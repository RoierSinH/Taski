import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_primera_app/models/task_attachment.dart';
import 'package:mi_primera_app/services/sample_media_generator.dart';
import 'package:mi_primera_app/services/task_attachment_service.dart';

void main() {
  group('TaskAttachment Model & TaskAttachmentService Validations (Parte 9)', () {
    test('TaskAttachment.fromMap mapea correctamente y clasifica tipos MIME', () {
      final imgMap = {
        'id': 10,
        'task_id': 5,
        'storage_path': 'uid-1/5/123_foto.png',
        'original_name': 'foto_evidencia.png',
        'mime_type': 'image/png',
        'size_bytes': 2048,
        'version': 2,
        'description': 'Evidencia visual de la tarea',
      };
      final attachment = TaskAttachment.fromMap(imgMap);

      expect(attachment.id, 10);
      expect(attachment.taskId, 5);
      expect(attachment.isImage, isTrue);
      expect(attachment.isPdf, isFalse);
      expect(attachment.isAudio, isFalse);
      expect(attachment.isVideo, isFalse);
      expect(attachment.typeLabel, 'Fotografía');
      expect(attachment.formattedSize, '2.0 KB');
      expect(attachment.version, 2);
    });

    test('inspectBytes rechaza archivos vacíos y tipos no permitidos', () {
      expect(
        () => TaskAttachmentService.inspectBytes(
          bytes: Uint8List(0),
          fileName: 'vacio.png',
        ),
        throwsStateError,
      );

      expect(
        () => TaskAttachmentService.inspectBytes(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'script.exe',
        ),
        throwsStateError,
      );
    });

    test('inspectBytes acepta los 4 formatos multimedia (Imagen, PDF, Audio, Video)', () {
      final pngBytes = SampleMediaGenerator.generatePngBytes();
      final pdfBytes = SampleMediaGenerator.generatePdfBytes(
        title: 'Evidencia PDF',
      );
      final audioBytes = SampleMediaGenerator.generateAudioBytes();
      final videoBytes = SampleMediaGenerator.generateVideoBytes();

      final imgMeta = TaskAttachmentService.inspectBytes(
        bytes: pngBytes,
        fileName: 'captura.png',
      );
      expect(imgMeta.mime, 'image/png');
      expect(imgMeta.bytes, greaterThan(0));

      final pdfMeta = TaskAttachmentService.inspectBytes(
        bytes: pdfBytes,
        fileName: 'reporte.pdf',
      );
      expect(pdfMeta.mime, 'application/pdf');
      expect(pdfMeta.bytes, greaterThan(0));

      final audioMeta = TaskAttachmentService.inspectBytes(
        bytes: audioBytes,
        fileName: 'nota_voz.m4a',
      );
      expect(audioMeta.mime, 'audio/mp4');
      expect(audioMeta.bytes, greaterThan(0));

      final videoMeta = TaskAttachmentService.inspectBytes(
        bytes: videoBytes,
        fileName: 'clip.mp4',
      );
      expect(videoMeta.mime, 'video/mp4');
      expect(videoMeta.bytes, greaterThan(0));
    });
  });
}
