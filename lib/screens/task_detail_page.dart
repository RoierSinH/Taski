import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../services/supabase_task_service.dart';
import '../widgets/task_attachments_panel.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late final SupabaseTaskService _service;
  List<Subtask> _subtasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = SupabaseTaskService(Supabase.instance.client);
    _loadSubtasks();
  }

  Future<void> _loadSubtasks() async {
    try {
      final items = await _service.getSubtasks(widget.task.id!);
      if (!mounted) return;
      setState(() {
        _subtasks = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _showAddSubtaskDialog() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva subtarea'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Descripción',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text.trim(),
                );
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (title == null || title.isEmpty) return;

    try {
      await _service.insertSubtask(
        taskId: widget.task.id!,
        title: title,
      );
      await _loadSubtasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar subtarea: $e')),
      );
    }
  }

  Future<void> _toggleSubtask(Subtask subtask) async {
    try {
      await _service.updateSubtask(
        subtask.copyWith(
          completed: !subtask.completed,
        ),
      );
      await _loadSubtasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar subtarea: $e')),
      );
    }
  }

  double get _progress {
    if (_subtasks.isEmpty) {
      return widget.task.completed ? 1 : 0;
    }
    final completed = _subtasks.where((item) => item.completed).length;
    return completed / _subtasks.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de tarea'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubtaskDialog,
        child: const Icon(Icons.add_task),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (widget.task.isPinned)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Chip(
                    avatar: Icon(Icons.push_pin, size: 16, color: Colors.amber),
                    label: Text('Fijada'),
                  ),
                ),
              Expanded(
                child: Text(
                  widget.task.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          if (widget.task.notes != null && widget.task.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.task.notes!),
          ],
          const SizedBox(height: 24),
          Text(
            '${(_progress * 100).round()}% completado',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress,
          ),
          const SizedBox(height: 24),
          Text(
            'Subtareas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (_subtasks.isEmpty)
            const Text('No hay subtareas registradas.')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subtasks.length,
              itemBuilder: (context, index) {
                final subtask = _subtasks[index];
                return CheckboxListTile(
                  value: subtask.completed,
                  title: Text(
                    subtask.title,
                    style: TextStyle(
                      decoration: subtask.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  onChanged: (_) => _toggleSubtask(subtask),
                );
              },
            ),
          if (widget.task.id != null) ...[
            const SizedBox(height: 24),
            TaskAttachmentsPanel(taskId: widget.task.id!),
          ],
        ],
      ),
    );
  }
}
