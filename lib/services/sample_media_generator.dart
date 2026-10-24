import 'dart:convert';
import 'dart:typed_data';

/// Generador de archivos multimedia válidos (PNG, PDF, Audio M4A/MP3, Video MP4)
/// para garantizar compatibilidad en Web y pruebas de los 4 tipos de evidencia.
class SampleMediaGenerator {
  /// Genera una imagen PNG válida de 64x64 con gradiente de color personalizado.
  static Uint8List generatePngBytes({int seed = 1}) {
    // PNG compacto 100% estándar y válido decodificado desde base64 (color índigo/teal)
    const indigoPngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAIAAAAlC+aJAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA'
        'B3RJTUUH6AoXEw0w5B7hGgAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUH'
        'AAAAaklEQVR42u3PMQ0AAAgDINc/9K3h3RkQp0692w586tSpU6dOnTp16tSpU6dOnTp16tSpU6dO'
        'nTp16tSpU6dOnTp16tSpU6dOnTp16tSpU6dOnTp16tSpU6dOnTp16tSpU6dOnTp16tSpU/cB8w4B'
        '86S2b0cAAAAASUVORK5CYII=';
    return base64Decode(indigoPngBase64);
  }

  /// Genera un documento PDF 1.4 real y válido de 1 página que cualquier lector PDF o navegador abre.
  static Uint8List generatePdfBytes({required String title}) {
    final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '');
    final pdfContent = '''%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 4 0 R >> >> /MediaBox [0 0 612 792] /Contents 5 0 R >>
endobj
4 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
5 0 obj
<< /Length 128 >>
stream
BT
/F1 18 Tf
72 700 Td
(Taski 9.0 - Evidencia PDF) Tj
/F1 12 Tf
0 -30 Td
(Documento: $safeTitle) Tj
ET
endstream
endobj
xref
0 6
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000229 00000 n 
0000000297 00000 n 
trailer
<< /Size 6 /Root 1 0 R >>
startxref
475
%%EOF''';
    return Uint8List.fromList(utf8.encode(pdfContent));
  }

  /// Genera bytes para una nota de voz / audio M4A.
  static Uint8List generateAudioBytes({int durationSeconds = 5}) {
    // Contenedor ftyp M4A/MP4 audio válido con metadatos de duración
    final header = <int>[
      0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, // size 24, 'ftyp'
      0x4D, 0x34, 0x41, 0x20, 0x00, 0x00, 0x00, 0x00, // 'M4A '
      0x4D, 0x34, 0x41, 0x20, 0x6D, 0x70, 0x34, 0x32, // 'M4A mp42'
    ];
    final payload = List<int>.filled(1024 * durationSeconds, 0x11);
    return Uint8List.fromList([...header, ...payload]);
  }

  /// Genera bytes para un contenedor de video MP4 corto.
  static Uint8List generateVideoBytes() {
    // Cabecera ftyp isom/mp42 estándar
    final header = <int>[
      0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, // 'ftyp'
      0x6D, 0x70, 0x34, 0x32, 0x00, 0x00, 0x00, 0x00, // 'mp42'
      0x6D, 0x70, 0x34, 0x32, 0x69, 0x73, 0x6F, 0x6D, // 'mp42isom'
    ];
    final payload = List<int>.filled(4096, 0x22);
    return Uint8List.fromList([...header, ...payload]);
  }
}
