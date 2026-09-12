/// How often a task repeats, Superlist-style recurring tasks.
enum Recurrence { daily, weekly, monthly }

/// A task with optional note, recurrence and infinitely nestable subtasks.
class Task {
  Task({
    required this.title,
    this.note,
    this.recurrence,
    Iterable<Task>? subtasks,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       subtasks = List<Task>.of(subtasks ?? const <Task>[]);

  final String id;
  final String title;
  final String? note;
  final Recurrence? recurrence;

  /// Nested subtasks, e.g. breaking a big goal into small steps.
  final List<Task> subtasks;

  bool done = false;

  int get completedSubtasks => subtasks.where((t) => t.done).length;

  int get totalSubtasks => subtasks.length;

  /// Depth-first search for a task (or subtask) by id.
  Task? find(String taskId) {
    if (id == taskId) return this;
    for (final subtask in subtasks) {
      final found = subtask.find(taskId);
      if (found != null) return found;
    }
    return null;
  }

  /// This task and all of its descendants, depth-first.
  Iterable<Task> get allTasks sync* {
    yield this;
    for (final subtask in subtasks) {
      yield* subtask.allTasks;
    }
  }
}
