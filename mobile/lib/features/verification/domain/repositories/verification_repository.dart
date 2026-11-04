import '../../../../core/errors/result.dart';
import '../../../media/domain/entities/media.dart';
import '../entities/verification.dart';

/// Writer verification, the requester's side (F19). Every call needs a signed-in user; reviewing is web-only.
abstract interface class VerificationRepository {
  /// `GET /me/verification`.
  Future<Result<VerificationStatus>> getStatus();

  /// `POST /verification-requests` (multipart) → `201` with the new pending request. `400 verification.proof_required`,
  /// `verification.field_invalid`, `verification.proof_invalid`, validation errors; `409 verification.already_pending`,
  /// `verification.already_verified`; `403 user.suspended`.
  Future<Result<VerificationRequest>> submit(VerificationSubmission submission);

  /// `DELETE /me/verification`: withdraws the pending request. `404 verification.not_found` when none is pending.
  Future<Result<void>> withdraw();
}

/// The document picker for a proof file: PDF, JPEG, PNG or WebP.
abstract interface class ProofFilePicker {
  /// One file, or null when the user cancels.
  Future<PickedMediaFile?> pick();
}
