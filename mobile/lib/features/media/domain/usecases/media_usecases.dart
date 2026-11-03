import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/transfer.dart';
import '../entities/media.dart';
import '../repositories/media_picker.dart';
import '../repositories/media_repository.dart';

@injectable
class PickImages {
  const PickImages(this._picker);

  final MediaPicker _picker;

  Future<List<PickedMediaFile>> call({required int limit}) => _picker.pickImages(limit: limit);
}

@injectable
class PickPdf {
  const PickPdf(this._picker);

  final MediaPicker _picker;

  Future<PickedMediaFile?> call() => _picker.pickPdf();
}

@injectable
class UploadImage {
  const UploadImage(this._repository);

  final MediaRepository _repository;

  Future<Result<MediaAsset>> call(
    PickedMediaFile file, {
    String purpose = 'image',
    TransferToken? token,
    TransferProgress? onProgress,
  }) =>
      _repository.uploadImage(file, purpose: purpose, token: token, onProgress: onProgress);
}

@injectable
class UploadDocument {
  const UploadDocument(this._repository);

  final MediaRepository _repository;

  Future<Result<MediaAsset>> call(
    PickedMediaFile file, {
    required String title,
    required bool allowDownload,
    TransferToken? token,
    TransferProgress? onProgress,
  }) =>
      _repository.uploadDocument(file, title: title, allowDownload: allowDownload, token: token, onProgress: onProgress);
}

@injectable
class GetUpload {
  const GetUpload(this._repository);

  final MediaRepository _repository;

  Future<Result<MediaAsset>> call(String id) => _repository.getUpload(id);
}

@injectable
class DeleteUpload {
  const DeleteUpload(this._repository);

  final MediaRepository _repository;

  Future<Result<void>> call(String id) => _repository.deleteUpload(id);
}

@injectable
class DownloadDocument {
  const DownloadDocument(this._repository);

  final MediaRepository _repository;

  Future<Result<String>> call(String url, {required String fileName, TransferToken? token, TransferProgress? onProgress}) =>
      _repository.downloadDocument(url, fileName: fileName, token: token, onProgress: onProgress);
}
