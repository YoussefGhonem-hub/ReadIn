import 'package:equatable/equatable.dart';

/// Sign-in providers accepted by `POST /auth/external`; [name] is the API value.
enum ExternalProvider { google, apple }

/// A Google or Apple ID token for the API, which verifies it and returns a
/// ReadIn session. Also used to link a provider and to confirm identity.
class ExternalCredential extends Equatable {
  const ExternalCredential({
    required this.provider,
    required this.idToken,
    this.nonce,
    this.authorizationCode,
    this.displayName,
  });

  final ExternalProvider provider;
  final String idToken;

  /// The raw nonce whose SHA-256 went to the provider (Apple).
  final String? nonce;

  /// Apple's one-time authorization code. The API exchanges it for a token it can revoke when the account is deleted
  /// (App Store guideline 5.1.1(v)), so it goes with every Apple credential: sign in, link and delete.
  final String? authorizationCode;

  /// The name the provider shared, used only when the API creates a new
  /// account. Apple shares it on the first authorization only.
  final String? displayName;

  @override
  List<Object?> get props => [provider, idToken, nonce, authorizationCode, displayName];
}
