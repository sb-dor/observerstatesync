import 'package:flutter/material.dart';
import 'package:observerstatesynch/dependencies_scope.dart';
import 'package:observerstatesynch/superlist/task.dart';
import 'package:observerstatesynch/superlist/task_list_controller.dart';

/// {@template task_list_widget}
/// Superlist-inspired demo screen: nested subtasks, recurring tasks, offline
/// sync and a real-time activity feed — all driven through the extended
/// observer pattern. Two independent observers ([_TaskListWidgetState] and
/// [_ActivityFeedWidgetState]) stay in sync from a single subject.
/// {@endtemplate}
class TaskListWidget extends StatefulWidget {
  /// {@macro task_list_widget}
  const TaskListWidget({super.key});

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

/// State for widget TaskListWidget.
class _TaskListWidgetState extends State<TaskListWidget> with TaskListObserver {
  late final TaskListController _taskListController;

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();
    // Initial state initialization
    final dependencies = DependenciesScope.of(context);
    _taskListController = dependencies.taskListController;

    _taskListController.addObserver(this);
  }

  @override
  void dispose() {
    // Permanent removal of a tree stent
    _taskListController.removeObserver(this);
    super.dispose();
  }
  /* #endregion */

  @override
  void onTaskAdded(Task task) => _showSnack('Added "${task.title}"');

  @override
  void onTaskRecurringReset(Task task) =>
      _showSnack('Recurring task "${task.title}" rescheduled');

  @override
  void onOfflineChangesSynced(int count) =>
      _showSnack('Back online — synced $count offline change(s)');

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddTaskSheet({Task? parent}) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    Recurrence? recurrence;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                parent == null
                    ? 'New task'
                    : 'New subtask of "${parent.title}"',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Dentist Friday at 2pm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Recurrence>(
                initialValue: recurrence,
                decoration: const InputDecoration(
                  labelText: 'Repeats',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<Recurrence>(
                    value: null,
                    child: Text('Never'),
                  ),
                  DropdownMenuItem<Recurrence>(
                    value: Recurrence.daily,
                    child: Text('Daily'),
                  ),
                  DropdownMenuItem<Recurrence>(
                    value: Recurrence.weekly,
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem<Recurrence>(
                    value: Recurrence.monthly,
                    child: Text('Monthly'),
                  ),
                ],
                onChanged: (value) => setSheetState(() => recurrence = value),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  _taskListController.addTask(
                    title,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                    recurrence: recurrence,
                    parent: parent,
                  );
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Add task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Superlist demo')),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showAddTaskSheet(),
      child: Icon(Icons.add),
    ),
    body: Column(
      children: [
        ListenableBuilder(
          listenable: _taskListController,
          builder: (context, _) {
            final allTasks = _taskListController.tasks
                .expand((task) => task.allTasks)
                .toList();
            final doneCount = allTasks.where((task) => task.done).length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('$doneCount / ${allTasks.length} done'),
                  const Spacer(),
                  if (_taskListController.hasPendingSync)
                    Chip(
                      label: Text(
                        '${_taskListController.pendingSyncCount} pending sync',
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1),
        Expanded(
          flex: 3,
          child: ListenableBuilder(
            listenable: _taskListController,
            builder: (context, _) => ListView(
              children: [
                for (final task in _taskListController.tasks)
                  _TaskTile(
                    task: task,
                    onToggle: () => _taskListController.toggleDone(task.id),
                    onAddSubtask: () => _showAddTaskSheet(parent: task),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: ActivityFeedWidget(controller: _taskListController),
        ),
      ],
    ),
  );
}

/// A task tile with expandable nested subtasks.
class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onAddSubtask,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onAddSubtask;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (task.note?.isNotEmpty ?? false) task.note!,
      if (task.recurrence != null) 'Repeats ${task.recurrence!.name}',
      if (task.subtasks.isNotEmpty)
        '${task.completedSubtasks}/${task.totalSubtasks} subtasks',
    ].join('  •  ');

    final titleStyle = task.done
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : null;

    if (task.subtasks.isEmpty) {
      return CheckboxListTile(
        value: task.done,
        onChanged: (_) => onToggle(),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(task.title, style: titleStyle),
        subtitle: details.isEmpty ? null : Text(details),
      );
    }

    return ExpansionTile(
      leading: Checkbox(value: task.done, onChanged: (_) => onToggle()),
      title: Text(task.title, style: titleStyle),
      subtitle: details.isEmpty ? null : Text(details),
      initiallyExpanded: !task.done,
      children: [
        for (final subtask in task.subtasks)
          CheckboxListTile(
            dense: true,
            value: subtask.done,
            onChanged: (_) => onToggle(),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              subtask.title,
              style: subtask.done
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
          ),
        TextButton.icon(
          onPressed: onAddSubtask,
          icon: const Icon(Icons.add),
          label: const Text('Add subtask'),
        ),
      ],
    );
  }
}

/// {@template activity_feed_widget}
/// A second, independent observer of the same [TaskListController] — mimics
/// Superlist's real-time collaboration activity log.
/// {@endtemplate}
class ActivityFeedWidget extends StatefulWidget {
  /// {@macro activity_feed_widget}
  const ActivityFeedWidget({required this.controller, super.key});

  final TaskListController controller;

  @override
  State<ActivityFeedWidget> createState() => _ActivityFeedWidgetState();
}

/// State for widget ActivityFeedWidget.
class _ActivityFeedWidgetState extends State<ActivityFeedWidget>
    with TaskListObserver {
  final _events = <String>[];

  /* #region Lifecycle */
  @override
  void initState() {
    super.initState();
    // Initial state initialization
    widget.controller.addObserver(this);
  }

  @override
  void dispose() {
    // Permanent removal of a tree stent
    widget.controller.removeObserver(this);
    super.dispose();
  }
  /* #endregion */

  void _log(String event) => setState(() => _events.insert(0, event));

  @override
  void onTaskAdded(Task task) => _log('➕ Added "${task.title}"');

  @override
  void onTaskCompleted(Task task) => _log('✅ Completed "${task.title}"');

  @override
  void onTaskReopened(Task task) => _log('↩️ Reopened "${task.title}"');

  @override
  void onTaskRecurringReset(Task task) =>
      _log('🔁 Rescheduled recurring "${task.title}"');

  @override
  void onOfflineChangesSynced(int count) =>
      _log('🔄 Synced $count offline change(s)');

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Activity (real-time via observers)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      Expanded(
        child: _events.isEmpty
            ? const Center(child: Text('No activity yet'))
            : ListView(
                children: [
                  for (final event in _events)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.circle, size: 8),
                      title: Text(event),
                    ),
                ],
              ),
      ),
    ],
  );
}

