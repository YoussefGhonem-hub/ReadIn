import 'dart:async';

import 'package:dio/dio.dart';
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
@lazySingleton
class AuthSessionStore implements SessionTokenProvider {
  AuthSessionStore(this._api, this._secure, {@ignoreParam DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const refreshTokenKey = 'auth.refreshToken';

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
  final _changes = StreamController<Me?>.broadcast();

  /// The user after every session change; null when the session ended.
  Stream<Me?> get changes => _changes.stream;

  /// Stores a session returned by sign in, sign up, refresh, sign out everywhere, a password or a phone change.
  Future<Me> save(SessionModel session) async {
    _accessToken = session.accessToken;
    _accessTokenExpiresAt = session.accessTokenExpiresAt;
    if (session.refreshToken case final token? when token.isNotEmpty) {
      _refreshToken = token;
      _refreshTokenLoaded = true;
      await _secure.write(refreshTokenKey, token);
    }
    final me = session.user.toEntity();
    _changes.add(me);
    return me;
  }

  /// A new copy of the user without new tokens (complete profile, set PIN, `GET /me`).
  void updateUser(Me me) => _changes.add(me);

  /// Forgets the session on this device.
  Future<void> clear() async {
    _accessToken = null;
    _accessTokenExpiresAt = null;
    _refreshToken = null;
    _refreshTokenLoaded = true;
    try {
      await _secure.delete(refreshTokenKey);
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
  /// locally; a network error keeps it, so the next call can try again.
  Future<Result<Me?>> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<Result<Me?>> _refresh() async {
    final token = await refreshToken();
    if (token == null) return const Ok(null);
    try {
      return Ok(await save(await _api.refresh(RefreshRequest(token))));
    } on DioException catch (e) {
      final failure = ApiErrorMapper.fromDio(e);
      if (failure.statusCode == 401 || failure.statusCode == 403) await clear();
      return Err(failure);
    } on Object catch (e) {
      return Err(Failure(FailureCodes.serverError, message: '$e'));
    }
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
