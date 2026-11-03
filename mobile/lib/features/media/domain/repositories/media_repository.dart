import '../../../../core/errors/result.dart';
import '../../../../core/models/transfer.dart';
import '../entities/media.dart';

abstract interface class MediaRepository {
  /// Compresses on the device (max 2048 px, JPEG q85, upright, no EXIF) and
  /// uploads with `POST /uploads/images`. Falls back to the original file when
  /// compression fails — the server re-processes everything anyway. [purpose] is `image`, `avatar` or `cover`.
  Future<Result<MediaAsset>> uploadImage(
    PickedMediaFile file, {
    String purpose = 'image',
    TransferToken? token,
    TransferProgress? onProgress,
  });

  /// `POST /uploads/documents` → `202` with `status: processing`.
  Future<Result<MediaAsset>> uploadDocument(
    PickedMediaFile file, {
    required String title,
    required bool allowDownload,
    TransferToken? token,
    TransferProgress? onProgress,
  });

  /// `GET /uploads/{id}` (owner only), polled while processing.
  Future<Result<MediaAsset>> getUpload(String id);

  /// `DELETE /uploads/{id}`.
  Future<Result<void>> deleteUpload(String id);

  /// Downloads the original document (with auth headers) to a temp file and
  /// returns its path.
  Future<Result<String>> downloadDocument(
    String url, {
    required String fileName,
    TransferToken? token,
    TransferProgress? onProgress,
  });
}
