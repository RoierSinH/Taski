import 'dart:typed_data';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

Future<({Uint8List bytes, String name})?> pickUniversalFile({
  required List<String> allowedExtensions,
  String label = 'Archivos permitidos',
}) async {
  final acceptList = <String>[];
  for (final ext in allowedExtensions) {
    final clean = ext.toLowerCase().replaceFirst('.', '');
    acceptList.add('.$clean');
    switch (clean) {
      case 'pdf':
        acceptList.add('application/pdf');
      case 'jpg':
      case 'jpeg':
        acceptList.add('image/jpeg');
      case 'png':
        acceptList.add('image/png');
      case 'webp':
        acceptList.add('image/webp');
      case 'm4a':
        acceptList.add('audio/mp4');
        acceptList.add('audio/x-m4a');
      case 'mp3':
        acceptList.add('audio/mpeg');
      case 'wav':
        acceptList.add('audio/wav');
      case 'mp4':
        acceptList.add('video/mp4');
    }
  }

  final accept = acceptList.toSet().join(',');
  final platform = ImagePickerPlatform.instance;
  final List<XFile> files;
  if (platform is ImagePickerPlugin) {
    files = await platform.getFiles(accept: accept);
  } else {
    files = await ImagePickerPlugin().getFiles(accept: accept);
  }

  if (files.isEmpty) return null;
  final xFile = files.first;
  final bytes = await xFile.readAsBytes();
  final defaultExt = allowedExtensions.first.replaceFirst('.', '');
  String name = xFile.name.trim();
  if (name.isEmpty) {
    name = 'archivo.$defaultExt';
  } else if (!name.contains('.')) {
    name = '$name.$defaultExt';
  }
  return (bytes: bytes, name: name);
}
