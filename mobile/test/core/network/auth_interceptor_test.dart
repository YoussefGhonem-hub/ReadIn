import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/network/interceptors.dart';
import 'package:readin/core/network/request_context.dart';
import 'package:readin/features/auth/data/datasources/auth_api.dart';
import 'package:readin/features/auth/data/datasources/auth_session_store.dart';

import '../../helpers/fake_auth.dart';

class FakeTokens implements SessionTokenProvider {
  FakeTokens(this.current, {this.next});

  String? current;
  String? next;
  final rejected = <String>[];
  final suspended = <Failure>[];

  @override
  Future<String?> accessToken() async => current;

  @override
  Future<String?> refreshAfterRejection(String token) async {
    rejected.add(token);
    current = next;
    return next;
  }

  @override
  Future<void> endSuspended(Failure reason) async {
    suspended.add(reason);
    current = null;
  }
}

class FakeDevice implements DeviceNameProvider {
  @override
  Future<String?> deviceName() async => 'Pixel 8';
}

Dio client(SessionTokenProvider tokens, ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))..httpClientAdapter = adapter;
  dio.interceptors.addAll([DeviceNameInterceptor(FakeDevice()), AuthInterceptor(tokens, dio)]);
  return dio;
}

String? bearer(RequestOptions o) => o.headers['Authorization'] as String?;

void main() {
  test('sends the access token, but not on sign-in calls', () async {
    final adapter = ScriptedAdapter((_) => (200, {'ok': true}));
    final dio = client(FakeTokens('a1'), adapter);

    await dio.get<dynamic>('/me');
    await dio.post<dynamic>('/auth/login', data: {});
    await dio.post<dynamic>('/auth/logout-all');

    expect(bearer(adapter.requests[0]), 'Bearer a1');
    expect(bearer(adapter.requests[1]), isNull);
    expect(bearer(adapter.requests[2]), 'Bearer a1');
  });

  test('names the device on calls that issue a session', () async {
    final adapter = ScriptedAdapter((_) => (200, {'ok': true}));
    final dio = client(FakeTokens(null), adapter);

    await dio.post<dynamic>('/auth/login', data: {});
    await dio.put<dynamic>('/me/password', data: {});
    await dio.get<dynamic>('/feed/today');

    expect(adapter.requests[0].headers[DeviceNameInterceptor.header], 'Pixel 8');
    expect(adapter.requests[1].headers[DeviceNameInterceptor.header], 'Pixel 8');
    expect(adapter.requests[2].headers.containsKey(DeviceNameInterceptor.header), isFalse);
  });

  test('on a 401 refreshes once and retries with the new token', () async {
    final tokens = FakeTokens('a1', next: 'a2');
    final adapter = ScriptedAdapter((o) => bearer(o) == 'Bearer a2' ? (200, {'id': 'u-1'}) : (401, {'code': 'auth.unauthorized'}));
    final dio = client(tokens, adapter);

    final response = await dio.get<dynamic>('/me');

    expect(response.statusCode, 200);
    expect(tokens.rejected, ['a1']);
    expect(adapter.requests.map(bearer), ['Bearer a1', 'Bearer a2']);
  });

  test('a 401 from a sign-in call is an answer, not a reason to refresh', () async {
    final tokens = FakeTokens('a1', next: 'a2');
    final dio = client(tokens, ScriptedAdapter((_) => (401, {'code': 'auth.invalid_credentials'})));

    await expectLater(dio.post<dynamic>('/auth/login', data: {}), throwsA(isA<DioException>()));
    expect(tokens.rejected, isEmpty);
  });

  test('when the refresh fails the original 401 goes through', () async {
    final tokens = FakeTokens('a1');
    final adapter = ScriptedAdapter((_) => (401, {'code': 'auth.unauthorized'}));
    final dio = client(tokens, adapter);

    final error = await dio.get<dynamic>('/me').then<DioException?>((_) => null, onError: (Object e) => e as DioException);
    expect(error?.response?.statusCode, 401);
    expect(adapter.requests, hasLength(1));
  });

  test('guests get 401s through without refreshing', () async {
    final tokens = FakeTokens(null, next: 'a2');
    final dio = client(tokens, ScriptedAdapter((_) => (401, null)));
    await expectLater(dio.get<dynamic>('/saved'), throwsA(isA<DioException>()));
    expect(tokens.rejected, isEmpty);
  });

  test('concurrent 401s share one refresh (single-flight) and all retry with the new token', () async {
    final secure = FakeSecureStore();
    var refreshes = 0;
    final authAdapter = ScriptedAdapter((o) async {
      refreshes++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return (200, session('a2', 'r2').toJson());
    });
    final authDio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))..httpClientAdapter = authAdapter;
    final store = AuthSessionStore(AuthApi(authDio), secure);
    await store.save(session('a1', 'r1'));

    final adapter = ScriptedAdapter((o) => bearer(o) == 'Bearer a2' ? (200, {'ok': true}) : (401, {'code': 'auth.unauthorized'}));
    final dio = client(store, adapter);

    final responses = await Future.wait([dio.get<dynamic>('/me'), dio.get<dynamic>('/saved'), dio.get<dynamic>('/feed/for-you')]);

    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
    expect(refreshes, 1);
    expect(authAdapter.requests.single.data, {'refreshToken': 'r1'});
    expect(secure.values[AuthSessionStore.refreshTokenKey], 'r2');
  });

  test('a signed-in call refused with 403 user.suspended ends the session with suspendedUntil (F22)', () async {
    final tokens = FakeTokens('a1');
    final adapter = ScriptedAdapter((_) => (403, {'code': 'user.suspended', 'suspendedUntil': '2026-11-09T12:00:00Z'}));
    final dio = client(tokens, adapter);

    final error = await dio.get<dynamic>('/me').then<DioException?>((_) => null, onError: (Object e) => e as DioException);

    expect(error?.response?.statusCode, 403, reason: 'the caller still gets the error');
    expect(tokens.suspended.single, Failure(FailureCodes.userSuspended, statusCode: 403, suspendedUntil: DateTime.utc(2026, 11, 9, 12)));
    expect(tokens.rejected, isEmpty, reason: 'no refresh for a 403');
  });

  test('other 403s, and a guest refused as suspended, keep the session alone', () async {
    final signedIn = FakeTokens('a1');
    await expectLater(
      client(signedIn, ScriptedAdapter((_) => (403, {'code': 'auth.forbidden'}))).get<dynamic>('/moderation/summary'),
      throwsA(isA<DioException>()),
    );
    final guest = FakeTokens(null);
    await expectLater(
      client(guest, ScriptedAdapter((_) => (403, {'code': 'user.suspended'}))).post<dynamic>('/auth/login', data: {}),
      throwsA(isA<DioException>()),
    );

    expect(signedIn.suspended, isEmpty);
    expect(guest.suspended, isEmpty);
  });
}
