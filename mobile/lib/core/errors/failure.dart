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

  // Article PDF (F33): `GET /articles/{id}/pdf`.
  static const articlePdfHidden = 'article.pdf_hidden';
  static const articlePdfBusy = 'article.pdf_busy';
  static const articlePdfFailed = 'article.pdf_failed';
  static const articlePdfLimit = 'article.pdf_limit';

  // Reading & streaks (ADR 0013): a parallel progress report; the reader sends it again.
  static const readingConflict = 'reading.conflict';

  // Profile (F14 contract)
  static const profileStatsPrivate = 'profile.stats_private';
  static const profileAvatarInvalid = 'profile.avatar_invalid';
  static const profileExpertiseInvalid = 'profile.expertise_invalid';
  static const validationUrl = 'validation.url';

  // Title and social links (F14, pre-production step): validation codes under `headline` and `links[i].*`.
  static const profileHeadlineTooLong = 'profile.headline_too_long';
  static const profileHeadlineInvalid = 'profile.headline_invalid';
  static const linkTooMany = 'link.too_many';
  static const linkPlatformInvalid = 'link.platform_invalid';
  static const linkDuplicatePlatform = 'link.duplicate_platform';
  static const linkTooLong = 'link.too_long';
  static const linkHttpsRequired = 'link.https_required';
  static const linkUrlInvalid = 'link.url_invalid';
  static const linkHostMismatch = 'link.host_mismatch';
  static const linkLabelRequired = 'link.label_required';
  static const linkLabelInvalid = 'link.label_invalid';
  static const linkLabelNotAllowed = 'link.label_not_allowed';

  // Reactions, saved and follow (wave 1 contract: F10, F12, F13)
  static const reactionInvalid = 'reaction.invalid';
  static const collectionNameTaken = 'collection.name_taken';
  static const collectionLimit = 'collection.limit';
  static const collectionNotFound = 'collection.not_found';
  static const followSelf = 'follow.self';

  // Mute & feedback (F28)
  static const muteSelf = 'mute.self';
  static const muteSystemAccount = 'mute.system_account';
  static const muteLimit = 'mute.limit';
  static const muteOwnArticle = 'mute.own_article';

  // Repost (F29)
  static const repostOwnArticle = 'repost.own_article';
  static const repostCaptionTooLong = 'repost.caption_too_long'; // validation code under `caption`

  // Highlights (F30)
  static const highlightTextMismatch = 'highlight.text_mismatch';
  static const highlightBlockNotAllowed = 'highlight.block_not_allowed';
  static const highlightTooShort = 'highlight.too_short';
  static const highlightTooLong = 'highlight.too_long';
  static const highlightLimit = 'highlight.limit';
  static const highlightNotFound = 'highlight.not_found';

  // Quote card (F24)
  static const quoteTextMismatch = 'quote.text_mismatch';
  static const quoteBlockNotAllowed = 'quote.block_not_allowed';
  static const quoteTooShort = 'quote.too_short';
  static const quoteTooLong = 'quote.too_long';
  static const quoteHidden = 'quote.hidden';
  static const quoteLimit = 'quote.limit';
  static const quoteBusy = 'quote.busy';
  static const quoteFailed = 'quote.failed';

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

  // Writer categories (F31): `category.name_invalid` is a validation code (in `errors.name`), `category.limit` also
  // one (in `errors.categoryIds`).
  static const categoryNotFound = 'category.not_found';
  static const categoryNotOwner = 'category.not_owner';
  static const categoryLimit = 'category.limit';
  static const categoryNameTaken = 'category.name_taken';
  static const categoryNameInvalid = 'category.name_invalid';

  // The private corner's du'as (F38).
  static const duaNotFound = 'dua.not_found';
  static const duaLimit = 'dua.limit';

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
  // Removing a badge (`DELETE /admin/users/{id}/verification`, `verification.manage`): the user has none.
  static const verificationNotVerified = 'verification.not_verified';
  // ... or the official @readin account, whose badge stays.
  static const verificationSystemAccount = 'verification.system_account';

  // Admin console (F23): the verification queue (F19, `verification.manage`).
  static const verificationAlreadyDecided = 'verification.already_decided';
  static const verificationProofNotFound = 'verification.proof_not_found';

  // Help & support (F35). `support.category_invalid` is a validation code (in `errors.category`).
  static const supportLimit = 'support.limit';
  static const supportTicketNotFound = 'support.ticket_not_found';
  static const supportAttachmentNotFound = 'support.attachment_not_found';
  static const supportTicketClosed = 'support.ticket_closed';
  static const supportReopenExpired = 'support.reopen_expired';
  static const supportAttachmentInvalid = 'support.attachment_invalid';
  static const supportTooManyAttachments = 'support.too_many_attachments';
  static const supportCategoryInvalid = 'support.category_invalid';

  // Block (F36), terms and the content filter (F37), report additions (F22 store requirements).
  static const blockSelf = 'block.self';
  static const blockLimit = 'block.limit';

  /// To the blocker only, with the person ([BlockedFailure]); the blocked person gets `404`s, as if it were deleted.
  static const blockBlocked = 'block.blocked';
  static const repostNotFound = 'repost.not_found';
  static const authTermsRequired = 'auth.terms_required';

  /// A word of the content filter's block list, in the field [ObjectionableContentFailure.field] names.
  static const contentObjectionable = 'content.objectionable';

  /// 5 new articles in 24 hours or 60 comments an hour ([ContentLimitFailure]).
  static const contentTooMany = 'content.too_many';

  // Client-side
  static const requestCancelled = 'request.cancelled';
  static const networkOffline = 'network.offline';
  static const networkTimeout = 'network.timeout';

  /// The Google / Apple sheet failed for a reason other than the person closing it.
  static const authExternalProviderFailed = 'auth.external_provider_failed';

  /// Deleting needs a fresh Apple sign in, which this device can't show (Android): the iPhone app, or email.
  static const authAppleUnavailable = 'auth.apple_unavailable';
}

/// `403 block.blocked` (F36): the viewer blocked this person, whose article, comment or profile they opened. The
/// screen shows "isn't available" with «إلغاء الحظر» / "Unblock" for [blockedUserId].
class BlockedFailure extends Failure {
  const BlockedFailure({
    required this.blockedUserId,
    required this.blockedUsername,
    this.blockedDisplayName = '',
    super.message,
  }) : super(FailureCodes.blockBlocked, statusCode: 403);

  final String blockedUserId;
  final String blockedUsername;
  final String blockedDisplayName;

  @override
  List<Object?> get props => [...super.props, blockedUserId, blockedUsername, blockedDisplayName];
}

/// `422 content.objectionable` (F37): the text in [field] (e.g. `displayName`, `body`, `caption`, `subject`, `title`,
/// `content`) breaks the Community Guidelines; for an article also its [language] and, in the text, the [blockId].
/// The matched words are never sent. [fieldErrors] holds `{field: [content.objectionable]}`, so forms show it on
/// that input.
class ObjectionableContentFailure extends Failure {
  ObjectionableContentFailure({required this.field, this.language, this.blockId, super.message})
      : super(
          FailureCodes.contentObjectionable,
          statusCode: 422,
          fieldErrors: {
            if (field.isNotEmpty) field: const [FailureCodes.contentObjectionable],
          },
        );

  final String field;
  final String? language;
  final String? blockId;

  @override
  List<Object?> get props => [...super.props, field, language, blockId];
}

/// Which spam limit of the content filter was reached (F37).
enum ContentLimitKind {
  articlesPerDay('articles_per_day'),
  commentsPerHour('comments_per_hour');

  const ContentLimitKind(this.wire);

  final String wire;

  static ContentLimitKind? fromWire(Object? wire) => values.where((kind) => kind.wire == wire).firstOrNull;
}

/// `429 content.too_many` (F37): 5 new articles in 24 hours, or 60 comments and replies an hour ([limit]).
class ContentLimitFailure extends Failure {
  const ContentLimitFailure({this.limit, super.message}) : super(FailureCodes.contentTooMany, statusCode: 429);

  final ContentLimitKind? limit;

  @override
  List<Object?> get props => [...super.props, limit];
}
