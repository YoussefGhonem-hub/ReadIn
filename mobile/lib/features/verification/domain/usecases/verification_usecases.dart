import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../media/domain/entities/media.dart';
import '../entities/verification.dart';
import '../repositories/verification_repository.dart';

/// Whether I'm verified, whether I may request it now, and my latest request (F19).
@injectable
class GetVerificationStatus {
  const GetVerificationStatus(this._repository);

  final VerificationRepository _repository;

  Future<Result<VerificationStatus>> call() => _repository.getStatus();
}

/// Sends a verification request. One without any proof, or with a file that isn't an accepted proof, is refused here
/// with the API's code, without a request.
@injectable
class SubmitVerificationRequest {
  const SubmitVerificationRequest(this._repository);

  final VerificationRepository _repository;

  static const proofRequired = Failure(FailureCodes.verificationProofRequired, statusCode: 400);
  static const proofInvalid = Failure(FailureCodes.verificationProofInvalid, statusCode: 400);

  Future<Result<VerificationRequest>> call(VerificationSubmission submission) async {
    final proof = submission.proof;
    if ((submission.proofUrl ?? '').isEmpty && proof == null) return const Err(proofRequired);
    if (proof != null && !isAcceptedProof(proof)) return const Err(proofInvalid);
    return _repository.submit(submission);
  }
}

/// Withdraws my pending request (its file is deleted with it).
@injectable
class WithdrawVerificationRequest {
  const WithdrawVerificationRequest(this._repository);

  final VerificationRepository _repository;

  Future<Result<void>> call() => _repository.withdraw();
}

/// Picks a proof file. Null when the user cancels; `verification.proof_invalid` for a file that isn't a PDF, JPEG, PNG
/// or WebP of at most 10 MB, before anything is sent.
@injectable
class PickVerificationProof {
  const PickVerificationProof(this._picker);

  final ProofFilePicker _picker;

  Future<Result<PickedMediaFile?>> call() async {
    final file = await _picker.pick();
    if (file == null) return const Ok(null);
    return isAcceptedProof(file) ? Ok(file) : const Err(SubmitVerificationRequest.proofInvalid);
  }
}
