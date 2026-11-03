/// Supplies the Firebase ID token for API calls. Implemented by the auth
/// feature so `core/` never depends on Firebase directly.
abstract interface class IdTokenProvider {
  /// Current ID token, or null for guests. [forceRefresh] after a 401.
  Future<String?> idToken({bool forceRefresh = false});
}
