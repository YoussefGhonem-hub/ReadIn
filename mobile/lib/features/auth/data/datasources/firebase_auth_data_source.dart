import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../../core/network/request_context.dart';

/// Wraps the Firebase Auth SDK. Every call degrades gracefully when Firebase
/// is unavailable (`auth.unavailable`), so the app still runs in guest mode.
/// Also bound as [IdTokenProvider] for the network layer (see [AuthModule]).
@lazySingleton
class FirebaseAuthDataSource implements IdTokenProvider {
  FirebaseAuthDataSource(this._status);

  final FirebaseStatus _status;

  bool get isAvailable => _status.available;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<String?> watchUid() =>
      isAvailable ? _auth.authStateChanges().map((user) => user?.uid) : Stream<String?>.value(null);

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    if (!isAvailable) return null;
    try {
      return await _auth.currentUser?.getIdToken(forceRefresh);
    } on FirebaseAuthException {
      return null;
    }
  }

  Future<Result<void>> signIn(String email, String password) => _guard(() async {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      });

  Future<Result<void>> signUp(String displayName, String email, String password) => _guard(() async {
        final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        final user = credential.user;
        if (user == null) return;
        await user.updateDisplayName(displayName);
        await user.sendEmailVerification();
        await user.getIdToken(true); // refresh so the API sees the new name
      });

  Future<Result<void>> sendPasswordReset(String email) => _guard(() => _auth.sendPasswordResetEmail(email: email));

  Future<void> signOut() async {
    if (isAvailable) await _auth.signOut();
  }

  Future<Result<void>> _guard(Future<void> Function() action) async {
    if (!isAvailable) return const Err(Failure(FailureCodes.authUnavailable));
    try {
      await action();
      return const Ok(null);
    } on FirebaseAuthException catch (e) {
      return Err(Failure(mapFirebaseCode(e.code), message: e.message));
    }
  }

  /// Maps Firebase Auth error codes to stable app [FailureCodes].
  static String mapFirebaseCode(String code) => switch (code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-login-credentials' =>
          FailureCodes.authInvalidCredentials,
        'email-already-in-use' => FailureCodes.authEmailInUse,
        'weak-password' => FailureCodes.authWeakPassword,
        'invalid-email' => FailureCodes.authInvalidEmail,
        'too-many-requests' => FailureCodes.authTooManyRequests,
        'network-request-failed' => FailureCodes.networkOffline,
        'user-disabled' => FailureCodes.userSuspended,
        _ => FailureCodes.authUnavailable,
      };
}
