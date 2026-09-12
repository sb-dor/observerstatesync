import 'package:flutter/foundation.dart';
import 'package:observerstatesynch/internet_connection/internet_connection_controller.dart';
import 'package:observerstatesynch/superlist/task.dart';

/// Extended observer: any screen or service can subscribe to task list
/// changes without knowing about [TaskListController] internals.
mixin TaskListObserver {
  void onTaskAdded(Task task) {}

  void onTaskCompleted(Task task) {}

  void onTaskReopened(Task task) {}

  void onTaskRecurringReset(Task task) {}

  void onOfflineChangesSynced(int count) {}
}

/// Superlist-inspired subject of the observer pattern: real-time sync of task
/// state to multiple observers. Extends the classic scheme by also acting as
/// an observer of [InternetConnectionController] — completions made while
/// offline are queued and synced once the connection is back (offline support).
class TaskListController with ChangeNotifier, InternetConnectionObserver {
  TaskListController({
    InternetConnectionController? internetConnectionController,
  }) : _internetConnectionController = internetConnectionController {
    internetConnectionController?.addObserver(this);
    _seedDemoTasks();
  }

  final InternetConnectionController? _internetConnectionController;

  // Store observers in a Set, preventing duplicates. Unlike list of observers
  final _observers = <TaskListObserver>{};

  final _tasks = <Task>[];

  // Offline support: completions made offline, waiting to be synced.
  final _pendingSyncIds = <String>{};

  InternetStatus _connectionStatus = InternetStatus.checking;

  List<Task> get tasks => List.unmodifiable(_tasks);

  bool get hasPendingSync => _pendingSyncIds.isNotEmpty;

  int get pendingSyncCount => _pendingSyncIds.length;

  bool get _isOffline => _connectionStatus == InternetStatus.offline;

  void addObserver(TaskListObserver observer) => _observers.add(observer);

  void removeObserver(TaskListObserver observer) =>
      _observers.remove(observer);

  /// Adds a top-level task, or a subtask when [parent] is provided
  /// (infinitely nested lists, Superlist-style).
  Task addTask(
    String title, {
    String? note,
    Recurrence? recurrence,
    Task? parent,
  }) {
    final task = Task(title: title, note: note, recurrence: recurrence);
    (parent?.subtasks ?? _tasks).add(task);

    notifyListeners();
    for (final observer in _observers) {
      observer.onTaskAdded(task);
    }
    return task;
  }

  void toggleDone(String taskId) {
    final task = _findTask(taskId);
    if (task == null) return;

    task.done = !task.done;
    notifyListeners();
    for (final observer in _observers) {
      task.done ? observer.onTaskCompleted(task) : observer.onTaskReopened(task);
    }

    // Recurring tasks: completing reschedules the next occurrence instead of
    // keeping the task checked.
    if (task.done && task.recurrence != null) {
      task.done = false;
      notifyListeners();
      for (final observer in _observers) {
        observer.onTaskRecurringReset(task);
      }
      return;
    }

    // Offline support: remember the completion and sync it when back online.
    if (task.done && _isOffline) {
      _pendingSyncIds.add(task.id);
      notifyListeners();
    }
  }

  @override
  void onInternetConnectionChange(InternetStatus status) {
    _connectionStatus = status;

    if (status == InternetStatus.online && _pendingSyncIds.isNotEmpty) {
      final count = _pendingSyncIds.length;
      _pendingSyncIds.clear();

      notifyListeners();
      for (final observer in _observers) {
        observer.onOfflineChangesSynced(count);
      }
    }
  }

  @override
  void dispose() {
    _internetConnectionController?.removeObserver(this);
    _observers.clear();
    super.dispose();
  }

  Task? _findTask(String taskId) {
    for (final task in _tasks) {
      final found = task.find(taskId);
      if (found != null) return found;
    }
    return null;
  }

  void _seedDemoTasks() {
    addTask('Plan your day', note: 'Schedule tasks, reminders and habits');
    addTask(
      'Team stand-up notes',
      note: 'Summarize meeting notes',
      recurrence: Recurrence.daily,
    );
    final groceryList = addTask(
      'Grocery list',
      note: 'Shared with family',
      recurrence: Recurrence.weekly,
    );
    groceryList.subtasks.addAll([
      Task(title: 'Milk'),
      Task(title: 'Eggs'),
      Task(title: 'Bread'),
    ]);
  }
}
