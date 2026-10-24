import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../services/task_attachment_service.dart';
import '../widgets/task_visual_card.dart';
import '../controllers/task_controller.dart';
import '../controllers/auth_controller.dart';
import '../main.dart'; // Para themeController
import 'category_screen.dart';
import 'task_form_screen.dart';
import 'statistics_page.dart';
import 'task_detail_page.dart';
import 'profile_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TaskController>();
    final authController = context.watch<AuthController>();
    final scheme = Theme.of(context).colorScheme;

    if (controller.loading && controller.tasks.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final visibleTasks = controller.visibleTasks;
    final categories = controller.categories;

    String categoryName(Task task) {
      if (task.categoryId == null) return 'Sin categoría';
      try {
        return categories.firstWhere((c) => c.id == task.categoryId).name;
      } catch (e) {
        return 'Sin categoría';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo_taski.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Taski 8.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Estadísticas',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatisticsPage(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Categorías',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoryScreen(),
                ),
              ).then((_) {
                if (context.mounted) {
                  context.read<TaskController>().loadCategories();
                }
              });
            },
            icon: const Icon(Icons.category_outlined),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Deseas cerrar tu sesión en este dispositivo?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<AuthController>().signOut();
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/logo_taski.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.task_alt, size: 44, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Taski Workspace',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    authController.user?.email ?? 'Usuario de Taski',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Identidad Visual & Supabase Sync',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Mi perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Apariencia',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Automático del sistema'),
              value: ThemeMode.system,
              groupValue: themeController.themeMode,
              onChanged: (value) {
                if (value != null) themeController.changeTheme(value);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Tema claro'),
              value: ThemeMode.light,
              groupValue: themeController.themeMode,
              onChanged: (value) {
                if (value != null) themeController.changeTheme(value);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Tema oscuro'),
              value: ThemeMode.dark,
              groupValue: themeController.themeMode,
              onChanged: (value) {
                if (value != null) themeController.changeTheme(value);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthController>().signOut();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      // LayoutBuilder didáctico para diseño adaptable (Etapa 11)
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 850 : double.infinity),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // Banner decorativo local con esquinas redondeadas (Etapa 8)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Image.asset(
                            'assets/images/portada.png',
                            height: isWide ? 130 : 95,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 90,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          Container(
                            height: isWide ? 130 : 95,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.65),
                                  Colors.transparent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isWide
                                      ? 'Organiza tus metas y proyectos'
                                      : 'Mis tareas de hoy',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${visibleTasks.length} ${visibleTasks.length == 1 ? "tarea visible" : "tareas visibles"}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (controller.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: () => controller.loadTasks(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),

                    // Barra de búsqueda con bordes y estilo unificado
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar tareas por título o nota...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: controller.searchText.isNotEmpty
                            ? IconButton(
                                tooltip: 'Limpiar búsqueda',
                                onPressed: () {
                                  context.read<TaskController>().changeSearchText('');
                                },
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        context.read<TaskController>().changeSearchText(val);
                      },
                    ),
                    const SizedBox(height: 10),

                    // Filtros de categoría y estado
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: controller.selectedCategoryId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              labelText: 'Categoría',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todas las categorías'),
                              ),
                              ...categories.map(
                                (category) => DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              context
                                  .read<TaskController>()
                                  .setCategoryFilter(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'all',
                            label: Text('Todas'),
                            icon: Icon(Icons.list_alt, size: 16),
                          ),
                          ButtonSegment(
                            value: 'pending',
                            label: Text('Pendientes'),
                            icon: Icon(Icons.pending_actions, size: 16),
                          ),
                          ButtonSegment(
                            value: 'today',
                            label: Text('Hoy'),
                            icon: Icon(Icons.today, size: 16),
                          ),
                          ButtonSegment(
                            value: 'favorites',
                            label: Text('Favoritas'),
                            icon: Icon(Icons.star_outline, size: 16),
                          ),
                        ],
                        selected: {controller.statusFilter},
                        onSelectionChanged: (selection) {
                          context
                              .read<TaskController>()
                              .setStatusFilter(selection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lista de tareas con la nueva TaskVisualCard desacoplada (Paso 6 y 7)
                    Expanded(
                      child: visibleTasks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 56,
                                    color: scheme.outline,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No hay tareas en esta vista',
                                    style: TextStyle(
                                      color: scheme.outline,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: visibleTasks.length,
                              itemBuilder: (_, index) {
                                final task = visibleTasks[index];
                                return TaskVisualCard(
                                  title: task.title,
                                  completed: task.completed,
                                  isPinned: task.isPinned,
                                  categoryName: categoryName(task),
                                  notes: task.notes,
                                  priority: task.priority,
                                  onToggle: () {
                                    if (!task.completed) {
                                      context
                                          .read<TaskController>()
                                          .completeTask(task);
                                    } else {
                                      context.read<TaskController>().updateTask(
                                            task.copyWith(completed: false),
                                          );
                                    }
                                  },
                                  onPin: () {
                                    context
                                        .read<TaskController>()
                                        .togglePin(task);
                                  },
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TaskDetailPage(task: task),
                                      ),
                                    );
                                  },
                                  onEdit: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TaskFormScreen(task: task),
                                      ),
                                    );
                                  },
                                  onDelete: () async {
                                    if (task.id == null) return;
                                    try {
                                      final attachmentService =
                                          TaskAttachmentService(
                                        Supabase.instance.client,
                                      );
                                      final adjuntos = await attachmentService
                                          .listForTask(task.id!);
                                      if (adjuntos.isNotEmpty) {
                                        if (!context.mounted) return;
                                        await showDialog<void>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                                'Evidencias multimedia asociadas'),
                                            content: Text(
                                              'La tarea "${task.title}" tiene ${adjuntos.length} '
                                              '${adjuntos.length == 1 ? "evidencia adjunta" : "evidencias adjuntas"} '
                                              'en Storage.\n\n'
                                              'Por integridad de datos, elimina primero los archivos adjuntos '
                                              'desde la Galería de Evidencias antes de borrar la tarea.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text('Cerrar'),
                                              ),
                                              FilledButton.icon(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          TaskDetailPage(
                                                              task: task),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons
                                                    .collections_bookmark_outlined),
                                                label: const Text(
                                                    'Ir a Galería de Evidencias'),
                                              ),
                                            ],
                                          ),
                                        );
                                        return;
                                      }
                                    } catch (_) {}
                                    if (context.mounted) {
                                      context
                                          .read<TaskController>()
                                          .deleteTask(task.id!);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
