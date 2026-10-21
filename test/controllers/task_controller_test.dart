import 'package:flutter_test/flutter_test.dart';
import 'package:mi_primera_app/controllers/task_controller.dart';
import 'package:mi_primera_app/models/task.dart';
import 'package:mi_primera_app/services/supabase_task_service.dart';

class FakeTaskRepository implements TaskRepository {
  final List<Task> items = [];

  @override
  Future<List<Task>> getTasks() async {
    return List.unmodifiable(items);
  }

  @override
  Future<Task> insertTask(Task task) async {
    final saved = task.copyWith(
      id: items.length + 1,
    );
    items.add(saved);
    return saved;
  }

  @override
  Future<Task> updateTask(Task task) async {
    final index = items.indexWhere(
      (item) => item.id == task.id,
    );
    items[index] = task;
    return task;
  }

  @override
  Future<void> deleteTask(int id) async {
    items.removeWhere((item) => item.id == id);
  }
}

class FailingTaskRepository implements TaskRepository {
  @override
  Future<List<Task>> getTasks() async {
    throw Exception('Sin conexión');
  }

  @override
  Future<Task> insertTask(Task task) async {
    throw Exception('Sin conexión');
  }

  @override
  Future<Task> updateTask(Task task) async {
    throw Exception('Sin conexión');
  }

  @override
  Future<void> deleteTask(int id) async {
    throw Exception('Sin conexión');
  }
}

void main() {
  group('Pruebas unitarias de TaskController (Parte 7)', () {
    test('addTask agrega y recarga la lista', () async {
      final repository = FakeTaskRepository();
      final controller = TaskController(repository);

      await controller.addTask(
        const Task(title: 'Estudiar Flutter'),
      );

      expect(controller.tasks, hasLength(1));
      expect(controller.tasks.first.title, 'Estudiar Flutter');
    });

    test('loadTasks expone un error cuando falla el repositorio', () async {
      final controller = TaskController(FailingTaskRepository());

      await controller.loadTasks();

      expect(controller.error, isNotNull);
      expect(controller.loading, isFalse);
    });
  });
}
