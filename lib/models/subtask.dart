class Subtask {
  Subtask({
    this.id,
    required this.taskId,
    required this.title,
    this.completed = false,
  });

  final int? id;
  final int taskId;
  final String title;
  final bool completed;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'completed': completed ? 1 : 0,
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      title: map['title'] as String,
      completed: map['completed'] == 1,
    );
  }

  factory Subtask.fromSupabase(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      title: map['title'] as String,
      completed: map['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'user_id': userId,
      'task_id': taskId,
      'title': title,
      'completed': completed,
    };
  }

  Subtask copyWith({
    int? id,
    int? taskId,
    String? title,
    bool? completed,
  }) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}
