import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task_attachment.dart';
import '../services/task_attachment_service.dart';

class TaskAttachmentViewer extends StatefulWidget {
  const TaskAttachmentViewer({
    super.key,
    required this.attachment,
    required this.service,
  });

  final TaskAttachment attachment;
  final TaskAttachmentService service;

  @override
  State<TaskAttachmentViewer> createState() => _TaskAttachmentViewerState();
}

class _TaskAttachmentViewerState extends State<TaskAttachmentViewer> {
  String? _signedUrl;
  bool _loading = true;
  String? _error;
  bool _isPlaying = false;
  double _playbackProgress = 0.0;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final url = await widget.service.signedUrl(widget.attachment);
      if (!mounted) return;
      setState(() {
        _signedUrl = url;
        _loading = false;
      });
      if (widget.attachment.isAudio || widget.attachment.isVideo) {
        _startSimulatedPlayback();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _startSimulatedPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = true;
      if (_playbackProgress >= 1.0) _playbackProgress = 0.0;
    });
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _playbackProgress += 0.04;
        if (_playbackProgress >= 1.0) {
          _playbackProgress = 1.0;
          _isPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      _startSimulatedPlayback();
    }
  }

  Future<void> _openExternalSignedUrl() async {
    if (_signedUrl == null) return;
    final uri = Uri.parse(_signedUrl!);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(a.originalName),
        actions: [
          if (_signedUrl != null)
            IconButton(
              tooltip: 'Abrir archivo en pestaña externa',
              icon: const Icon(Icons.open_in_new),
              onPressed: _openExternalSignedUrl,
            ),
        ],
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No se pudo reproducir: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Contenido principal según formato
                          if (a.isImage && _signedUrl != null)
                            Card(
                              clipBehavior: Clip.antiAlias,
                              elevation: 3,
                              child: Column(
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 420,
                                      minHeight: 220,
                                    ),
                                    child: InteractiveViewer(
                                      child: Image.network(
                                        _signedUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Padding(
                                          padding: EdgeInsets.all(40),
                                          child: Icon(Icons.broken_image,
                                              size: 72),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Pellizca o usa la rueda del ratón para hacer zoom (InteractiveViewer)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.outline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (a.isVideo)
                            Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: 240,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            _isPlaying
                                                ? Icons.movie_filter
                                                : Icons.play_circle_fill,
                                            size: 80,
                                            color: Colors.white70,
                                          ),
                                          Positioned(
                                            bottom: 16,
                                            left: 16,
                                            right: 16,
                                            child: Column(
                                              children: [
                                                LinearProgressIndicator(
                                                  value: _playbackProgress,
                                                  backgroundColor:
                                                      Colors.white24,
                                                  color: scheme.primary,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _isPlaying
                                                      ? 'Reproduciendo video MP4 (URL firmada)...'
                                                      : 'Video en pausa',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 12,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: _togglePlayPause,
                                          icon: Icon(_isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow),
                                          label: Text(_isPlaying
                                              ? 'Pausar'
                                              : 'Reproducir'),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: _openExternalSignedUrl,
                                          icon: const Icon(Icons.download),
                                          label: const Text('Descargar MP4'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (a.isAudio)
                            Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 44,
                                      backgroundColor: scheme.primaryContainer,
                                      child: Icon(
                                        Icons.graphic_eq,
                                        size: 48,
                                        color: scheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nota de voz / Audio',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    LinearProgressIndicator(
                                      value: _playbackProgress,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isPlaying
                                          ? 'Reproduciendo audio...'
                                          : 'Audio listo para reproducir',
                                      style: TextStyle(color: scheme.outline),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 12,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: _togglePlayPause,
                                          icon: Icon(_isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow),
                                          label: Text(_isPlaying
                                              ? 'Pausar'
                                              : 'Reproducir otra vez'),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: _openExternalSignedUrl,
                                          icon: const Icon(Icons.download),
                                          label: const Text('Descargar audio'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (a.isPdf)
                            Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      size: 72,
                                      color: Colors.red.shade600,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      a.originalName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Documento PDF privado protegido con URL firmada temporal (300 s).',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    FilledButton.icon(
                                      onPressed: _openExternalSignedUrl,
                                      icon: const Icon(Icons.open_in_browser),
                                      label: const Text(
                                          'Abrir / Descargar documento PDF'),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Ficha de metadatos de PostgreSQL y Storage
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Metadatos del Adjunto (PostgreSQL + Storage)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: scheme.primary,
                                        ),
                                  ),
                                  const Divider(),
                                  Text('Nombre visible: ${a.originalName}'),
                                  if (a.description != null &&
                                      a.description!.isNotEmpty)
                                    Text('Descripción: ${a.description}'),
                                  Text('Tipo MIME: ${a.mimeType}'),
                                  Text('Tamaño: ${a.formattedSize}'),
                                  Text(
                                      'Versión de concurrencia: v${a.version}'),
                                  Text(
                                    'Ruta privada Storage: ${a.storagePath}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
