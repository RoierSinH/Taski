import 'package:flutter/material.dart';

/// Widget visual aislado creado en la Actividad Guiada (Parte 8).
/// Presenta desacoplada la tarjeta de tarea, recibiendo solo datos y callbacks.
class TaskVisualCard extends StatelessWidget {
  const TaskVisualCard({
    super.key,
    required this.title,
    required this.completed,
    required this.onToggle,
    this.isPinned = false,
    this.categoryName,
    this.notes,
    this.priority = 1,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onPin,
  });

  final String title;
  final bool completed;
  final VoidCallback onToggle;
  final bool isPinned;
  final String? categoryName;
  final String? notes;
  final int priority;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;

  Color _priorityColor(int p) {
    switch (p) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }

  String _priorityText(int p) {
    switch (p) {
      case 3:
        return 'Alta';
      case 2:
        return 'Media';
      default:
        return 'Baja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.titleMedium;

    // Animación discreta de 250ms (Etapa 10) que interpola color y forma según estado
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: completed
            ? colors.surfaceVariant.withOpacity(0.5)
            : colors.surface,
        borderRadius: BorderRadius.circular(isPinned ? 20 : 16),
        border: Border.all(
          color: isPinned
              ? Colors.amber.shade600
              : completed
                  ? colors.outlineVariant.withOpacity(0.5)
                  : colors.outlineVariant,
          width: isPinned ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isPinned ? 0.08 : 0.04),
            blurRadius: isPinned ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isPinned ? 20 : 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(isPinned ? 20 : 16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono interactivo para alternar completado
                IconButton(
                  tooltip: completed
                      ? 'Marcar como pendiente'
                      : 'Marcar como completada',
                  icon: Icon(
                    completed ? Icons.check_circle : Icons.circle_outlined,
                    color: completed ? colors.primary : colors.outline,
                    size: 26,
                  ),
                  onPressed: onToggle,
                ),
                const SizedBox(width: 8),

                // Contenido textual con protección de desbordamiento (maxLines + ellipsis)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isPinned)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.push_pin,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle?.copyWith(
                                decoration: completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: completed
                                    ? colors.onSurface.withOpacity(0.5)
                                    : colors.onSurface,
                                fontWeight: isPinned
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (notes != null && notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (categoryName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.secondaryContainer.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                categoryName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.onSecondaryContainer,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _priorityColor(priority).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Prioridad ${_priorityText(priority)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _priorityColor(priority),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Acciones secundarias (Fijar, Editar, Eliminar)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onPin != null)
                      IconButton(
                        tooltip: isPinned ? 'Desfijar' : 'Fijar',
                        icon: Icon(
                          isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 20,
                          color: isPinned ? Colors.amber : colors.outline,
                        ),
                        onPressed: onPin,
                      ),
                    if (onEdit != null)
                      IconButton(
                        tooltip: 'Editar tarea',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        tooltip: 'Eliminar tarea',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: onDelete,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
