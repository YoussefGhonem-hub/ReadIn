import 'package:equatable/equatable.dart';

import '../../../verification/domain/entities/verification.dart';

/// The requester of a verification request, as the queue shows them.
class AdminVerificationUser extends Equatable {
  const AdminVerificationUser({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
    this.headline,
  });

  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;

  /// Has the badge now: an approved request then offers "Remove badge".
  final bool isVerified;
  final String? headline;

  @override
  List<Object?> get props => [id, displayName, username, avatarUrl, isVerified, headline];
}

/// The uploaded proof file while the request is pending (deleted once decided).
class VerificationProofFile extends Equatable {
  const VerificationProofFile({required this.fileName, required this.contentType, this.sizeBytes = 0});

  final String fileName;
  final String contentType;
  final int sizeBytes;

  @override
  List<Object?> get props => [fileName, contentType, sizeBytes];
}

/// A writer verification request in the console (`AdminVerificationRequestDto`, F19).
class AdminVerificationRequest extends Equatable {
  const AdminVerificationRequest({
    required this.id,
    required this.status,
    required this.user,
    required this.field,
    required this.jobTitle,
    required this.submittedAt,
    this.proofUrl,
    this.proof,
    this.note,
    this.decidedAt,
    this.decidedBy,
    this.rejectionReason,
  });

  final String id;
  final VerificationRequestStatus status;
  final AdminVerificationUser user;
  final VerificationField field;
  final String jobTitle;
  final String? proofUrl;
  final VerificationProofFile? proof;
  final String? note;
  final DateTime submittedAt;
  final DateTime? decidedAt;

  /// `@username` of who decided; null while pending or once that account is gone.
  final String? decidedBy;
  final String? rejectionReason;

  bool get isPending => status == VerificationRequestStatus.pending;

  @override
  List<Object?> get props =>
      [id, status, user, field, jobTitle, proofUrl, proof, note, submittedAt, decidedAt, decidedBy, rejectionReason];
}

/// The reason a request is rejected: 5–500 characters, shown only on the requester's verification page.
abstract final class VerificationReviewLimits {
  static const reasonMin = 5;
  static const reasonMax = 500;
}
