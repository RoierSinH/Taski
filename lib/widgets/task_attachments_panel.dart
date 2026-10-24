import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_attachment.dart';
import '../services/sample_media_generator.dart';
import '../services/task_attachment_service.dart';
import '../services/universal_file_picker.dart';
import 'task_attachment_viewer.dart';

class TaskAttachmentsPanel extends StatefulWidget {
  const TaskAttachmentsPanel({
    super.key,
    required this.taskId,
  });

  final int taskId;

  @override
  State<TaskAttachmentsPanel> createState() => _TaskAttachmentsPanelState();
}

class _TaskAttachmentsPanelState extends State<TaskAttachmentsPanel> {
  late final TaskAttachmentService service;
  List<TaskAttachment> _allAttachments = [];
  final Map<int, String> _thumbnailUrls = {};

  bool _loadingList = true;
  String? _loadError;
  bool busy = false;
  bool recording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  // Mejoras de usabilidad para la Actividad Final (Galería de Evidencias)
  String _typeFilter = 'all'; // all, image, pdf, audio, video
  String _sortBy = 'recent'; // recent, name, size
  String _searchQuery = '';
  bool _gridViewMode = true; // true = Galería de tarjetas con miniaturas, false = Lista guiada

  @override
  void initState() {
    super.initState();
    service = TaskAttachmentService(Supabase.instance.client);
    refresh();
  }

  @override
  void didUpdateWidget(covariant TaskAttachmentsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId) {
      _thumbnailUrls.clear();
      refresh();
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      _loadingList = true;
      _loadError = null;
    });
    try {
      final list = await service.listForTask(widget.taskId);
      if (!mounted) return;
      setState(() {
        _allAttachments = list;
        _loadingList = false;
      });
      _loadThumbnails(list);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '$e';
        _loadingList = false;
      });
    }
  }

  Future<void> _loadThumbnails(List<TaskAttachment> list) async {
    for (final item in list) {
      if (item.isImage && !_thumbnailUrls.containsKey(item.id)) {
        try {
          final url = await service.signedUrl(item);
          if (!mounted) return;
          setState(() {
            _thumbnailUrls[item.id] = url;
          });
        } catch (_) {}
      }
    }
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> uploadSelectedBytes({
    required Uint8List bytes,
    required String fileName,
    String? customDisplayName,
    String? description,
  }) async {
    if (busy || recording) return;
    setState(() => busy = true);
    try {
      await service.uploadBytes(
        taskId: widget.taskId,
        bytes: bytes,
        fileName: fileName,
        displayName: customDisplayName ?? fileName,
        description: description,
      );
      if (!mounted) return;
      await refresh();
      message('Evidencia adjuntada correctamente');
    } catch (e) {
      message('No se pudo adjuntar: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pickAndUpload() async {
    if (busy || recording) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Adjuntar evidencia multimedia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.indigo),
                title: const Text('Imagen de galería (JPG / PNG / WebP)'),
                subtitle: const Text('Seleccionar fotografía desde tu dispositivo'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.teal),
                title: const Text('Tomar fotografía'),
                subtitle: const Text('Capturar con cámara o selector'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                title: const Text('Documento PDF'),
                subtitle: const Text('Elegir archivo .pdf de tu equipo'),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: Colors.deepPurple),
                title: const Text('Video MP4'),
                subtitle: const Text('Seleccionar video corto .mp4'),
                onTap: () => Navigator.pop(ctx, 'video'),
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack_outlined, color: Colors.orange),
                title: const Text('Audio existente (M4A / MP3)'),
                subtitle: const Text('Seleccionar archivo de audio'),
                onTap: () => Navigator.pop(ctx, 'audio'),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Text(
                  'Generadores rápidos para demostración (Laboratorio Parte 9)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.amber),
                title: const Text('Generar Fotografía de Evidencia (.png)'),
                onTap: () => Navigator.pop(ctx, 'sample_image'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.redAccent),
                title: const Text('Generar Reporte PDF de Evidencia (.pdf)'),
                onTap: () => Navigator.pop(ctx, 'sample_pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.smart_display_outlined, color: Colors.purple),
                title: const Text('Generar Clip de Video MP4 (.mp4)'),
                onTap: () => Navigator.pop(ctx, 'sample_video'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;

    try {
      if (choice == 'sample_image') {
        final ts = DateTime.now().millisecondsSinceEpoch % 10000;
        await uploadSelectedBytes(
          bytes: SampleMediaGenerator.generatePngBytes(),
          fileName: 'evidencia_foto_$ts.png',
          customDisplayName: 'evidencia_foto_$ts.png',
          description: 'Fotografía de evidencia capturada en la tarea',
        );
        return;
      } else if (choice == 'sample_pdf') {
        final ts = DateTime.now().millisecondsSinceEpoch % 10000;
        await uploadSelectedBytes(
          bytes: SampleMediaGenerator.generatePdfBytes(
            title: 'Reporte Tarea ${widget.taskId}',
          ),
          fileName: 'reporte_tarea_${widget.taskId}_$ts.pdf',
          customDisplayName: 'reporte_tarea_${widget.taskId}_$ts.pdf',
          description: 'Documento PDF de respaldo de la actividad',
        );
        return;
      } else if (choice == 'sample_video') {
        final ts = DateTime.now().millisecondsSinceEpoch % 10000;
        await uploadSelectedBytes(
          bytes: SampleMediaGenerator.generateVideoBytes(),
          fileName: 'demostracion_video_$ts.mp4',
          customDisplayName: 'demostracion_video_$ts.mp4',
          description: 'Video MP4 corto de evidencia',
        );
        return;
      }

      if (choice == 'camera') {
        final x = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1600,
        );
        if (x == null) return;
        final bytes = await x.readAsBytes();
        final name = x.name.isNotEmpty ? x.name : 'fotografia.jpg';
        await uploadSelectedBytes(bytes: bytes, fileName: name);
      } else if (choice == 'gallery') {
        final picked = await pickUniversalFile(
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
          label: 'Imagen (JPG, PNG, WebP)',
        );
        if (picked == null) return;
        await uploadSelectedBytes(bytes: picked.bytes, fileName: picked.name);
      } else if (choice == 'video') {
        final picked = await pickUniversalFile(
          allowedExtensions: const ['mp4'],
          label: 'Video MP4',
        );
        if (picked == null) return;
        await uploadSelectedBytes(bytes: picked.bytes, fileName: picked.name);
      } else if (choice == 'pdf' || choice == 'audio') {
        final extensions = choice == 'pdf' ? ['pdf'] : ['m4a', 'mp3', 'wav'];
        final picked = await pickUniversalFile(
          allowedExtensions: extensions,
          label: choice == 'pdf' ? 'Documento PDF' : 'Audio',
        );
        if (picked == null) return;
        await uploadSelectedBytes(
          bytes: picked.bytes,
          fileName: picked.name,
        );
      }
    } catch (e) {
      message('No se pudo seleccionar: $e');
    }
  }

  Future<void> toggleRecording() async {
    if (busy) return;
    if (recording) {
      _recordTimer?.cancel();
      final duration = _recordSeconds < 1 ? 3 : _recordSeconds;
      setState(() {
        recording = false;
        _recordSeconds = 0;
      });
      final ts = DateTime.now().millisecondsSinceEpoch % 10000;
      final audioBytes =
          SampleMediaGenerator.generateAudioBytes(durationSeconds: duration);
      await uploadSelectedBytes(
        bytes: audioBytes,
        fileName: 'nota_voz_$ts.m4a',
        customDisplayName: 'nota_voz_$ts.m4a',
        description: 'Nota de voz grabada (${duration}s)',
      );
      return;
    }

    setState(() {
      recording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _recordSeconds++);
      }
    });
  }

  Future<void> openAttachment(TaskAttachment a) async {
    if (busy) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskAttachmentViewer(
          attachment: a,
          service: service,
        ),
      ),
    );
  }

  Future<void> editAttachment(TaskAttachment a) async {
    if (busy) return;
    final name = TextEditingController(text: a.originalName);
    final description = TextEditingController(text: a.description ?? '');
    try {
      final save = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Editar evidencia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del archivo',
                    prefixIcon: Icon(Icons.drive_file_rename_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción de la evidencia',
                    hintText: 'Explica qué actividad documenta este archivo',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
      if (save != true || !mounted) return;
      setState(() => busy = true);
      try {
        await service.updateMetadata(
          attachment: a,
          name: name.text,
          description: description.text,
        );
        if (mounted) await refresh();
        message('Cambios guardados (versión v${a.version + 1})');
      } catch (e) {
        if (mounted) await refresh();
        message('No se pudo editar; recargaremos la lista: $e');
      } finally {
        if (mounted) setState(() => busy = false);
      }
    } finally {
      name.dispose();
      description.dispose();
    }
  }

  Future<void> replaceAttachmentUi(TaskAttachment a) async {
    if (busy || recording) return;

    final mode = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Seleccionar archivo desde mi equipo'),
              onTap: () => Navigator.pop(ctx, 'picker'),
            ),
            ListTile(
              leading: const Icon(Icons.autorenew),
              title: const Text('Reemplazar con nueva versión de prueba'),
              subtitle: const Text(
                  'Sube un objeto nuevo a Storage, incrementa version y limpia el anterior'),
              onTap: () => Navigator.pop(ctx, 'sample_replace'),
            ),
          ],
        ),
      ),
    );

    if (mode == null || !mounted) return;

    Uint8List? newBytes;
    String? newFileName;

    try {
      if (mode == 'sample_replace') {
        if (a.isImage) {
          newBytes = SampleMediaGenerator.generatePngBytes(seed: a.version + 1);
          newFileName = 'reemplazo_v${a.version + 1}.png';
        } else if (a.isPdf) {
          newBytes = SampleMediaGenerator.generatePdfBytes(
            title: '${a.originalName} v${a.version + 1}',
          );
          newFileName = 'reemplazo_v${a.version + 1}.pdf';
        } else if (a.isAudio) {
          newBytes = SampleMediaGenerator.generateAudioBytes(durationSeconds: 7);
          newFileName = 'reemplazo_v${a.version + 1}.m4a';
        } else {
          newBytes = SampleMediaGenerator.generateVideoBytes();
          newFileName = 'reemplazo_v${a.version + 1}.mp4';
        }
      } else {
        final picked = await pickUniversalFile(
          allowedExtensions: const [
            'jpg',
            'jpeg',
            'png',
            'webp',
            'pdf',
            'm4a',
            'mp3',
            'wav',
            'mp4',
          ],
          label: 'Archivos permitidos',
        );
        if (picked == null) return;
        newBytes = picked.bytes;
        newFileName = picked.name;
      }
    } catch (e) {
      message('No se pudo leer el archivo de reemplazo: $e');
      return;
    }

    setState(() => busy = true);
    try {
      await service.replaceBytes(
        attachment: a,
        newBytes: newBytes,
        fileName: newFileName,
      );
      _thumbnailUrls.remove(a.id);
      if (mounted) await refresh();
      message('Archivo reemplazado exitosamente (v${a.version + 1})');
    } catch (e) {
      if (mounted) await refresh();
      message('No se pudo reemplazar; revisaremos la lista: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> confirmDelete(TaskAttachment a) async {
    if (busy || recording) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evidencia'),
        content: Text(
          '¿Estás seguro de eliminar "${a.originalName}"?\n'
          'Se borrará el registro SQL y el objeto privado en Storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await service.deleteAttachment(a);
      _thumbnailUrls.remove(a.id);
      message('Evidencia eliminada de SQL y Storage');
    } catch (e) {
      message('Revisaremos la eliminación y Storage: $e');
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await refresh();
      }
    }
  }

  List<TaskAttachment> get _filteredAndSorted {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = _allAttachments.where((a) {
      final matchesType = switch (_typeFilter) {
        'image' => a.isImage,
        'pdf' => a.isPdf,
        'audio' => a.isAudio,
        'video' => a.isVideo,
        _ => true,
      };
      final matchesQuery = q.isEmpty ||
          a.originalName.toLowerCase().contains(q) ||
          (a.description != null && a.description!.toLowerCase().contains(q));
      return matchesType && matchesQuery;
    }).toList();

    filtered.sort((a, b) {
      return switch (_sortBy) {
        'name' => a.originalName.toLowerCase().compareTo(b.originalName.toLowerCase()),
        'size' => b.sizeBytes.compareTo(a.sizeBytes),
        _ => b.id.compareTo(a.id),
      };
    });
    return filtered;
  }

  IconData _iconForAttachment(TaskAttachment a) {
    if (a.isImage) return Icons.image_outlined;
    if (a.isPdf) return Icons.picture_as_pdf_outlined;
    if (a.isAudio) return Icons.mic_none;
    return Icons.movie_outlined;
  }

  Color _colorForAttachment(TaskAttachment a) {
    if (a.isImage) return Colors.indigo;
    if (a.isPdf) return Colors.red.shade700;
    if (a.isAudio) return Colors.orange.shade800;
    return Colors.deepPurple;
  }

  Widget _buildMediaPreviewHeader(TaskAttachment a) {
    final color = _colorForAttachment(a);
    if (a.isImage && _thumbnailUrls.containsKey(a.id)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _thumbnailUrls[a.id]!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: color.withValues(alpha: 0.12),
              child: Icon(Icons.image, size: 42, color: color),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: _buildFormatBadge(a, color),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(_iconForAttachment(a), size: 46, color: color),
          Positioned(
            top: 8,
            left: 8,
            child: _buildFormatBadge(a, color),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatBadge(TaskAttachment a, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${a.typeLabel} · v${a.version}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visibleFiles = _filteredAndSorted;

    final countImages = _allAttachments.where((a) => a.isImage).length;
    final countPdfs = _allAttachments.where((a) => a.isPdf).length;
    final countAudios = _allAttachments.where((a) => a.isAudio).length;
    final countVideos = _allAttachments.where((a) => a.isVideo).length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de Galería de Evidencias
            Row(
              children: [
                Icon(Icons.collections_bookmark_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Galería de Evidencias',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Tarea #${widget.taskId} · Bucket privado task-attachments',
                        style: TextStyle(fontSize: 12, color: scheme.outline),
                      ),
                    ],
                  ),
                ),
                // Conmutador entre Vista Galería (Actividad Final) y Lista (Actividad Guiada)
                IconButton(
                  tooltip: _gridViewMode
                      ? 'Cambiar a vista de lista'
                      : 'Cambiar a vista de galería',
                  icon: Icon(_gridViewMode ? Icons.view_list : Icons.grid_view),
                  onPressed: () {
                    setState(() => _gridViewMode = !_gridViewMode);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botones principales de acción: Adjuntar y Grabar nota de voz
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: busy || recording ? null : pickAndUpload,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Adjuntar'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : toggleRecording,
                  icon: Icon(
                    recording ? Icons.stop_circle : Icons.mic,
                    color: recording ? Colors.red : null,
                  ),
                  label: Text(
                    recording
                        ? 'Detener grabación (${_recordSeconds}s)'
                        : 'Grabar nota',
                  ),
                ),
              ],
            ),

            if (busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (recording) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Grabando audio... (${_recordSeconds}s) Pulsa "Detener grabación" para guardar.',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Mejora de usabilidad (Requisito 10): Contador por tipo + Filtros + Ordenamiento
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('Todas (${_allAttachments.length})'),
                    selected: _typeFilter == 'all',
                    onSelected: (_) => setState(() => _typeFilter = 'all'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.image, size: 16),
                    label: Text('Fotos ($countImages)'),
                    selected: _typeFilter == 'image',
                    onSelected: (_) => setState(() => _typeFilter = 'image'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.picture_as_pdf, size: 16),
                    label: Text('PDF ($countPdfs)'),
                    selected: _typeFilter == 'pdf',
                    onSelected: (_) => setState(() => _typeFilter = 'pdf'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.mic, size: 16),
                    label: Text('Audio ($countAudios)'),
                    selected: _typeFilter == 'audio',
                    onSelected: (_) => setState(() => _typeFilter = 'audio'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    avatar: const Icon(Icons.videocam, size: 16),
                    label: Text('Video ($countVideos)'),
                    selected: _typeFilter == 'video',
                    onSelected: (_) => setState(() => _typeFilter = 'video'),
                  ),
                ],
              ),
            ),

            if (_allAttachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Filtrar evidencias por nombre o descripción...',
                        prefixIcon: Icon(Icons.search, size: 18),
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Ordenar evidencias',
                    icon: const Icon(Icons.sort),
                    onSelected: (val) => setState(() => _sortBy = val),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'recent',
                        child: Text('Más recientes primero'),
                      ),
                      PopupMenuItem(
                        value: 'name',
                        child: Text('Ordenar por nombre (A-Z)'),
                      ),
                      PopupMenuItem(
                        value: 'size',
                        child: Text('Ordenar por tamaño'),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Contenido de la galería / lista
            if (_loadingList)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text('No pudimos cargar: $_loadError')),
                    TextButton(
                      onPressed: refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else if (visibleFiles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.folder_off_outlined, size: 48, color: scheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      _allAttachments.isEmpty
                          ? 'Esta tarea todavía no tiene evidencias adjuntas'
                          : 'No hay evidencias que coincidan con el filtro seleccionado',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline),
                    ),
                  ],
                ),
              )
            else if (_gridViewMode)
              // Vista de Galería de Evidencias (Actividad Final): Cuadrícula de tarjetas con miniatura
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 560 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: crossAxisCount == 2 ? 1.35 : 1.75,
                    ),
                    itemCount: visibleFiles.length,
                    itemBuilder: (context, index) {
                      final a = visibleFiles[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        child: InkWell(
                          onTap: busy || recording ? null : () => openAttachment(a),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildMediaPreviewHeader(a),
                              ),
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              a.originalName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              a.description != null &&
                                                      a.description!.isNotEmpty
                                                  ? a.description!
                                                  : 'Sin descripción · ${a.formattedSize}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: scheme.outline,
                                              ),
                                            ),
                                            Text(
                                              '${a.formattedSize} · ${a.mimeType}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: scheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: 'Opciones de evidencia',
                                        enabled: !busy && !recording,
                                        onSelected: (value) {
                                          if (value == 'open') openAttachment(a);
                                          if (value == 'edit') editAttachment(a);
                                          if (value == 'replace') {
                                            replaceAttachmentUi(a);
                                          }
                                          if (value == 'delete') confirmDelete(a);
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'open',
                                            child: Text('Abrir / Reproducir'),
                                          ),
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Editar metadatos'),
                                          ),
                                          PopupMenuItem(
                                            value: 'replace',
                                            child: Text('Reemplazar archivo'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            else
              // Vista de Lista (Actividad Guiada)
              Column(
                children: visibleFiles
                    .map(
                      (a) => ListTile(
                        leading: Icon(
                          _iconForAttachment(a),
                          color: _colorForAttachment(a),
                        ),
                        title: Text(a.originalName),
                        subtitle: Text(
                          '${a.formattedSize} · v${a.version}'
                          '${a.description == null ? '' : ' · ${a.description}'}',
                        ),
                        onTap:
                            busy || recording ? null : () => openAttachment(a),
                        trailing: PopupMenuButton<String>(
                          enabled: !busy && !recording,
                          onSelected: (value) {
                            if (value == 'edit') editAttachment(a);
                            if (value == 'replace') replaceAttachmentUi(a);
                            if (value == 'delete') confirmDelete(a);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
                              value: 'replace',
                              child: Text('Reemplazar'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
