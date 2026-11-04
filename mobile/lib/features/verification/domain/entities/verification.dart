import 'package:equatable/equatable.dart';

import '../../../media/domain/entities/media.dart';

/// Writer verification rules (SPEC F19, the API's `VerificationRequest`). The server checks everything again; a proof
/// file is checked there by its bytes.
abstract final class VerificationLimits {
  static const jobTitleMin = 2;
  static const jobTitleMax = 100;
  static const proofUrlMax = 500;
  static const noteMax = 500;
  static const proofMaxBytes = 10 * 1024 * 1024;

  /// The file types a proof may be (PDF, JPEG, PNG, WebP), by extension.
  static const proofExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];
}

/// `MyVerificationRequestDto.status`. [unknown] is a status this app version doesn't know.
enum VerificationRequestStatus {
  pending,
  approved,
  rejected,
  unknown;

  static VerificationRequestStatus fromWire(String? wire) =>
      values.where((status) => status != unknown && status.name == wire).firstOrNull ?? unknown;
}

/// `MyVerificationRequestDto.field`: its name is in the UI language (`Accept-Language`).
class VerificationField extends Equatable {
  const VerificationField({required this.id, required this.slug, required this.name});

  final String id;
  final String slug;
  final String name;

  @override
  List<Object?> get props => [id, slug, name];
}

/// My latest verification request (`MyVerificationRequestDto`, F19).
class VerificationRequest extends Equatable {
  const VerificationRequest({
    required this.id,
    required this.status,
    required this.field,
    required this.jobTitle,
    required this.submittedAt,
    this.proofUrl,
    this.proofFileName,
    this.note,
    this.decidedAt,
    this.rejectionReason,
  });

  final String id;
  final VerificationRequestStatus status;
  final VerificationField field;
  final String jobTitle;
  final String? proofUrl;

  /// The uploaded proof's display name; null without a file, and once the request is decided (the file is deleted).
  final String? proofFileName;
  final String? note;
  final DateTime submittedAt;
  final DateTime? decidedAt;

  /// Why it was rejected; shown only on the verification page, never in a push.
  final String? rejectionReason;

  bool get isPending => status == VerificationRequestStatus.pending;
  bool get isRejected => status == VerificationRequestStatus.rejected;

  @override
  List<Object?> get props =>
      [id, status, field, jobTitle, proofUrl, proofFileName, note, submittedAt, decidedAt, rejectionReason];
}

/// `GET /me/verification` (`VerificationStatusDto`): whether I'm verified, whether I may send a request now (signed
/// in, not verified, not suspended, nothing pending) and my latest request.
class VerificationStatus extends Equatable {
  const VerificationStatus({this.isVerified = false, this.canRequest = false, this.request});

  /// Nothing requested yet.
  static const none = VerificationStatus(canRequest: true);

  final bool isVerified;
  final bool canRequest;
  final VerificationRequest? request;

  VerificationRequest? get pending => (request?.isPending ?? false) ? request : null;

  @override
  List<Object?> get props => [isVerified, canRequest, request];
}

/// A new request (`POST /verification-requests`): at least one of [proofUrl] and [proof].
class VerificationSubmission extends Equatable {
  const VerificationSubmission({required this.fieldId, required this.jobTitle, this.proofUrl, this.note, this.proof});

  final String fieldId;
  final String jobTitle;
  final String? proofUrl;
  final String? note;

  /// A PDF, JPEG, PNG or WebP file of at most [VerificationLimits.proofMaxBytes].
  final PickedMediaFile? proof;

  @override
  List<Object?> get props => [fieldId, jobTitle, proofUrl, note, proof];
}

/// The lower-cased extension of [fileName] (`CV.PDF` → `pdf`), or empty.
String fileExtensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot < 0 || dot == fileName.length - 1 ? '' : fileName.substring(dot + 1).toLowerCase();
}

/// Whether [file] may be sent as a proof: an allowed type by its extension, and not larger than the limit (an unknown
/// size is left to the server).
bool isAcceptedProof(PickedMediaFile file) =>
    VerificationLimits.proofExtensions.contains(fileExtensionOf(file.name)) &&
    (file.sizeBytes ?? 0) <= VerificationLimits.proofMaxBytes;
