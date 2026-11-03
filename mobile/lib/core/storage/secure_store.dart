import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Keychain/Keystore-backed storage for secrets (tokens, device ids).
/// Firebase keeps its own session; this is for app-owned secrets such as the
/// registered FCM token (F17).
@lazySingleton
class SecureStore {
  SecureStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
}
