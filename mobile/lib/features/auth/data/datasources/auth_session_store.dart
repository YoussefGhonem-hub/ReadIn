import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/network/request_context.dart';
import '../../../../core/storage/secure_store.dart';
import '../../domain/entities/me.dart';
import '../models/auth_models.dart';
import 'auth_api.dart';

/// The API session on this device (SPEC §9.3): the access token in memory only, the refresh token in the Keychain /
/// Keystore. Refresh tokens rotate on every use and presenting an old one ends the whole session, so refreshes run one
/// at a time (single-flight) and every new token is stored before anyone can use the old one again.
///
/// A refresh whose answer is lost (a timeout on a slow server, the app killed mid-refresh) would leave this device with
/// a token the server already rotated. So every refresh carries a retry key, stored with the token before it is sent:
/// the next attempt presents the same token with the same key, which the server accepts as long as the token it issued
/// for that key was never used.
@lazySingleton
class AuthSessionStore implements SessionTokenProvider {
  AuthSessionStore(this._api, this._secure, {@ignoreParam DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const refreshTokenKey = 'auth.refreshToken';

  /// The retry key of a refresh that hasn't been answered yet, as `<token tag>:<key>`: it only ever goes out with the
  /// refresh token it was made for ([tokenTag]).
  static const retryKeyKey = 'auth.refreshRetryKey';

  /// Refresh a little before the access token expires, so a call never leaves with a token about to die.
  static const expiryMargin = Duration(seconds: 30);

  final AuthApi _api;
  final SecureStore _secure;
  final DateTime Function() _clock;

  String? _accessToken;
  DateTime? _accessTokenExpiresAt;
  String? _refreshToken;
  bool _refreshTokenLoaded = false;
  Future<Result<Me?>>? _refreshing;
  Failure? _endedBy;
  ({String tag, String key})? _pendingRetry;
  final _changes = StreamController<Me?>.broadcast();

  /// The user after every session change; null when the session ended.
  Stream<Me?> get changes => _changes.stream;

  /// Why the last session ended when the server ended it for a suspended account (`user.suspended`, F22). Null after a
  /// sign out or any other ending, and once a new session starts.
  Failure? get endedBy => _endedBy;

  /// Stores a session returned by sign in, sign up, refresh, sign out everywhere, a password or a phone change.
  Future<Me> save(SessionModel session) async {
    _endedBy = null;
    _accessToken = session.accessToken;
    _accessTokenExpiresAt = session.accessTokenExpiresAt;
    if (session.refreshToken case final token? when token.isNotEmpty) {
      _refreshToken = token;
      _refreshTokenLoaded = true;
      await _secure.write(refreshTokenKey, token);
      await _forgetRetryKey(); // it belonged to the token just replaced
    }
    final me = session.user.toEntity();
    _changes.add(me);
    return me;
  }

  /// A new copy of the user without new tokens (complete profile, set PIN, `GET /me`).
  void updateUser(Me me) => _changes.add(me);

  /// Forgets the session on this device. [reason]: the server ended it (see [endedBy]).
  Future<void> clear({Failure? reason}) async {
    _endedBy = reason;
    _accessToken = null;
    _accessTokenExpiresAt = null;
    _refreshToken = null;
    _refreshTokenLoaded = true;
    try {
      await _secure.delete(refreshTokenKey);
      await _forgetRetryKey();
    } finally {
      _changes.add(null);
    }
  }

  Future<String?> refreshToken() async {
    if (!_refreshTokenLoaded) {
      try {
        _refreshToken = await _secure.read(refreshTokenKey);
      } catch (_) {
        _refreshToken = null; // unreadable after a restore to another device: start signed out
      }
      _refreshTokenLoaded = true;
    }
    return _refreshToken;
  }

  /// `POST /auth/refresh`, one at a time: callers that arrive while a refresh runs share its result. `Ok(null)` when
  /// there is no session; a rejected refresh token (`401`, or `403` for a suspended account) ends the session
  /// locally; a network error keeps it and its retry key, so the next call tries again with both.
  Future<Result<Me?>> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<Result<Me?>> _refresh() async {
    final token = await refreshToken();
    if (token == null) return const Ok(null);
    try {
      final retryKey = await _retryKeyFor(token);
      return Ok(await save(await _api.refresh(RefreshRequest(token, retryKey: retryKey))));
    } on DioException catch (e) {
      final failure = ApiErrorMapper.fromDio(e);
      if (failure.statusCode == 401 || failure.statusCode == 403) await clear(reason: _suspension(failure));
      return Err(failure);
    } on Object catch (e) {
      return Err(Failure(FailureCodes.serverError, message: '$e'));
    }
  }

  static Failure? _suspension(Failure failure) => failure.code == FailureCodes.userSuspended ? failure : null;

  /// The retry key for presenting [token]: the one an unanswered attempt stored for it, or a new one, stored before it
  /// is sent so it survives the app being killed mid-refresh.
  Future<String> _retryKeyFor(String token) async {
    final tag = tokenTag(token);
    if (_pendingRetry case final pending? when pending.tag == tag) return pending.key;
    String? stored;
    try {
      stored = await _secure.read(retryKeyKey);
    } catch (_) {
      stored = null; // unreadable: make a new one
    }
    if (stored case final value? when value.startsWith('$tag:') && value.length > tag.length + 1) {
      final key = value.substring(tag.length + 1);
      _pendingRetry = (tag: tag, key: key);
      return key;
    }
    final key = newRetryKey();
    _pendingRetry = (tag: tag, key: key);
    try {
      await _secure.write(retryKeyKey, '$tag:$key');
    } catch (_) {
      // Not stored: still sent, so a lost answer can be retried while the app runs.
    }
    return key;
  }

  Future<void> _forgetRetryKey() async {
    _pendingRetry = null;
    try {
      await _secure.delete(retryKeyKey);
    } catch (_) {
      // Harmless when it stays: it names a token that is gone, so it is never sent again.
    }
  }

  /// 32 random bytes, base64url without padding.
  @visibleForTesting
  static String newRetryKey() {
    final random = Random.secure();
    return base64Url.encode([for (var i = 0; i < 32; i++) random.nextInt(256)]).replaceAll('=', '');
  }

  /// Names the refresh token a stored retry key belongs to without storing the token twice: its SHA-256, base64url.
  @visibleForTesting
  static String tokenTag(String token) =>
      base64Url.encode(sha256.convert(utf8.encode(token)).bytes).replaceAll('=', '');

  @override
  Future<void> endSuspended(Failure reason) async {
    if (_accessToken == null && await refreshToken() == null) return; // already ended by a parallel call
    await clear(reason: _suspension(reason));
  }

  bool get _accessTokenFresh {
    final expiresAt = _accessTokenExpiresAt;
    return _accessToken != null && (expiresAt == null || _clock().isBefore(expiresAt.subtract(expiryMargin)));
  }

  @override
  Future<String?> accessToken() async {
    if (_accessTokenFresh) return _accessToken;
    if (await refreshToken() == null) return null;
    await refresh();
    return _accessToken;
  }

  @override
  Future<String?> refreshAfterRejection(String rejected) async {
    if (_accessToken != null && _accessToken != rejected) return _accessToken; // another call already refreshed
    final result = await refresh();
    return result.valueOrNull == null ? null : _accessToken;
  }
}
