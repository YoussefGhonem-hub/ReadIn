/// The API session's tokens for [AuthInterceptor]. Implemented by the auth feature so `core/` never depends on it.
abstract interface class SessionTokenProvider {
  /// The access token for the next call, refreshed first when it has expired (single-flight); null for guests.
  Future<String?> accessToken();

  /// After a `401` for [rejected]: the token to retry with, refreshing once if nobody has yet (single-flight). Null
  /// when the session is over, in which case it has already been ended locally.
  Future<String?> refreshAfterRejection(String rejected);
}

/// This device's model ("Pixel 8"), sent as `X-Device-Name` on calls that issue a session (SPEC §9.3).
abstract interface class DeviceNameProvider {
  Future<String?> deviceName();
}
