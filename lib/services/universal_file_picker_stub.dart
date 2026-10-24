import 'dart:typed_data';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

Future<({Uint8List bytes, String name})?> pickUniversalFile({
  required List<String> allowedExtensions,
  String label = 'Archivos permitidos',
}) async {
  final xFile = await FileSelectorPlatform.instance.openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: label,
        extensions: allowedExtensions,
      ),
    ],
  );
  if (xFile == null) return null;
  final bytes = await xFile.readAsBytes();
  final name = xFile.name.isNotEmpty
      ? xFile.name
      : 'archivo.${allowedExtensions.first}';
  return (bytes: bytes, name: name);
}
