import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/entities/external_credential.dart';

typedef AppleCredentialRequest = Future<AuthorizationCredentialAppleID> Function({
  required List<AppleIDAuthorizationScopes> scopes,
  String? nonce,
});

/// Sign in with Apple (native, iOS only for now: Android needs a server
/// callback). Apple gets the SHA-256 of a fresh nonce and the API gets the raw
/// nonce, so a stolen identity token can't be replayed. The one-time
/// authorization code goes to the API too: it keeps a token it can revoke when
/// the account is deleted.
@lazySingleton
class AppleSignInDataSource {
  AppleSignInDataSource() : this.withRequest(SignInWithApple.getAppleIDCredential);

  @visibleForTesting
  AppleSignInDataSource.withRequest(this._request, {Random? random}) : _random = random ?? Random.secure();

  final AppleCredentialRequest _request;
  final Random _random;

  /// Whether to show the Apple button on this device.
  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Shows the Apple sheet. Returns null when the user cancels.
  ///
  /// Throws [SignInWithAppleException] for every other failure.
  Future<ExternalCredential?> signInWithApple() async {
    final nonce = _nonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await _request(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const SignInWithAppleAuthorizationException(code: AuthorizationErrorCode.invalidResponse, message: 'No identity token');
    }
    final name = [credential.givenName, credential.familyName].whereType<String>().join(' ').trim();
    return ExternalCredential(
      provider: ExternalProvider.apple,
      idToken: idToken,
      nonce: nonce,
      authorizationCode: credential.authorizationCode.isEmpty ? null : credential.authorizationCode,
      displayName: name.isEmpty ? null : name,
    );
  }

  /// 32 random URL-safe characters.
  String _nonce() {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    return List.generate(32, (_) => charset[_random.nextInt(charset.length)]).join();
  }
}
