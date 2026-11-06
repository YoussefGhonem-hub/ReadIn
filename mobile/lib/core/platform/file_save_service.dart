import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

/// The system "Save as" dialog (`file_picker`), behind a small seam so cubits stay unit-testable: on Android the
/// Storage Access Framework (the person picks a folder, e.g. Pictures or Downloads; no storage permission), on iOS the
/// Files picker. Used by the F24 quote card's **Save**.
@lazySingleton
class FileSaveService {
  /// Writes [bytes] where the person chooses, suggesting [fileName]. True once saved, false when they cancel. Throws
  /// when the dialog can't open or the file can't be written.
  Future<bool> save(Uint8List bytes, {required String fileName, required String mimeType}) async =>
      await FilePicker.saveFile(fileName: fileName, bytes: bytes, mimeType: mimeType) != null;
}
