import 'package:injectable/injectable.dart';

import '../../../../core/storage/key_value_store.dart';
import '../../../../core/storage/secure_store.dart';
import 'auth_session_store.dart';

/// Deleting the app signs out. iOS keeps Keychain items after the app is deleted, so a reinstall would come back signed
/// in; the key/value store (Hive) lives in the app's data and goes with it. So the first launch of an install, told by
/// [markerKey] missing from that store, forgets the refresh token and its retry key before the session is restored.
///
/// Builds from before the marker never wrote it: when the store already holds anything (settings, welcome seen, the
/// last phone country, recent searches…), this is an update of an existing install, and only the marker is written.
@lazySingleton
class FreshInstallCheck {
  FreshInstallCheck(this._store, this._secure);

  /// True once this install has started; false while a new install still has to forget an earlier one's session
  /// (the Keychain couldn't be reached yet).
  static const markerKey = 'app.installed';

  final KeyValueStore _store;
  final SecureStore _secure;

  /// Runs once at startup, before anything reads the stored session or writes to the store. True when it forgot a
  /// session left by an earlier install. Never throws: at worst the check runs again on the next launch.
  Future<bool> run() async {
    try {
      final marker = _store.read<bool>(markerKey);
      if (marker == true) return false;
      final freshInstall = marker == false || _store.isEmpty;
      if (freshInstall) {
        try {
          await _secure.delete(AuthSessionStore.refreshTokenKey);
          await _secure.delete(AuthSessionStore.retryKeyKey);
        } catch (_) {
          await _store.write(markerKey, false); // the next launch tries again, even with settings stored by then
          return false;
        }
      }
      await _store.write(markerKey, true);
      return freshInstall;
    } catch (_) {
      return false;
    }
  }
}
