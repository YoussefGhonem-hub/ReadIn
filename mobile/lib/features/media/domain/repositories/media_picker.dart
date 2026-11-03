import '../entities/media.dart';

/// Device pickers: the photo library (multi-select), the camera and the document picker.
abstract interface class MediaPicker {
  /// Up to [limit] images; empty when the user cancels.
  Future<List<PickedMediaFile>> pickImages({required int limit});

  /// One photo from the camera, or null when the user cancels.
  Future<PickedMediaFile?> takePhoto();

  /// One PDF, or null when the user cancels.
  Future<PickedMediaFile?> pickPdf();
}
