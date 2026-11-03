import '../../../../core/errors/result.dart';
import '../entities/auth_config.dart';
import '../entities/me.dart';

/// Phone + password sign in with the API's own sessions (SPEC §9, ADR 0007). Every call that returns a session stores
/// its tokens (the refresh token rotates every time) and reports the user through [sessionChanges].
abstract interface class AuthRepository {
  /// The signed-in user after every session change, or null once the session has ended (signed out, the refresh
  /// token was rejected, the account was deleted).
  Stream<Me?> get sessionChanges;

  /// `GET /auth/config`, cached; the defaults when it can't be loaded.
  Future<AuthConfig> getConfig();

  /// Splash: `POST /auth/refresh` with the stored refresh token. `Ok(null)` when there is no session to restore.
  Future<Result<Me?>> restoreSession();

  Future<Result<Me>> signIn({required String phoneNumber, required String password});

  /// Sent only after the "confirm your number" dialog.
  Future<Result<Me>> register({
    required String phoneNumber,
    required String password,
    required String recoveryPin,
    required String uiLanguage,
  });

  /// Forgot password, step 1: phone + recovery PIN → a 10-minute reset token.
  Future<Result<String>> verifyRecoveryPin({required String phoneNumber, required String pin});

  /// Forgot password, step 2. Every session of the account ends.
  Future<Result<void>> resetPassword({required String resetToken, required String newPassword});

  /// Unregisters this device's push token, ends the session on the server (best effort) and forgets it locally.
  Future<void> signOut();

  /// `POST /auth/logout-all`: every other session ends, this device gets fresh tokens.
  Future<Result<Me>> signOutEverywhere();
}

/// The signed-in account (SPEC F01, F18).
abstract interface class AccountRepository {
  /// `GET /me`.
  Future<Result<Me>> getMe();

  Future<Result<UsernameAvailability>> checkUsername(String username);

  Future<Result<Me>> completeProfile({required String displayName, required String username, String? avatarUrl});

  /// The mandatory first PIN (`mustSetRecoveryPin`).
  Future<Result<Me>> setRecoveryPin(String pin);

  Future<Result<void>> changeRecoveryPin({required String currentPassword, required String newPin});

  /// Other sessions end; this one gets fresh tokens.
  Future<Result<Me>> changePassword({required String currentPassword, required String newPassword});

  /// Other sessions end; this one gets fresh tokens.
  Future<Result<Me>> changePhoneNumber({required String newPhoneNumber, required String currentPassword});

  /// Signs out everywhere; the session is forgotten locally on success.
  Future<Result<void>> deleteAccount(String password);
}
