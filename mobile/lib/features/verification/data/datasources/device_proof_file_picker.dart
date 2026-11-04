import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../../media/domain/entities/media.dart';
import '../../domain/entities/verification.dart';
import '../../domain/repositories/verification_repository.dart';

/// `file_picker`, limited to the proof types (PDF, JPEG, PNG, WebP).
@LazySingleton(as: ProofFilePicker)
class DeviceProofFilePicker implements ProofFilePicker {
  @override
  Future<PickedMediaFile?> pick() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: VerificationLimits.proofExtensions);
    if (file == null) return null;
    final size = file.lengthSync() ?? await file.length();
    var path = file.path;
    // Storage Access Framework results may only expose a content:// URI; the upload needs a local file, so copy it.
    // A file over the limit is refused by the caller without being read.
    if (path == null && (size ?? 0) <= VerificationLimits.proofMaxBytes) {
      final dir = await getTemporaryDirectory();
      final copy = File('${dir.path}${Platform.pathSeparator}${_safeName(file.name)}');
      await copy.writeAsBytes(await file.readAsBytes(), flush: true);
      path = copy.path;
    }
    return PickedMediaFile(path: path ?? '', name: file.name, sizeBytes: size);
  }

  /// Keeps letters (any script), digits, spaces, `.`, `-`, `_`.
  static String _safeName(String name) {
    final safe = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
    return safe.isEmpty ? 'proof' : safe;
  }
}
