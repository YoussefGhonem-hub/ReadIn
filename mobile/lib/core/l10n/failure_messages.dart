import '../errors/failure.dart';
import 'gen/app_localizations.dart';

/// Maps a [Failure.code] to a translated message. Unknown codes fall back to
/// the generic server error — raw server text is never shown to users.
String localizeFailure(AppLocalizations l10n, Failure failure) => switch (failure.code) {
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
