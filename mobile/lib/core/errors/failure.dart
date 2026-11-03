import 'package:equatable/equatable.dart';

/// A typed, translatable error. [code] is the stable API/client error code
/// (e.g. `article.not_found`, `network.offline`) that the UI maps to ar/en text
/// via `localizeFailure` — never show raw server messages to users.
class Failure extends Equatable {
  const Failure(this.code, {this.statusCode, this.message, this.fieldErrors = const {}});

  /// Stable error code (see docs/api/contract-v1.md).
  final String code;
  final int? statusCode;

  /// Developer-facing detail (server `title`/`detail`), used only as a fallback.
  final String? message;

  /// Validation errors: field name → list of error codes.
  final Map<String, List<String>> fieldErrors;

  static const unknown = Failure(FailureCodes.serverError);

  @override
  List<Object?> get props => [code, statusCode, message, fieldErrors];

  @override
  String toString() => 'Failure($code, status: $statusCode, message: $message)';
}

/// Error codes shared with the API contract, plus client-only codes.
abstract final class FailureCodes {
  // API (docs/api/contract-v1.md)
  static const validationFailed = 'validation.failed';
  static const authUnauthorized = 'auth.unauthorized';
  static const authForbidden = 'auth.forbidden';
  static const userSuspended = 'user.suspended';
  static const userNotSynced = 'user.not_synced';
  static const userNotFound = 'user.not_found';
  static const usernameTaken = 'user.username_taken';
  static const usernameInvalid = 'user.username_invalid';
  static const interestsMinThree = 'user.interests.min_three';
  static const fieldNotFound = 'field.not_found';
  static const articleNotFound = 'article.not_found';
  static const articleSourcesRequired = 'article.sources_required';
  static const rateLimited = 'rate_limited';
  static const serverError = 'server.error';
  static const validationRequired = 'validation.required';
  static const validationMinLength = 'validation.min_length';
  static const validationMaxLength = 'validation.max_length';

  // Auth (SPEC §9, ADR 0007, ADR 0009)
  static const authInvalidCredentials = 'auth.invalid_credentials';
  static const authLockedOut = 'auth.locked_out';
  static const authPhoneTaken = 'auth.phone_taken';
  static const authPhoneUnchanged = 'auth.phone_unchanged';
  static const authRefreshInvalid = 'auth.refresh_invalid';
  static const authRecoveryInvalid = 'auth.recovery_invalid';
  static const authRecoveryLocked = 'auth.recovery_locked';
  static const authRecoveryDisabled = 'auth.recovery_disabled';
  static const authResetTokenInvalid = 'auth.reset_token_invalid';
  static const authWrongPassword = 'auth.wrong_password';
  static const authPinAlreadySet = 'auth.pin_already_set';

  // Media (docs/api/contract-v1.md "Media", ADR 0011)
  static const mediaPurposeInvalid = 'media.purpose_invalid';
  static const mediaFileRequired = 'media.file_required';
  static const mediaTooLarge = 'media.too_large';
  static const mediaUnsupportedType = 'media.unsupported_type';
  static const mediaDimensionsTooLarge = 'media.dimensions_too_large';
  static const mediaImageCorrupted = 'media.image_corrupted';
  static const mediaPdfEncrypted = 'media.pdf_encrypted';
  static const mediaPdfCorrupted = 'media.pdf_corrupted';
  static const mediaPdfTooManyPages = 'media.pdf_too_many_pages';
  static const mediaQuotaDaily = 'media.quota_daily';
  static const mediaQuotaStorage = 'media.quota_storage';
  static const mediaNotFound = 'media.not_found';
  static const mediaInUse = 'media.in_use';
  static const mediaDownloadNotAllowed = 'media.download_not_allowed';
  static const mediaProcessingFailed = 'media.processing_failed';
  static const mediaProcessingTimeout = 'media.processing_timeout';
  static const attachmentsMixedKinds = 'attachments.mixed_kinds';
  static const attachmentsTooManyImages = 'attachments.too_many_images';
  static const attachmentsSingleDocument = 'attachments.single_document';
  static const attachmentsAltTextRequired = 'attachments.alt_text_required';
  static const attachmentsAltTextTooLong = 'attachments.alt_text_too_long';
  static const attachmentsCaptionTooLong = 'attachments.caption_too_long';
  static const attachmentsTitleRequired = 'attachments.title_required';
  static const attachmentsTitleTooLong = 'attachments.title_too_long';
  static const attachmentsAssetNotFound = 'attachments.asset_not_found';
  static const attachmentsAssetNotReady = 'attachments.asset_not_ready';
  static const attachmentsDuplicateAsset = 'attachments.duplicate_asset';

  // Client-side
  static const requestCancelled = 'request.cancelled';
  static const networkOffline = 'network.offline';
  static const networkTimeout = 'network.timeout';
}
