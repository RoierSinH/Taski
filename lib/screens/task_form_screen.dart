import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../controllers/task_controller.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({
    super.key,
    this.task,
  });

  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  int? _categoryId;
  int _selectedPriority = 1;
  DateTime? _dueDate;
  int? _reminderMinutes;
  String _recurrence = 'none';
  bool _isPinned = false;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');
    _categoryId = widget.task?.categoryId;
    _selectedPriority = widget.task?.priority ?? 1;
    _dueDate = widget.task?.dueDate;
    _recurrence = widget.task?.recurrence ?? 'none';
    _isPinned = widget.task?.isPinned ?? false;

    if (widget.task?.reminderDate != null && widget.task?.dueDate != null) {
      _reminderMinutes = widget.task!.dueDate!
          .difference(widget.task!.reminderDate!)
          .inMinutes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _dueDate != null
          ? TimeOfDay.fromDateTime(_dueDate!)
          : TimeOfDay.now(),
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _dueDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  DateTime? _calculateReminderDate() {
    if (_dueDate == null || _reminderMinutes == null) return null;
    return _dueDate!.subtract(Duration(minutes: _reminderMinutes!));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final reminderDate = _calculateReminderDate();
    if (reminderDate != null && reminderDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El recordatorio debe estar en el futuro'),
        ),
      );
      return;
    }

    try {
      if (_editing && widget.task?.id != null) {
        await NotificationService.instance.cancelTaskReminder(widget.task!.id!);
      }
    } catch (e) {
      // Ignorar en web o sin permisos
    }

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      completed: widget.task?.completed ?? false,
      isFavorite: widget.task?.isFavorite ?? false,
      isPinned: _isPinned,
      categoryId: _categoryId,
      priority: _selectedPriority,
      dueDate: _dueDate,
      reminderDate: reminderDate,
      recurrence: _recurrence,
      recurrenceEndDate: widget.task?.recurrenceEndDate,
    );

    int? savedTaskId;
    final controller = context.read<TaskController>();
    if (_editing) {
      await controller.updateTask(task);
      savedTaskId = task.id;
    } else {
      savedTaskId = await controller.addTask(task);
    }

    try {
      if (savedTaskId != null) {
        final savedTask = task.copyWith(id: savedTaskId);
        if (savedTask.reminderDate != null && !savedTask.completed) {
          await NotificationService.instance.scheduleTaskReminder(savedTask);
        }
      }
    } catch (e) {
      // Ignorar en web
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<TaskController>().categories;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar tarea' : 'Nueva tarea'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editing ? 'Modifica los detalles' : 'Detalles de la tarea',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Campo de título con icono y borde estilizado
                      TextFormField(
                        controller: _titleController,
                        autofocus: !_editing,
                        decoration: const InputDecoration(
                          labelText: 'Título de la tarea',
                          hintText: 'Ej. Preparar informe de proyecto',
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Escribe una tarea';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Categoría
                      DropdownButtonFormField<int?>(
                        value: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Sin categoría'),
                          ),
                          ...categories.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _categoryId = value),
                      ),
                      const SizedBox(height: 16),

                      // Prioridad
                      DropdownButtonFormField<int>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Prioridad',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Baja')),
                          DropdownMenuItem(value: 2, child: Text('Media')),
                          DropdownMenuItem(value: 3, child: Text('Alta')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedPriority = value ?? 1),
                      ),
                      const SizedBox(height: 16),

                      // Fecha límite con estilo Card suave
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outlineVariant),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.event_outlined),
                          title: const Text('Fecha límite'),
                          subtitle: Text(
                            _dueDate == null
                                ? 'Sin fecha seleccionada'
                                : DateFormat('dd/MM/yyyy HH:mm')
                                    .format(_dueDate!),
                          ),
                          trailing: IconButton(
                            tooltip: 'Seleccionar fecha y hora',
                            onPressed: _selectDueDate,
                            icon: const Icon(Icons.edit_calendar_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recordatorio
                      DropdownButtonFormField<int?>(
                        value: _reminderMinutes,
                        decoration: const InputDecoration(
                          labelText: 'Recordatorio',
                          prefixIcon: Icon(Icons.alarm_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Sin recordatorio'),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child: Text('10 minutos antes'),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text('30 minutos antes'),
                          ),
                          DropdownMenuItem(
                            value: 60,
                            child: Text('1 hora antes'),
                          ),
                          DropdownMenuItem(
                            value: 1440,
                            child: Text('1 día antes'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _reminderMinutes = value),
                      ),
                      const SizedBox(height: 16),

                      // Recurrencia
                      DropdownButtonFormField<String>(
                        value: _recurrence,
                        decoration: const InputDecoration(
                          labelText: 'Repetición',
                          prefixIcon: Icon(Icons.repeat_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'none',
                            child: Text('No repetir'),
                          ),
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Todos los días'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Cada semana'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Cada mes'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _recurrence = value ?? 'none';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notas
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notas adicionales (opcional)',
                          hintText: 'Detalles, enlaces o recordatorios clave...',
                          prefixIcon: Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Switch de Fijar tarea
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.push_pin_outlined,
                            color: Colors.amber),
                        title: const Text('Fijar tarea al inicio'),
                        subtitle: const Text(
                            'Aparecerá destacada al principio de la lista'),
                        value: _isPinned,
                        onChanged: (val) {
                          setState(() {
                            _isPinned = val;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Botón guardar estilizado con FilledButton.icon (Etapa 4)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                            _editing ? 'Actualizar tarea' : 'Guardar tarea',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
