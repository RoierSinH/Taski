import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../models/task.dart';
import '../models/category.dart';
import '../services/supabase_task_service.dart';

class TaskController extends ChangeNotifier {
  TaskController(this._service);

  final TaskRepository _service;

  List<Task> _tasks = [];
  List<Category> _categories = [];
  bool _loading = false;
  String? _error;
  String _searchText = '';
  int? _selectedCategoryId;
  String _statusFilter = 'all';

  StreamSubscription<List<Task>>? _taskSubscription;

  List<Task> get tasks => _tasks;
  List<Category> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;
  String get searchText => _searchText;
  int? get selectedCategoryId => _selectedCategoryId;
  String get statusFilter => _statusFilter;

  Future<void> init() async {
    await loadCategories();
    await loadTasks();
    startRealtime();
  }

  Future<void> loadTasks() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _service.getTasks();
    } catch (e) {
      _error = 'No fue posible cargar las tareas: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    final service = _service;
    if (service is! SupabaseTaskService) return;
    try {
      _categories = await service.getCategories();
      if (_categories.isEmpty) {
        await service.insertCategory('Personal');
        await service.insertCategory('Trabajo');
        await service.insertCategory('Escuela');
        _categories = await service.getCategories();
      }
      notifyListeners();
    } catch (_) {
      // Ignorar fallo puntual de categorías
    }
  }

  void startRealtime() {
    final service = _service;
    if (service is! SupabaseTaskService) return;
    try {
      _taskSubscription?.cancel();
      _taskSubscription = service.watchTasks().listen(
        (items) {
          _tasks = items;
          _error = null;
          notifyListeners();
        },
        onError: (err) {
          _error = 'Se perdió la sincronización en tiempo real';
          notifyListeners();
        },
      );
    } catch (_) {
      // En modo sin realtime continuar
    }
  }

  void changeSearchText(String value) {
    _searchText = value;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  List<Task> get visibleTasks {
    final query = _searchText.trim().toLowerCase();

    final filtered = _tasks.where((task) {
      final textMatches = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          (task.notes != null && task.notes!.toLowerCase().contains(query));

      final categoryMatches = _selectedCategoryId == null ||
          task.categoryId == _selectedCategoryId;

      final statusMatches = switch (_statusFilter) {
        'pending' => !task.completed,
        'completed' => task.completed,
        'favorites' => task.isFavorite,
        'today' => _isToday(task.dueDate),
        _ => true,
      };

      return textMatches && categoryMatches && statusMatches;
    }).toList();

    filtered.sort((a, b) {
      // Reto 6: Las tareas fijadas (isPinned) siempre van primero
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }

      if (_statusFilter == 'today') {
        if (a.dueDate != null && b.dueDate != null) {
          final dateCompare = a.dueDate!.compareTo(b.dueDate!);
          if (dateCompare != 0) return dateCompare;
        }
        return b.priority.compareTo(a.priority);
      }

      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return filtered;
  }

  // --- Reto 5 & 6: Estadísticas reactivas de Provider ---
  String get topPendingCategoryStats {
    final pendingTasks = _tasks.where((t) => !t.completed);
    if (pendingTasks.isEmpty) return 'No hay tareas pendientes';

    final counts = <int?, int>{};
    for (final task in pendingTasks) {
      counts[task.categoryId] = (counts[task.categoryId] ?? 0) + 1;
    }

    int? topCategoryId;
    int maxCount = -1;

    counts.forEach((catId, count) {
      if (count > maxCount) {
        maxCount = count;
        topCategoryId = catId;
      }
    });

    final categoryName = topCategoryId == null
        ? 'Sin categoría'
        : _categories
            .firstWhere(
              (c) => c.id == topCategoryId,
              orElse: () => const Category(name: 'Desconocida'),
            )
            .name;

    return '$categoryName ($maxCount pendientes)';
  }

  // --- Métodos de escritura en Supabase / Repositorio ---
  Future<int?> addTask(Task task) async {
    final created = await _service.insertTask(task);
    await loadTasks();
    return created.id;
  }

  Future<void> updateTask(Task task) async {
    await _service.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await _service.deleteTask(id);
    await loadTasks();
  }

  Future<void> togglePin(Task task) async {
    final service = _service;
    if (service is SupabaseTaskService) {
      await service.togglePin(task);
    } else {
      await _service.updateTask(task.copyWith(isPinned: !task.isPinned));
    }
    await loadTasks();
  }

  DateTime? calculateNextDate(Task task) {
    final current = task.dueDate;
    if (current == null) return null;

    switch (task.recurrence) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
      default:
        return null;
    }
  }

  Future<void> completeTask(Task task) async {
    final completedTask = task.copyWith(completed: true);
    await _service.updateTask(completedTask);

    final nextDate = calculateNextDate(task);
    if (nextDate != null) {
      final nextTask = Task(
        title: task.title,
        notes: task.notes,
        priority: task.priority,
        dueDate: nextDate,
        categoryId: task.categoryId,
        recurrence: task.recurrence,
        recurrenceEndDate: task.recurrenceEndDate,
        isPinned: task.isPinned,
      );

      final shouldCreate = task.recurrenceEndDate == null ||
          !nextDate.isAfter(task.recurrenceEndDate!);

      if (shouldCreate) {
        await _service.insertTask(nextTask);
      }
    }

    await loadTasks();
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }
}
