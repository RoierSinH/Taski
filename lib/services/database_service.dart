import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/category.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/statistics_data.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return _openAtPath('taski_web.db');
    }
    final path = join(await getDatabasesPath(), 'taski.db');
    return _openAtPath(path);
  }

  Future<Database> _openAtPath(String path) async {
    return openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER,
        notes TEXT,
        priority INTEGER NOT NULL DEFAULT 1,
        due_date TEXT,
        reminder_date TEXT,
        recurrence TEXT NOT NULL DEFAULT 'none',
        recurrence_end_date TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subtasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    await db.insert('categories', {'name': 'Personal'});
    await db.insert('categories', {'name': 'Trabajo'});
    await db.insert('categories', {'name': 'Escuela'});
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN notes TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN priority INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE tasks ADD COLUMN due_date TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN reminder_date TEXT');
    }
    if (oldVersion < 4) {
      // Parte 5: Subtareas y recurrencia
      await db.execute('''
        CREATE TABLE subtasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
        )
      ''');
      await db.execute("ALTER TABLE tasks ADD COLUMN recurrence TEXT NOT NULL DEFAULT 'none'");
      await db.execute("ALTER TABLE tasks ADD COLUMN recurrence_end_date TEXT");
    }
  }

  // --- Operaciones CRUD Category ---
  Future<List<Category>> getCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap()..remove('id'));
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- Operaciones CRUD Task ---
  Future<List<Task>> getTasks() async {
    final db = await database;
    final result = await db.query('tasks');
    return result.map(Task.fromMap).toList();
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    return db.insert('tasks', task.toMap()..remove('id'));
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // --- Operaciones CRUD Subtask ---
  Future<int> insertSubtask(Subtask subtask) async {
    final db = await database;
    return db.insert('subtasks', subtask.toMap()..remove('id'));
  }

  Future<List<Subtask>> getSubtasks(int taskId) async {
    final db = await database;
    final maps = await db.query(
      'subtasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'id ASC',
    );
    return maps.map((map) => Subtask.fromMap(map)).toList();
  }

  Future<int> updateSubtask(Subtask subtask) async {
    final db = await database;
    return db.update(
      'subtasks',
      subtask.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [subtask.id],
    );
  }

  Future<int> deleteSubtask(int id) async {
    final db = await database;
    return db.delete(
      'subtasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Consultas de Estadísticas ---
  Future<int> countAllTasks() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM tasks');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countCompletedTasks() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM tasks WHERE completed = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countPendingTasks() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM tasks WHERE completed = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<int, int>> countByPriority() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT priority, COUNT(*) AS total
      FROM tasks
      WHERE completed = 0
      GROUP BY priority
    ''');
    return {
      for (final row in result) row['priority'] as int: row['total'] as int,
    };
  }

  Future<StatisticsData> loadStatistics() async {
    final results = await Future.wait([
      countAllTasks(),
      countCompletedTasks(),
      countPendingTasks(),
      countByPriority(),
    ]);

    return StatisticsData(
      total: results[0] as int,
      completed: results[1] as int,
      pending: results[2] as int,
      byPriority: results[3] as Map<int, int>,
    );
  }
}
