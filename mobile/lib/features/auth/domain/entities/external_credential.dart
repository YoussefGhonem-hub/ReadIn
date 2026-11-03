import 'package:equatable/equatable.dart';

/// Sign-in providers accepted by `POST /auth/external`; [name] is the API value.
enum ExternalProvider { google, apple }

/// A Google or Apple ID token for the API, which verifies it and returns a
/// ReadIn session. Also used to link a provider and to confirm identity.
class ExternalCredential extends Equatable {
  const ExternalCredential({required this.provider, required this.idToken, this.nonce, this.displayName});

  final ExternalProvider provider;
  final String idToken;

  /// The raw nonce whose SHA-256 went to the provider (Apple).
  final String? nonce;

  /// The name the provider shared, used only when the API creates a new
  /// account. Apple shares it on the first authorization only.
  final String? displayName;

  @override
  List<Object?> get props => [provider, idToken, nonce, displayName];
}
