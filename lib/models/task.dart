class Task {
  const Task({
    this.id,
    required this.title,
    this.completed = false,
    this.isFavorite = false,
    this.isPinned = false,
    this.categoryId,
    this.notes,
    this.priority = 1,
    this.dueDate,
    this.reminderDate,
    this.recurrence = 'none',
    this.recurrenceEndDate,
  });

  final int? id;
  final String title;
  final bool completed;
  final bool isFavorite;
  final bool isPinned;
  final int? categoryId;
  final String? notes;
  final int priority;
  final DateTime? dueDate;
  final DateTime? reminderDate;
  final String recurrence;
  final DateTime? recurrenceEndDate;

  Task copyWith({
    int? id,
    String? title,
    bool? completed,
    bool? isFavorite,
    bool? isPinned,
    int? categoryId,
    String? notes,
    int? priority,
    DateTime? dueDate,
    DateTime? reminderDate,
    String? recurrence,
    DateTime? recurrenceEndDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      reminderDate: reminderDate ?? this.reminderDate,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
    );
  }

  // --- SQLite Mappings ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'category_id': categoryId,
      'notes': notes,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'reminder_date': reminderDate?.toIso8601String(),
      'recurrence': recurrence,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      completed: map['completed'] == 1,
      isFavorite: map['isFavorite'] == 1,
      isPinned: map['is_pinned'] == 1,
      categoryId: map['category_id'] as int?,
      notes: map['notes'] as String?,
      priority: map['priority'] as int? ?? 1,
      dueDate: map['due_date'] == null
          ? null
          : DateTime.parse(map['due_date'] as String),
      reminderDate: map['reminder_date'] == null
          ? null
          : DateTime.parse(map['reminder_date'] as String),
      recurrence: map['recurrence'] as String? ?? 'none',
      recurrenceEndDate: map['recurrence_end_date'] == null
          ? null
          : DateTime.parse(map['recurrence_end_date'] as String),
    );
  }

  // --- Supabase Mappings (Parte 6 y Reto 6) ---
  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'description': notes ?? '',
      'completed': completed,
      'priority': priority,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'reminder_date': reminderDate?.toUtc().toIso8601String(),
      'recurrence': recurrence,
      'recurrence_end_date': recurrenceEndDate?.toUtc().toIso8601String(),
      'is_pinned': isPinned,
    };
  }

  factory Task.fromSupabase(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      notes: map['description'] as String? ?? '',
      completed: map['completed'] as bool? ?? false,
      priority: map['priority'] as int? ?? 1,
      dueDate: map['due_date'] == null
          ? null
          : DateTime.parse(map['due_date'] as String).toLocal(),
      reminderDate: map['reminder_date'] == null
          ? null
          : DateTime.parse(map['reminder_date'] as String).toLocal(),
      categoryId: map['category_id'] as int?,
      recurrence: map['recurrence'] as String? ?? 'none',
      recurrenceEndDate: map['recurrence_end_date'] == null
          ? null
          : DateTime.parse(map['recurrence_end_date'] as String).toLocal(),
      isPinned: map['is_pinned'] as bool? ?? false,
    );
  }
}
