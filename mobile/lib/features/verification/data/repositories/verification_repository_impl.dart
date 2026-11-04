import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/verification.dart';
import '../../domain/repositories/verification_repository.dart';
import '../datasources/verification_api.dart';

@LazySingleton(as: VerificationRepository)
class VerificationRepositoryImpl implements VerificationRepository {
  VerificationRepositoryImpl(this._api);

  final VerificationApi _api;

  @override
  Future<Result<VerificationStatus>> getStatus() => guardApi(() async => (await _api.status()).toEntity());

  @override
  Future<Result<VerificationRequest>> submit(VerificationSubmission submission) async {
    try {
      return await guardApi(() async {
        final file = submission.proof;
        final proof = file == null
            ? null
            : await MultipartFile.fromFile(file.path, filename: file.name, contentType: proofMediaType(file.name));
        final model = await _api.submit(
          submission.fieldId,
          submission.jobTitle,
          proofUrl: submission.proofUrl,
          note: submission.note,
          proof: proof,
        );
        return model.toEntity();
      });
    } on FileSystemException catch (e) {
      // The picked file is gone or can't be read: it has to be picked again.
      return Err(Failure(FailureCodes.verificationProofInvalid, message: e.message));
    }
  }

  @override
  Future<Result<void>> withdraw() => guardApi(_api.withdraw);

  /// The proof's content type by its extension; the server decides by the file's bytes.
  static DioMediaType proofMediaType(String fileName) => switch (fileExtensionOf(fileName)) {
        'pdf' => DioMediaType('application', 'pdf'),
        'png' => DioMediaType('image', 'png'),
        'webp' => DioMediaType('image', 'webp'),
        'jpg' || 'jpeg' => DioMediaType('image', 'jpeg'),
        _ => DioMediaType('application', 'octet-stream'),
      };
}
