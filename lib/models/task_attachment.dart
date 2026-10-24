class TaskAttachment {
  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.storagePath,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.version,
    this.description,
    this.createdAt,
  });

  final int id;
  final int taskId;
  final String storagePath;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final int version;
  final String? description;
  final DateTime? createdAt;

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isVideo => mimeType.startsWith('video/');

  String get typeLabel {
    if (isImage) return 'Fotografía';
    if (isPdf) return 'Documento PDF';
    if (isAudio) return 'Audio / Voz';
    if (isVideo) return 'Video MP4';
    return 'Archivo';
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  factory TaskAttachment.fromMap(Map<String, dynamic> row) {
    return TaskAttachment(
      id: (row['id'] as num).toInt(),
      taskId: (row['task_id'] as num).toInt(),
      storagePath: row['storage_path'] as String,
      originalName: row['original_name'] as String,
      mimeType: row['mime_type'] as String,
      sizeBytes: (row['size_bytes'] as num).toInt(),
      version: (row['version'] as num).toInt(),
      description: row['description'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'].toString())?.toLocal()
          : null,
    );
  }
}
