import '../../../../core/errors/result.dart';
import '../entities/me.dart';

/// Firebase identity (sign-in methods, SPEC §9.1).
abstract interface class AuthRepository {
  /// False when Firebase failed to initialize (guest-only mode).
  bool get isAvailable;

  /// Emits the Firebase uid on sign-in and null on sign-out.
  Stream<String?> watchUid();

  Future<Result<void>> signInWithEmail({required String email, required String password});

  /// Creates the Firebase user, sets its display name and sends the
  /// verification email.
  Future<Result<void>> signUpWithEmail({required String displayName, required String email, required String password});

  Future<Result<void>> sendPasswordReset(String email);

  Future<void> signOut();
}

/// The SQL Server account behind the Firebase identity (SPEC §9.2 step 4).
abstract interface class AccountRepository {
  /// `POST /auth/sync` — creates the user on first call, refreshes it after.
  Future<Result<Me>> sync({required String uiLanguage});

  /// `GET /me`.
  Future<Result<Me>> getMe();
}
