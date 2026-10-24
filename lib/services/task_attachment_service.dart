import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_attachment.dart';

class TaskAttachmentService {
  TaskAttachmentService(this.client);
  final SupabaseClient client;

  static const bucketName = 'task-attachments';
  static const maxBytes = 15 * 1024 * 1024;
  static const allowedMime = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
    'audio/mp4',
    'audio/mpeg',
    'audio/x-m4a',
    'video/mp4',
  };

  String get userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Inicia sesión');
    return id;
  }

  /// Genera un identificador único UUID v4 RFC-4122 para evitar colisiones en Storage.
  static String generateUuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }

  /// Infiere el tipo MIME a partir del nombre o extensión del archivo.
  static String? lookupMimeFromPath(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return switch (ext) {
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.pdf' => 'application/pdf',
      '.m4a' => 'audio/mp4',
      '.mp3' => 'audio/mpeg',
      '.mp4' => 'video/mp4',
      _ => null,
    };
  }

  /// Valida reglas de negocio y seguridad (tamaño 1B..15MB y MIME permitido) sin depender de red.
  static ({String mime, int bytes}) inspectBytes({
    required Uint8List bytes,
    required String fileName,
  }) {
    final length = bytes.length;
    if (length < 1 || length > maxBytes) {
      throw StateError('Archivo vacío o mayor de 15 MB');
    }
    final mime = lookupMimeFromPath(fileName);
    if (mime == null || !allowedMime.contains(mime)) {
      throw StateError('Formato no permitido: ${mime ?? p.extension(fileName)}');
    }
    return (mime: mime, bytes: length);
  }

  Future<({String mime, int bytes})> inspect(File file) async {
    final bytes = await file.length();
    if (bytes < 1 || bytes > maxBytes) {
      throw StateError('Archivo vacío o mayor de 15 MB');
    }
    final mime = lookupMimeFromPath(file.path);
    if (mime == null || !allowedMime.contains(mime)) {
      throw StateError('Formato no permitido: $mime');
    }
    return (mime: mime, bytes: bytes);
  }

  /// Método único de subida compatible con Web y Android (recibe bytes y nombre).
  Future<void> uploadBytes({
    required int taskId,
    required Uint8List bytes,
    required String fileName,
    required String displayName,
    String? description,
  }) async {
    final uid = userId;
    await client
        .from('tasks')
        .select('id')
        .eq('id', taskId)
        .eq('user_id', uid)
        .single();

    final info = inspectBytes(bytes: bytes, fileName: fileName);
    final name = displayName.trim();
    if (name.isEmpty || name.length > 150) {
      throw StateError('Nombre entre 1 y 150 caracteres');
    }
    final cleanDesc = description?.trim();
    if (cleanDesc != null && cleanDesc.length > 500) {
      throw StateError('Descripción máxima: 500 caracteres');
    }

    final extension = p.extension(fileName).toLowerCase();
    final objectPath = '$uid/$taskId/${generateUuidV4()}$extension';
    final bucket = client.storage.from(bucketName);

    await bucket.uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(contentType: info.mime),
    );

    try {
      await client.from('task_attachments').insert({
        'task_id': taskId,
        'user_id': uid,
        'storage_path': objectPath,
        'original_name': name,
        'description': (cleanDesc == null || cleanDesc.isEmpty) ? null : cleanDesc,
        'mime_type': info.mime,
        'size_bytes': info.bytes,
      });
    } catch (_) {
      try {
        await bucket.remove([objectPath]);
      } catch (_) {
        // Si falla la limpieza, revisaremos Storage.
      }
      rethrow;
    }
  }

  /// Método uploadFile de la guía que delega en uploadBytes.
  Future<void> uploadFile({
    required int taskId,
    required File file,
    required String displayName,
  }) async {
    final bytes = await file.readAsBytes();
    await uploadBytes(
      taskId: taskId,
      bytes: bytes,
      fileName: file.path,
      displayName: displayName,
    );
  }

  Future<List<TaskAttachment>> listForTask(int taskId) async {
    final rows = await client
        .from('task_attachments')
        .select()
        .eq('task_id', taskId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => TaskAttachment.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<String> signedUrl(TaskAttachment a) async {
    return client.storage.from(bucketName).createSignedUrl(a.storagePath, 300);
  }

  Future<Uint8List> downloadBytes(TaskAttachment a) async {
    return client.storage.from(bucketName).download(a.storagePath);
  }

  Future<File> downloadToTemp(TaskAttachment a) async {
    final bytes = await client.storage.from(bucketName).download(a.storagePath);
    final dir = await Directory.systemTemp.createTemp('taski_');
    final ext = p.extension(a.storagePath);
    return File('${dir.path}/adjunto$ext').writeAsBytes(bytes, flush: true);
  }

  Future<void> updateMetadata({
    required TaskAttachment attachment,
    required String name,
    required String description,
  }) async {
    final cleanName = name.trim();
    final cleanDescription = description.trim();
    if (cleanName.isEmpty || cleanName.length > 150) {
      throw StateError('Nombre entre 1 y 150 caracteres');
    }
    if (cleanDescription.length > 500) {
      throw StateError('Descripción máxima: 500 caracteres');
    }
    await client
        .from('task_attachments')
        .update({
          'original_name': cleanName,
          'description': cleanDescription.isEmpty ? null : cleanDescription,
          'version': attachment.version + 1,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', attachment.id)
        .eq('version', attachment.version)
        .select('id')
        .single();
  }

  Future<void> replaceBytes({
    required TaskAttachment attachment,
    required Uint8List newBytes,
    required String fileName,
  }) async {
    final uid = userId;
    final info = inspectBytes(bytes: newBytes, fileName: fileName);
    final ext = p.extension(fileName).toLowerCase();
    final newPath = '$uid/${attachment.taskId}/${generateUuidV4()}$ext';
    final bucket = client.storage.from(bucketName);

    await bucket.uploadBinary(
      newPath,
      newBytes,
      fileOptions: FileOptions(contentType: info.mime),
    );

    try {
      await client
          .from('task_attachments')
          .update({
            'storage_path': newPath,
            'mime_type': info.mime,
            'size_bytes': info.bytes,
            'version': attachment.version + 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', attachment.id)
          .eq('version', attachment.version)
          .select('id')
          .single();
    } catch (_) {
      try {
        await bucket.remove([newPath]);
      } catch (_) {}
      rethrow;
    }

    try {
      await bucket.remove([attachment.storagePath]);
    } catch (_) {
      // El registro ya apunta al nuevo objeto; limpiar el anterior.
    }
  }

  Future<void> replaceFile({
    required TaskAttachment attachment,
    required File newFile,
  }) async {
    final bytes = await newFile.readAsBytes();
    await replaceBytes(
      attachment: attachment,
      newBytes: bytes,
      fileName: newFile.path,
    );
  }

  Future<void> deleteAttachment(TaskAttachment attachment) async {
    await client
        .from('task_attachments')
        .delete()
        .eq('id', attachment.id)
        .eq('version', attachment.version)
        .select('id')
        .single();

    await client.storage.from(bucketName).remove([attachment.storagePath]);
  }
}
