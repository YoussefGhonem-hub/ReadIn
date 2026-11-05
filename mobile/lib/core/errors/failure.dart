import 'package:equatable/equatable.dart';

/// A typed, translatable error. [code] is the stable API/client error code
/// (e.g. `article.not_found`, `network.offline`) that the UI maps to ar/en text
/// via `localizeFailure` — never show raw server messages to users.
class Failure extends Equatable {
  const Failure(this.code, {this.statusCode, this.message, this.fieldErrors = const {}, this.suspendedUntil});

  /// Stable error code (see docs/api/contract-v1.md).
  final String code;
  final int? statusCode;

  /// Developer-facing detail (server `title`/`detail`), used only as a fallback.
  final String? message;

  /// Validation errors: field name → list of error codes.
  final Map<String, List<String>> fieldErrors;

  /// `user.suspended` only (F22): when the suspension ends; null = permanent.
  final DateTime? suspendedUntil;

  static const unknown = Failure(FailureCodes.serverError);

  @override
  List<Object?> get props => [code, statusCode, message, fieldErrors, suspendedUntil];

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
  static const interestsUnknown = 'user.interests.unknown';
  static const fieldNotFound = 'field.not_found';
  static const topicNotFound = 'topic.not_found';
  static const topicNotInField = 'topic.not_in_field';
  static const articleNotFound = 'article.not_found';
  static const articleSourcesRequired = 'article.sources_required';
  static const concurrencyConflict = 'concurrency.conflict';
  static const requestInvalid = 'request.invalid';
  static const requestTooLarge = 'request.too_large';
  static const requestUnsupportedMediaType = 'request.unsupported_media_type';
  static const routeNotFound = 'route.not_found';

  // Article editor (F05 contract): conflicts, and the publish checks (DraftProblemCode).
  static const articleDraftConflict = 'article.draft_conflict';
  static const articleNotPublished = 'article.not_published';
  static const articleRevisionNotFound = 'article.revision_not_found';
  static const articleNotOwner = 'article.not_owner';
  static const articleStatusInvalid = 'article.status_invalid';
  static const articleNoContent = 'article.no_content';
  static const articleInvalidTransition = 'article.invalid_transition';
  static const articleSlugTaken = 'article.slug_taken';

  /// Replaced by [articleTooManyTags] in F32; still translated.
  static const articleTagsMaxFive = 'article.tags.max_five';
  static const articleLanguageInvalid = 'article.language_invalid';
  static const articleContentLanguageMismatch = 'article.content_language_mismatch';
  static const articleFieldRequired = 'article.field_required';
  static const articleTitleLength = 'article.title_length';
  static const articleContentEmpty = 'article.content_empty';
  static const articleContentInvalid = 'article.content_invalid';
  static const articleImageAltRequired = 'article.image_alt_required';
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

  // Google / Apple sign in (ADR 0012)
  static const authExternalNotLinked = 'auth.external_not_linked';
  static const authExternalInvalid = 'auth.external_invalid';
  static const authProviderDisabled = 'auth.provider_disabled';
  static const authExternalConflict = 'auth.external_conflict';
  static const authExternalInUse = 'auth.external_in_use';
  static const authExternalMismatch = 'auth.external_mismatch';
  static const authExternalLoginNotFound = 'auth.external_login_not_found';
  static const authConfirmationRequired = 'auth.confirmation_required';
  static const authLastSignInMethod = 'auth.last_sign_in_method';
  static const authPhoneSignInExists = 'auth.phone_sign_in_exists';
  static const providerInvalid = 'provider.invalid';

  // Delete account (`DELETE /me`)
  /// The account is linked to Apple and the server has no Apple token to revoke: confirm with Apple.
  static const authAppleConfirmationRequired = 'auth.apple_confirmation_required';

  /// `503`: Apple couldn't be reached, so nothing was deleted.
  static const accountDeletionUnavailable = 'account.deletion_unavailable';

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

  // Reading & streaks (ADR 0013): a parallel progress report; the reader sends it again.
  static const readingConflict = 'reading.conflict';

  // Profile (F14 contract)
  static const profileStatsPrivate = 'profile.stats_private';
  static const profileAvatarInvalid = 'profile.avatar_invalid';
  static const profileExpertiseInvalid = 'profile.expertise_invalid';
  static const validationUrl = 'validation.url';

  // Reactions, saved and follow (wave 1 contract: F10, F12, F13)
  static const reactionInvalid = 'reaction.invalid';
  static const collectionNameTaken = 'collection.name_taken';
  static const collectionLimit = 'collection.limit';
  static const collectionNotFound = 'collection.not_found';
  static const followSelf = 'follow.self';

  // Comments (F11)
  static const commentNotFound = 'comment.not_found';
  static const commentNotOwner = 'comment.not_owner';
  static const commentNotAvailable = 'comment.not_available';
  static const commentPinReply = 'comment.pin_reply';
  static const commentPinNotAuthor = 'comment.pin_not_author';
  static const commentPinConflict = 'comment.pin_conflict';
  static const commentArticleLimit = 'comment.article_limit';
  static const commentDuplicate = 'comment.duplicate';
  static const commentEmpty = 'comment.empty';
  static const commentTooLong = 'comment.too_long';

  // Reports and moderation (F22)
  static const reportOwnContent = 'report.own_content';
  static const reportReasonInvalid = 'report.reason_invalid';
  static const reportTargetInvalid = 'report.target_invalid';
  static const reportTargetNotFound = 'report.target_not_found';
  static const reportStatusInvalid = 'report.status_invalid';
  static const moderationActionInvalid = 'moderation.action_invalid';
  static const moderationSelf = 'moderation.self';
  static const moderationStaffTarget = 'moderation.staff_target';
  static const moderationNoteRequired = 'moderation.note_required';
  static const moderationDurationInvalid = 'moderation.duration_invalid';
  static const moderationNoticeNotFound = 'moderation.notice_not_found';

  // Tags (F32): `tag.invalid` and `article.too_many_tags` are validation codes (in `errors`), `tag.hidden` and
  // `tag.limit` publish problems (in `checks.problems`).
  static const tagNotFound = 'tag.not_found';
  static const tagInvalid = 'tag.invalid';
  static const tagHidden = 'tag.hidden';
  static const tagLimit = 'tag.limit';
  static const articleTooManyTags = 'article.too_many_tags';

  // Search (F16): the app checks the query and the filters first, so these are rare.
  static const searchQueryInvalid = 'search.query_invalid';
  static const searchTypeInvalid = 'search.type_invalid';
  static const searchFilterInvalid = 'search.filter_invalid';

  // Glossary (F21)
  static const glossaryTermNotFound = 'glossary.term_not_found';
  // Learning paths (F09); the last three come from the admin endpoints only.
  static const pathNotFound = 'path.not_found';
  static const pathSlugTaken = 'path.slug_taken';
  static const pathEditorial = 'path.editorial';
  static const pathItemsInvalid = 'path.items_invalid';

  // Notifications (F17)
  static const notificationNotFound = 'notification.not_found';
  static const notificationTypeInvalid = 'notification.type_invalid';
  static const notificationModeInvalid = 'notification.mode_invalid';
  static const notificationQuietHoursInvalid = 'notification.quiet_hours_invalid';

  // Writer verification (F19), the requester's side
  static const verificationProofRequired = 'verification.proof_required';
  static const verificationProofInvalid = 'verification.proof_invalid';
  static const verificationFieldInvalid = 'verification.field_invalid';
  static const verificationAlreadyPending = 'verification.already_pending';
  static const verificationAlreadyVerified = 'verification.already_verified';
  static const verificationNotFound = 'verification.not_found';

  // Client-side
  static const requestCancelled = 'request.cancelled';
  static const networkOffline = 'network.offline';
  static const networkTimeout = 'network.timeout';

  /// The Google / Apple sheet failed for a reason other than the person closing it.
  static const authExternalProviderFailed = 'auth.external_provider_failed';

  /// Deleting needs a fresh Apple sign in, which this device can't show (Android): the iPhone app, or email.
  static const authAppleUnavailable = 'auth.apple_unavailable';
}
