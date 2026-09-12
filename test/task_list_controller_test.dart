import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:observerstatesynch/app_lifecycle/app_lifecycle_controller.dart';
import 'package:observerstatesynch/app_settings/app_settings_controller.dart';
import 'package:observerstatesynch/dependencies.dart';
import 'package:observerstatesynch/dependencies_scope.dart';
import 'package:observerstatesynch/home_page.dart';
import 'package:observerstatesynch/internet_connection/internet_connection_controller.dart';
import 'package:observerstatesynch/superlist/task.dart';
import 'package:observerstatesynch/superlist/task_list_controller.dart';

class _RecordingObserver with TaskListObserver {
  final added = <Task>[];
  final completed = <Task>[];
  final reopened = <Task>[];
  final recurringResets = <Task>[];
  final syncedCounts = <int>[];

  @override
  void onTaskAdded(Task task) => added.add(task);

  @override
  void onTaskCompleted(Task task) => completed.add(task);

  @override
  void onTaskReopened(Task task) => reopened.add(task);

  @override
  void onTaskRecurringReset(Task task) => recurringResets.add(task);

  @override
  void onOfflineChangesSynced(int count) => syncedCounts.add(count);
}

void main() {
  test('addTask notifies observers and supports nested subtasks', () {
    final controller = TaskListController();
    addTearDown(controller.dispose);
    final observer = _RecordingObserver();
    controller.addObserver(observer);

    final parent = controller.addTask('Project', note: 'Big goal');
    final subtask = controller.addTask('Step 1', parent: parent);

    expect(observer.added.map((t) => t.title), containsAll(['Project', 'Step 1']));
    expect(parent.subtasks, contains(subtask));
    expect(controller.tasks, contains(parent));
    expect(parent.find(subtask.id), same(subtask));
  });

  test('completing a recurring task reschedules it instead of staying done',
      () {
    final controller = TaskListController();
    addTearDown(controller.dispose);
    final observer = _RecordingObserver();
    controller.addObserver(observer);

    final recurring = controller.tasks
        .firstWhere((task) => task.recurrence != null);
    controller.toggleDone(recurring.id);

    expect(observer.completed, [recurring]);
    expect(observer.recurringResets, [recurring]);
    expect(recurring.done, isFalse);
  });

  test('toggling a task notifies completed and reopened events', () {
    final controller = TaskListController();
    addTearDown(controller.dispose);
    final observer = _RecordingObserver();
    controller.addObserver(observer);

    final task = controller.tasks.firstWhere((t) => t.recurrence == null);
    controller.toggleDone(task.id);
    controller.toggleDone(task.id);

    expect(observer.completed, [task]);
    expect(observer.reopened, [task]);
  });

  test('completions made offline are synced when the connection returns', () {
    final controller = TaskListController();
    addTearDown(controller.dispose);
    final observer = _RecordingObserver();
    controller.addObserver(observer);

    controller.onInternetConnectionChange(InternetStatus.offline);

    final task = controller.tasks.firstWhere((t) => t.recurrence == null);
    controller.toggleDone(task.id);

    expect(controller.hasPendingSync, isTrue);
    expect(controller.pendingSyncCount, 1);

    controller.onInternetConnectionChange(InternetStatus.online);

    expect(observer.syncedCounts, [1]);
    expect(controller.hasPendingSync, isFalse);
    expect(task.done, isTrue);
  });

  testWidgets('TaskListWidget resolves dependencies from a pushed route',
      (tester) async {
    // Regression test: DependenciesScope must wrap MaterialApp so that
    // Navigator-pushed routes can call DependenciesScope.of(context).
    final internetConnectionController = InternetConnectionController(
      // Fake DNS lookup: resolves instantly, no real network or timers.
      lookup: (_) async => const <InternetAddress>[],
    );
    final taskListController = TaskListController(
      internetConnectionController: internetConnectionController,
    );
    final appLifecycleController = AppLifecycleController();

    try {
      await tester.pumpWidget(
        DependenciesScope(
          dependencies: Dependencies(
            appSettingsController: AppSettingsController(),
            internetConnectionController: internetConnectionController,
            appLifecycleController: appLifecycleController,
            taskListController: taskListController,
          ),
          child: const MaterialApp(home: HomePage()),
        ),
      );

      await tester.tap(find.text('Superlist demo'));
      await tester.pumpAndSettle();

      // The pushed screen rendered its seeded tasks — no
      // "No DependenciesScope was found in element tree" error.
      expect(find.text('Plan your day'), findsOneWidget);
      expect(find.text('Activity (real-time via observers)'), findsOneWidget);
    } finally {
      taskListController.dispose();
      appLifecycleController.dispose();
      internetConnectionController.dispose();
    }
  });
}
