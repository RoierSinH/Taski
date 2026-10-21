import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.categoryName,
    required this.onChanged,
    required this.onFavoriteChanged,
    required this.onPinChanged,
    required this.onEdit,
    required this.onUpdate,
    required this.onDelete,
  });

  final Task task;
  final String categoryName;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onFavoriteChanged;
  final VoidCallback onPinChanged;
  final VoidCallback onEdit;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  Color priorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String priorityText(int priority) {
    switch (priority) {
      case 3:
        return 'Alta';
      case 2:
        return 'Media';
      default:
        return 'Baja';
    }
  }

  bool isOverdue(Task task) {
    if (task.completed || task.dueDate == null) {
      return false;
    }
    return task.dueDate!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: task.isPinned
          ? RoundedRectangleBorder(
              side: const BorderSide(color: Colors.amber, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: onChanged,
        ),
        title: Row(
          children: [
            if (task.isPinned)
              const Padding(
                padding: EdgeInsets.only(right: 6.0),
                child: Icon(
                  Icons.push_pin,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  decoration: task.completed ? TextDecoration.lineThrough : null,
                  fontWeight: task.isPinned ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isOverdue(task))
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text(
                  'Atrasada',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(categoryName),
            if (task.notes != null && task.notes!.trim().isNotEmpty)
              Text(
                'Nota: ${task.notes}',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            const SizedBox(height: 4),
            Chip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                Icons.flag,
                size: 16,
                color: priorityColor(task.priority),
              ),
              label: Text(
                priorityText(task.priority),
                style: const TextStyle(fontSize: 12),
              ),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        onTap: onEdit,
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: task.isPinned ? 'Desfijar tarea' : 'Fijar tarea',
              icon: Icon(
                task.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: task.isPinned ? Colors.amber : Colors.grey,
              ),
              onPressed: onPinChanged,
            ),
            IconButton(
              tooltip: 'Favorita',
              icon: Icon(
                task.isFavorite ? Icons.star : Icons.star_border,
                color: task.isFavorite ? Colors.amber : Colors.grey,
              ),
              onPressed: onFavoriteChanged,
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: onUpdate,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
