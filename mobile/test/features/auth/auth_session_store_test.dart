import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/auth/data/datasources/auth_api.dart';
import 'package:readin/features/auth/data/datasources/auth_session_store.dart';
import 'package:readin/features/auth/data/models/auth_models.dart';
import 'package:readin/features/auth/domain/entities/me.dart';

import '../../helpers/fake_auth.dart';

class MockAuthApi extends Mock implements AuthApi {}

void main() {
  setUpAll(() => registerFallbackValue(const RefreshRequest('')));

  late MockAuthApi api;
  late FakeSecureStore secure;
  late DateTime now;
  late AuthSessionStore store;

  setUp(() {
    api = MockAuthApi();
    secure = FakeSecureStore();
    now = DateTime.utc(2026, 11, 3, 12);
    store = AuthSessionStore(api, secure, clock: () => now);
  });

  test('without a stored refresh token there is nothing to restore', () async {
    expect((await store.refresh()).valueOrNull, isNull);
    expect(await store.accessToken(), isNull);
    verifyNever(() => api.refresh(any()));
  });

  test('restores the session and stores the rotated refresh token', () async {
    secure.values[AuthSessionStore.refreshTokenKey] = 'r1';
    when(() => api.refresh(any())).thenAnswer((_) async => session('a2', 'r2'));
    final users = <Me?>[];
    store.changes.listen(users.add);

    final result = await store.refresh();

    expect(result.valueOrNull?.username, 'reader1');
    expect(secure.values[AuthSessionStore.refreshTokenKey], 'r2');
    expect(await store.accessToken(), 'a2');
    expect(verify(() => api.refresh(captureAny())).captured.single.refreshToken, 'r1');
    await Future<void>.delayed(Duration.zero);
    expect(users.single?.id, 'u-1');
  });

  test('refreshes one at a time and always presents the newest token', () async {
    secure.values[AuthSessionStore.refreshTokenKey] = 'r1';
    final gate = Completer<SessionModel>();
    when(() => api.refresh(any())).thenAnswer((_) => gate.future);

    final first = store.refresh();
    final second = store.refresh();
    gate.complete(session('a2', 'r2'));
    await Future.wait([first, second]);
    verify(() => api.refresh(any())).called(1);

    when(() => api.refresh(any())).thenAnswer((_) async => session('a3', 'r3'));
    await store.refresh();
    expect(verify(() => api.refresh(captureAny())).captured.single.refreshToken, 'r2');
    expect(secure.values[AuthSessionStore.refreshTokenKey], 'r3');
  });

  test('a rejected refresh token ends the session locally', () async {
    secure.values[AuthSessionStore.refreshTokenKey] = 'r1';
    when(() => api.refresh(any())).thenThrow(httpError('/auth/refresh', 401, code: 'auth.refresh_invalid'));
    final users = <Me?>[];
    store.changes.listen(users.add);

    final result = await store.refresh();

    expect(result.failureOrNull?.code, 'auth.refresh_invalid');
    expect(secure.values, isEmpty);
    expect(await store.accessToken(), isNull);
    await Future<void>.delayed(Duration.zero);
    expect(users, [null]);
  });

  test('a network error keeps the session for the next try', () async {
    secure.values[AuthSessionStore.refreshTokenKey] = 'r1';
    when(() => api.refresh(any())).thenThrow(offline('/auth/refresh'));

    final result = await store.refresh();

    expect(result.failureOrNull?.code, FailureCodes.networkOffline);
    expect(secure.values[AuthSessionStore.refreshTokenKey], 'r1');
  });

  test('refreshes before using an access token that is about to expire', () async {
    await store.save(session('a1', 'r1', expiresAt: now.add(const Duration(minutes: 15))));
    expect(await store.accessToken(), 'a1');
    verifyNever(() => api.refresh(any()));

    now = now.add(const Duration(minutes: 14, seconds: 45)); // inside the 30-second margin
    when(() => api.refresh(any())).thenAnswer((_) async => session('a2', 'r2', expiresAt: now.add(const Duration(minutes: 15))));
    expect(await store.accessToken(), 'a2');
    verify(() => api.refresh(any())).called(1);
  });

  test('after a 401, refreshes only if nobody already replaced the rejected token', () async {
    await store.save(session('a1', 'r1'));
    when(() => api.refresh(any())).thenAnswer((_) async => session('a2', 'r2'));

    expect(await store.refreshAfterRejection('a1'), 'a2');
    expect(await store.refreshAfterRejection('a1'), 'a2'); // a second call that failed with a1
    verify(() => api.refresh(any())).called(1);

    when(() => api.refresh(any())).thenThrow(httpError('/auth/refresh', 401));
    expect(await store.refreshAfterRejection('a2'), isNull);
    expect(secure.values, isEmpty);
  });

  test('clear forgets both tokens and reports the end of the session', () async {
    await store.save(session('a1', 'r1'));
    final users = <Me?>[];
    store.changes.listen(users.add);
    await store.clear();
    await Future<void>.delayed(Duration.zero);
    expect(await store.refreshToken(), isNull);
    expect(await store.accessToken(), isNull);
    expect(users, [null]);
  });

  group('a suspended account (F22)', () {
    DioException suspended(String path) => DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: path),
            statusCode: 403,
            data: {'status': 403, 'code': 'user.suspended', 'suspendedUntil': '2026-11-09T12:00:00Z'},
          ),
        );

    test('a refused refresh ends the session and keeps why', () async {
      secure.values[AuthSessionStore.refreshTokenKey] = 'r1';
      when(() => api.refresh(any())).thenThrow(suspended('/auth/refresh'));

      await store.refresh();

      expect(store.endedBy?.code, FailureCodes.userSuspended);
      expect(store.endedBy?.suspendedUntil, DateTime.utc(2026, 11, 9, 12));
      expect(secure.values, isEmpty);
    });

    test('a refused call ends the session once; signing in again or out forgets why', () async {
      await store.save(session('a1', 'r1'));
      final users = <Me?>[];
      store.changes.listen(users.add);
      const reason = Failure(FailureCodes.userSuspended, statusCode: 403);

      await store.endSuspended(reason);
      await store.endSuspended(reason); // a parallel call: already ended
      await Future<void>.delayed(Duration.zero);

      expect(users, [null]);
      expect(store.endedBy, reason);
      expect(await store.accessToken(), isNull);

      await store.save(session('a2', 'r2'));
      expect(store.endedBy, isNull);
      await store.clear();
      expect(store.endedBy, isNull);
    });

    test('a rejected refresh token for another reason keeps no reason', () async {
      secure.values[AuthSessionStore.refreshTokenKey] = 'r1';
      when(() => api.refresh(any())).thenThrow(httpError('/auth/refresh', 401, code: 'auth.refresh_invalid'));

      await store.refresh();

      expect(store.endedBy, isNull);
    });
  });
}
