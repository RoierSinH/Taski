import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/subtask.dart';

abstract interface class TaskRepository {
  Future<List<Task>> getTasks();
  Future<Task> insertTask(Task task);
  Future<Task> updateTask(Task task);
  Future<void> deleteTask(int id);
}

class SupabaseTaskService implements TaskRepository {
  SupabaseTaskService(this._client);
  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('No existe una sesión activa');
    }
    return id;
  }

  // --- Tareas (Tasks) ---
  @override
  Future<List<Task>> getTasks() async {
    final rows = await _client
        .from('tasks')
        .select()
        .order('is_pinned', ascending: false) // Reto 6: Fijadas antes que las demás
        .order('completed', ascending: true)
        .order('priority', ascending: false)
        .order('due_date', ascending: true);

    return rows.map<Task>((row) => Task.fromSupabase(row)).toList();
  }

  @override
  Future<Task> insertTask(Task task) async {
    final row = await _client
        .from('tasks')
        .insert(task.toSupabaseMap(_userId))
        .select()
        .single();
    return Task.fromSupabase(row);
  }

  @override
  Future<Task> updateTask(Task task) async {
    final row = await _client
        .from('tasks')
        .update(task.toSupabaseMap(_userId))
        .eq('id', task.id!)
        .select()
        .single();
    return Task.fromSupabase(row);
  }

  @override
  Future<void> deleteTask(int id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  Future<Task> togglePin(Task task) async {
    final newPinned = !task.isPinned;
    final row = await _client
        .from('tasks')
        .update({'is_pinned': newPinned})
        .eq('id', task.id!)
        .select()
        .single();
    return Task.fromSupabase(row);
  }

  Stream<List<Task>> watchTasks() {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows.map(Task.fromSupabase).toList());
  }

  // --- Categorías (Categories) ---
  Future<List<Category>> getCategories() async {
    final rows = await _client
        .from('categories')
        .select()
        .order('name');
    return rows.map<Category>((row) => Category.fromSupabase(row)).toList();
  }

  Future<Category> insertCategory(String name) async {
    final row = await _client
        .from('categories')
        .insert({
          'user_id': _userId,
          'name': name.trim(),
        })
        .select()
        .single();
    return Category.fromSupabase(row);
  }

  Future<void> deleteCategory(int id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  // --- Subtareas (Subtasks) ---
  Future<List<Subtask>> getSubtasks(int taskId) async {
    final rows = await _client
        .from('subtasks')
        .select()
        .eq('task_id', taskId)
        .order('id');
    return rows.map<Subtask>((row) => Subtask.fromSupabase(row)).toList();
  }

  Future<Subtask> insertSubtask({
    required int taskId,
    required String title,
  }) async {
    final row = await _client
        .from('subtasks')
        .insert({
          'task_id': taskId,
          'user_id': _userId,
          'title': title,
        })
        .select()
        .single();
    return Subtask.fromSupabase(row);
  }

  Future<Subtask> updateSubtask(Subtask subtask) async {
    final row = await _client
        .from('subtasks')
        .update({
          'title': subtask.title,
          'completed': subtask.completed,
        })
        .eq('id', subtask.id!)
        .select()
        .single();
    return Subtask.fromSupabase(row);
  }

  Future<void> deleteSubtask(int id) async {
    await _client.from('subtasks').delete().eq('id', id);
  }
}
