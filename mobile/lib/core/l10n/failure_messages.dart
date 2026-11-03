import '../errors/failure.dart';
import '../security/credential_rules.dart';
import 'gen/app_localizations.dart';

/// Maps a [Failure.code] to a translated message. Unknown codes fall back to
/// the generic server error — raw server text is never shown to users.
String localizeFailure(AppLocalizations l10n, Failure failure) => localizeErrorCode(l10n, failure.code);

/// For actions without a form (react, save, follow, collections): a validation failure shows its first field error
/// (e.g. `reaction.invalid`) instead of "check the highlighted fields".
String localizeActionFailure(AppLocalizations l10n, Failure failure) {
  if (failure.code == FailureCodes.validationFailed) {
    final first = failure.fieldErrors.values.expand((codes) => codes).firstOrNull;
    if (first != null) {
      final message = localizeErrorCode(l10n, first);
      return message == l10n.errServer ? l10n.errInvalidValue : message;
    }
  }
  return localizeFailure(l10n, failure);
}

/// For comment actions (F11): like [localizeActionFailure], but the `429` of the comments rate limit (10 a minute)
/// says to slow down instead of the generic "too many requests".
String localizeCommentFailure(AppLocalizations l10n, Failure failure) =>
    failure.code == FailureCodes.rateLimited ? l10n.commentsErrRateLimited : localizeActionFailure(l10n, failure);

/// Same as [localizeFailure] for a bare error code, e.g. a media asset's
/// `failureReason` (`media.processing_timeout`).
String localizeErrorCode(AppLocalizations l10n, String code) => switch (code) {
      FailureCodes.validationFailed => l10n.errValidation,
      FailureCodes.authUnauthorized => l10n.errUnauthorized,
      FailureCodes.authForbidden => l10n.errForbidden,
      FailureCodes.userSuspended => l10n.errSuspended,
      FailureCodes.userNotSynced => l10n.errNotSynced,
      FailureCodes.userNotFound => l10n.errUserNotFound,
      FailureCodes.usernameTaken => l10n.errUsernameTaken,
      FailureCodes.usernameInvalid => l10n.errUsernameInvalid,
      FailureCodes.profileStatsPrivate => l10n.profileErrStatsPrivate,
      FailureCodes.profileAvatarInvalid => l10n.profileErrAvatarInvalid,
      FailureCodes.profileExpertiseInvalid => l10n.profileErrExpertiseInvalid,
      FailureCodes.validationUrl => l10n.profileErrUrl,
      FailureCodes.interestsMinThree => l10n.errInterestsMinThree,
      FailureCodes.fieldNotFound => l10n.errFieldNotFound,
      FailureCodes.articleNotFound => l10n.errArticleNotFound,
      FailureCodes.articleSourcesRequired => l10n.errSourcesRequired,
      FailureCodes.rateLimited => l10n.errTooManyRequests,
      FailureCodes.validationRequired || CredentialCodes.required => l10n.fieldRequired,
      FailureCodes.validationMinLength => l10n.errTooShort,
      FailureCodes.validationMaxLength => l10n.errTooLong,
      'validation.length' || 'validation.format' || 'validation.invalid' || 'validation.range' => l10n.errInvalidValue,
      FailureCodes.authInvalidCredentials => l10n.errInvalidCredentials,
      FailureCodes.authLockedOut => l10n.errLockedOut,
      FailureCodes.authPhoneTaken => l10n.errPhoneTaken,
      FailureCodes.authPhoneUnchanged => l10n.errPhoneUnchanged,
      FailureCodes.authRefreshInvalid => l10n.sessionExpired,
      FailureCodes.authRecoveryInvalid => l10n.errRecoveryInvalid,
      FailureCodes.authRecoveryLocked => l10n.errRecoveryLocked,
      FailureCodes.authRecoveryDisabled => l10n.errRecoveryDisabled,
      FailureCodes.authResetTokenInvalid => l10n.errResetTokenInvalid,
      FailureCodes.authWrongPassword => l10n.errWrongPassword,
      FailureCodes.authPinAlreadySet => l10n.errPinAlreadySet,
      FailureCodes.authExternalNotLinked => l10n.errExternalNotLinked,
      FailureCodes.authExternalInvalid => l10n.errExternalInvalid,
      FailureCodes.authProviderDisabled => l10n.errProviderDisabled,
      FailureCodes.authExternalConflict => l10n.errExternalConflict,
      FailureCodes.authExternalInUse => l10n.errExternalInUse,
      FailureCodes.authExternalMismatch => l10n.errExternalMismatch,
      FailureCodes.authExternalLoginNotFound => l10n.errExternalLoginNotFound,
      FailureCodes.authConfirmationRequired => l10n.errConfirmationRequired,
      FailureCodes.authLastSignInMethod => l10n.errLastSignInMethod,
      FailureCodes.authPhoneSignInExists => l10n.errPhoneSignInExists,
      FailureCodes.providerInvalid => l10n.errProviderInvalid,
      FailureCodes.authExternalProviderFailed => l10n.errExternalProviderFailed,
      CredentialCodes.phoneInvalid => l10n.errPhoneInvalid,
      CredentialCodes.passwordTooShort => l10n.errPasswordTooShort,
      CredentialCodes.passwordTooLong => l10n.errPasswordTooLong,
      CredentialCodes.passwordLetterRequired => l10n.errPasswordLetterRequired,
      CredentialCodes.passwordDigitRequired => l10n.errPasswordDigitRequired,
      CredentialCodes.passwordTooCommon => l10n.errPasswordTooCommon,
      CredentialCodes.passwordContainsPhone => l10n.errPasswordContainsPhone,
      CredentialCodes.passwordMismatch => l10n.errPasswordMismatch,
      CredentialCodes.pinLength => l10n.errPinLength,
      CredentialCodes.pinDigitsOnly => l10n.errPinDigitsOnly,
      CredentialCodes.pinWeak => l10n.errPinWeak,
      CredentialCodes.pinMismatch => l10n.errPinMismatch,
      FailureCodes.mediaPurposeInvalid => l10n.errMediaPurposeInvalid,
      FailureCodes.mediaFileRequired => l10n.errMediaFileRequired,
      FailureCodes.mediaTooLarge => l10n.errMediaTooLarge,
      FailureCodes.mediaUnsupportedType => l10n.errMediaUnsupportedType,
      FailureCodes.mediaDimensionsTooLarge => l10n.errMediaDimensionsTooLarge,
      FailureCodes.mediaImageCorrupted => l10n.errMediaImageCorrupted,
      FailureCodes.mediaPdfEncrypted => l10n.errMediaPdfEncrypted,
      FailureCodes.mediaPdfCorrupted => l10n.errMediaPdfCorrupted,
      FailureCodes.mediaPdfTooManyPages => l10n.errMediaPdfTooManyPages,
      FailureCodes.mediaQuotaDaily => l10n.errMediaQuotaDaily,
      FailureCodes.mediaQuotaStorage => l10n.errMediaQuotaStorage,
      FailureCodes.mediaNotFound => l10n.errMediaNotFound,
      FailureCodes.mediaInUse => l10n.errMediaInUse,
      FailureCodes.mediaDownloadNotAllowed => l10n.errMediaDownloadNotAllowed,
      FailureCodes.mediaProcessingFailed => l10n.errMediaProcessingFailed,
      FailureCodes.mediaProcessingTimeout => l10n.errMediaProcessingTimeout,
      FailureCodes.attachmentsMixedKinds => l10n.errAttachmentsMixedKinds,
      FailureCodes.attachmentsTooManyImages => l10n.errAttachmentsTooManyImages,
      FailureCodes.attachmentsSingleDocument => l10n.errAttachmentsSingleDocument,
      FailureCodes.attachmentsAltTextRequired => l10n.errAttachmentsAltTextRequired,
      FailureCodes.attachmentsAltTextTooLong => l10n.errAttachmentsAltTextTooLong,
      FailureCodes.attachmentsCaptionTooLong => l10n.errAttachmentsCaptionTooLong,
      FailureCodes.attachmentsTitleRequired => l10n.errAttachmentsTitleRequired,
      FailureCodes.attachmentsTitleTooLong => l10n.errAttachmentsTitleTooLong,
      FailureCodes.attachmentsAssetNotFound => l10n.errAttachmentsAssetNotFound,
      FailureCodes.attachmentsAssetNotReady => l10n.errAttachmentsAssetNotReady,
      FailureCodes.attachmentsDuplicateAsset => l10n.errAttachmentsDuplicateAsset,
      FailureCodes.reactionInvalid => l10n.errReactionInvalid,
      FailureCodes.collectionNameTaken => l10n.errCollectionNameTaken,
      FailureCodes.collectionLimit => l10n.errCollectionLimit,
      FailureCodes.collectionNotFound => l10n.errCollectionNotFound,
      FailureCodes.followSelf => l10n.errFollowSelf,
      FailureCodes.commentNotFound => l10n.commentsErrNotFound,
      FailureCodes.commentNotOwner => l10n.commentsErrNotOwner,
      FailureCodes.commentNotAvailable => l10n.commentsErrNotAvailable,
      FailureCodes.commentPinReply => l10n.commentsErrPinReply,
      FailureCodes.commentPinNotAuthor => l10n.commentsErrPinNotAuthor,
      FailureCodes.commentPinConflict => l10n.commentsErrPinConflict,
      FailureCodes.commentArticleLimit => l10n.commentsErrArticleLimit,
      FailureCodes.commentDuplicate => l10n.commentsErrDuplicate,
      FailureCodes.commentEmpty => l10n.commentsErrEmpty,
      FailureCodes.commentTooLong => l10n.commentsErrTooLong,
      FailureCodes.reportOwnContent => l10n.commentsErrReportOwnContent,
      FailureCodes.reportTargetNotSupported => l10n.commentsErrReportNotSupported,
      FailureCodes.reportReasonInvalid => l10n.commentsErrReportReason,
      FailureCodes.reportTargetNotFound => l10n.commentsErrNotFound,
      FailureCodes.requestCancelled => l10n.errCancelled,
      FailureCodes.networkOffline => l10n.errOffline,
      FailureCodes.networkTimeout => l10n.errTimeout,
      _ => l10n.errServer,
    };
