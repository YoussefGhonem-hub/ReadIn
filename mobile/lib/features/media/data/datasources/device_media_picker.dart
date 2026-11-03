import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/media.dart';
import '../../domain/repositories/media_picker.dart';

/// `image_picker` (photo library, multi-select) + `file_picker` (PDF only).
@LazySingleton(as: MediaPicker)
class DeviceMediaPicker implements MediaPicker {
  final _images = ImagePicker();

  @override
  Future<List<PickedMediaFile>> pickImages({required int limit}) async {
    if (limit < 1) return const [];
    // Full metadata is not needed (EXIF is dropped anyway) and would trigger
    // the photo-library permission prompt on iOS.
    final files = await _images.pickMultiImage(limit: limit, requestFullMetadata: false);
    return [
      for (final f in files.take(limit)) PickedMediaFile(path: f.path, name: f.name, sizeBytes: await f.length()),
    ];
  }

  @override
  Future<PickedMediaFile?> pickPdf() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf']);
    if (file == null) return null;
    final size = file.lengthSync() ?? await file.length();
    var path = file.path;
    // Storage Access Framework results may only expose a content:// URI;
    // uploads need a local file, so copy it (oversized files are rejected
    // by the caller without being read).
    if (path == null && (size ?? 0) <= AttachmentLimits.maxPdfBytes) {
      final dir = await getTemporaryDirectory();
      final copy = File('${dir.path}${Platform.pathSeparator}${pdfFileName(file.name)}');
      await copy.writeAsBytes(await file.readAsBytes(), flush: true);
      path = copy.path;
    }
    return PickedMediaFile(path: path ?? '', name: file.name, sizeBytes: size);
  }
}
