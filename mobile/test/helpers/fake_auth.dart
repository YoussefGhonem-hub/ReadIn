import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:readin/core/storage/secure_store.dart';
import 'package:readin/features/auth/data/models/auth_models.dart';

/// [SecureStore] backed by a map.
class FakeSecureStore extends SecureStore {
  FakeSecureStore([Map<String, String>? values])
      : values = {...?values},
        super(const FlutterSecureStorage());

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

MeModel meModel({String id = 'u-1', bool mustSetRecoveryPin = false}) => MeModel(
      id: id,
      phoneNumber: '+12025550110',
      displayName: 'Reader 1',
      username: 'reader1',
      onboardingCompleted: true,
      mustSetRecoveryPin: mustSetRecoveryPin,
    );

SessionModel session(String access, String refresh, {DateTime? expiresAt, MeModel? user}) => SessionModel(
      accessToken: access,
      accessTokenExpiresAt: expiresAt ?? DateTime.utc(2030),
      refreshToken: refresh,
      refreshTokenExpiresAt: DateTime.utc(2030),
      user: user ?? meModel(),
    );

DioException httpError(String path, int status, {String? code}) => DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: status,
        data: {'status': status, 'code': ?code, 'title': 'error'},
      ),
    );

DioException offline(String path) =>
    DioException(requestOptions: RequestOptions(path: path), type: DioExceptionType.connectionError);

/// A scripted HTTP server for Dio: every request is recorded, [handler] answers it.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.handler);

  final FutureOr<(int, Object?)> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options.copyWith(headers: {...options.headers})); // a retry mutates the same options
    final (status, body) = await handler(options);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
