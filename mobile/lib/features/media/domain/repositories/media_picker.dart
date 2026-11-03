import '../entities/media.dart';

/// Device pickers: the photo library (multi-select) and the document picker.
abstract interface class MediaPicker {
  /// Up to [limit] images; empty when the user cancels.
  Future<List<PickedMediaFile>> pickImages({required int limit});

  /// One PDF, or null when the user cancels.
  Future<PickedMediaFile?> pickPdf();
}
