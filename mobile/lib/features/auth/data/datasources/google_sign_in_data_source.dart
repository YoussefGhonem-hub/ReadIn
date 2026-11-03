import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/external_credential.dart';

/// Google Sign-In: the native account picker, then the account's ID token for
/// `POST /auth/external`. The API verifies the token; Firebase Auth isn't used.
@lazySingleton
class GoogleSignInDataSource {
  GoogleSignInDataSource() : this.withClient(GoogleSignIn.instance);

  @visibleForTesting
  GoogleSignInDataSource.withClient(this._google);

  /// OAuth clients of the `readin-cca78` Google Cloud project; the API accepts
  /// tokens issued to either. Android needs the web client (`client_type` 3 in
  /// google-services.json) as `serverClientId`, which becomes the token's
  /// audience. iOS uses its own client, whose reversed form is the URL scheme
  /// in ios/Runner/Info.plist.
  static const serverClientId = '56680910112-11fpmt15shbi4mddnkjtuemfrdoqrp6e.apps.googleusercontent.com';
  static const iosClientId = '56680910112-75d05fvhmih7a6kgftpq3osg88jpc2ul.apps.googleusercontent.com';

  final GoogleSignIn _google;
  Future<void>? _initialized;

  /// Shows the Google account picker. Returns null when the user closes it.
  ///
  /// Throws [GoogleSignInException] for every other failure.
  Future<ExternalCredential?> signInWithGoogle() async {
    await _ensureInitialized();
    final GoogleSignInAccount account;
    try {
      account = await _google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const GoogleSignInException(code: GoogleSignInExceptionCode.unknownError, description: 'No ID token');
    }
    return ExternalCredential(provider: ExternalProvider.google, idToken: idToken, displayName: account.displayName);
  }

  /// Forgets the chosen account, so the next sign-in shows the picker again.
  /// Best effort: a failure here must not block signing out of ReadIn.
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _google.signOut();
    } on Exception catch (error) {
      debugPrint('Google sign-out failed: $error');
    }
  }

  Future<void> _ensureInitialized() => _initialized ??= _initialize();

  Future<void> _initialize() async {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    try {
      await _google.initialize(clientId: ios ? iosClientId : null, serverClientId: ios ? null : serverClientId);
    } catch (_) {
      _initialized = null; // let the next attempt retry
      rethrow;
    }
  }
}
