import '../errors/failure.dart';
import 'gen/app_localizations.dart';

/// Maps a [Failure.code] to a translated message. Unknown codes fall back to
/// the generic server error — raw server text is never shown to users.
String localizeFailure(AppLocalizations l10n, Failure failure) => localizeErrorCode(l10n, failure.code);

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
      FailureCodes.interestsMinThree => l10n.errInterestsMinThree,
      FailureCodes.fieldNotFound => l10n.errFieldNotFound,
      FailureCodes.articleNotFound => l10n.errArticleNotFound,
      FailureCodes.articleSourcesRequired => l10n.errSourcesRequired,
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
      FailureCodes.requestCancelled => l10n.errCancelled,
      FailureCodes.networkOffline => l10n.errOffline,
      FailureCodes.networkTimeout => l10n.errTimeout,
      FailureCodes.authUnavailable => l10n.errAuthUnavailable,
      FailureCodes.authInvalidCredentials => l10n.errInvalidCredentials,
      FailureCodes.authEmailInUse => l10n.errEmailInUse,
      FailureCodes.authWeakPassword => l10n.errWeakPassword,
      FailureCodes.authInvalidEmail => l10n.errInvalidEmail,
      FailureCodes.authTooManyRequests => l10n.errTooManyRequests,
      _ => l10n.errServer,
    };
