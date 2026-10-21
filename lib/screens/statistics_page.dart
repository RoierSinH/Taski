import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/task_controller.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final allTasks = controller.tasks;

    final total = allTasks.length;
    final completed = allTasks.where((t) => t.completed).length;
    final pending = total - completed;
    final completionRate = total == 0 ? 0.0 : (completed / total);
    final percentage = (completionRate * 100).round();
    final topCategoryStats = controller.topPendingCategoryStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progreso general: $percentage%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: completionRate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Total de tareas'),
              trailing: Text(
                total.toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('Tareas completadas'),
              trailing: Text(
                completed.toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.pending_actions),
              title: const Text('Tareas pendientes'),
              trailing: Text(
                pending.toString(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Estadísticas reactivas en la nube (Provider)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.indigo),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.indigo.shade50,
            child: ListTile(
              leading: const Icon(Icons.category, color: Colors.indigo),
              title: const Text('Categoría con más pendientes'),
              subtitle: Text(
                topCategoryStats,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
