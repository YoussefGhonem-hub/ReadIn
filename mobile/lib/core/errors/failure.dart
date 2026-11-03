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
  static const interestsMinThree = 'user.interests.min_three';
  static const fieldNotFound = 'field.not_found';
  static const articleNotFound = 'article.not_found';
  static const serverError = 'server.error';

  // Client-side
  static const networkOffline = 'network.offline';
  static const networkTimeout = 'network.timeout';
  static const authUnavailable = 'auth.unavailable';
  static const authInvalidCredentials = 'auth.invalid_credentials';
  static const authEmailInUse = 'auth.email_in_use';
  static const authWeakPassword = 'auth.weak_password';
  static const authInvalidEmail = 'auth.invalid_email';
  static const authTooManyRequests = 'auth.too_many_requests';
}
