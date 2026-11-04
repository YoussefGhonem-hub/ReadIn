import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/notification_fixtures.dart';

class MockRealtimeService extends Mock implements RealtimeService {}

class MockSessionCubit extends MockCubit<SessionState> implements SessionCubit {}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late ValueNotifier<int> liveCount;
  late ValueNotifier<bool> live;
  late MockRealtimeService realtime;
  late FakeNotificationsRepository repository;
  late MockSessionCubit session;
  late StreamController<SessionState> sessions;

  const signedIn = SessionState(status: SessionStatus.authenticated, me: sampleMe);
  const guest = SessionState(status: SessionStatus.guest);

  setUp(() {
    liveCount = ValueNotifier(0);
    live = ValueNotifier(false);
    realtime = MockRealtimeService();
    when(() => realtime.unreadNotifications).thenReturn(liveCount);
    when(() => realtime.unreadLive).thenReturn(live);
    repository = FakeNotificationsRepository()..unread = 4;
    session = MockSessionCubit();
    sessions = StreamController<SessionState>.broadcast();
    addTearDown(sessions.close);
  });

  UnreadBadgeCubit build(SessionState initial) {
    whenListen(session, sessions.stream, initialState: initial);
    final cubit = UnreadBadgeCubit(realtime, GetUnreadNotificationCount(repository), session);
    addTearDown(cubit.close);
    return cubit;
  }

  test('follows the live count while the Realtime Database delivers it', () async {
    live.value = true;
    liveCount.value = 2;
    final cubit = build(signedIn);
    expect(cubit.state, 2);

    liveCount.value = 5;
    expect(cubit.state, 5);
    await settle();
    expect(repository.calls, isEmpty, reason: 'no REST call while the database is live');
  });

  test('without the database, the count comes from GET /me/notifications/unread-count', () async {
    final cubit = build(signedIn);
    await settle();
    expect(cubit.state, 4);
    expect(repository.calls, ['unread-count']);

    // The database comes up: its value wins.
    liveCount.value = 6;
    expect(cubit.state, 4, reason: 'not live yet');
    live.value = true;
    expect(cubit.state, 6);

    // It drops out (e.g. permission denied): back to REST.
    repository.unread = 7;
    live.value = false;
    await settle();
    expect(cubit.state, 7);
  });

  test('refresh re-reads the count only while the database is unavailable', () async {
    final cubit = build(signedIn);
    await settle();
    repository.unread = 9;
    await cubit.refresh();
    expect(cubit.state, 9);

    live.value = true;
    repository.calls.clear();
    await cubit.refresh();
    expect(repository.calls, isEmpty);
  });

  test('a REST answer that arrives after the live count is dropped', () async {
    final pending = Completer<void>();
    final slow = _SlowCount(pending.future, 3);
    whenListen(session, sessions.stream, initialState: signedIn);
    final cubit = UnreadBadgeCubit(realtime, slow, session);
    addTearDown(cubit.close);

    liveCount.value = 8;
    live.value = true;
    pending.complete();
    await settle();
    expect(cubit.state, 8);
  });

  test('a failed REST call keeps the count', () async {
    final cubit = build(signedIn);
    await settle();
    repository.unreadFailure = const Failure(FailureCodes.networkOffline);
    await cubit.refresh();
    expect(cubit.state, 4);
  });

  test('opening the center clears it', () async {
    final cubit = build(signedIn);
    await settle();
    cubit.clear();
    expect(cubit.state, 0);
  });

  test('guests see 0 and never call the API; signing in loads the count, signing out clears it', () async {
    final cubit = build(guest);
    await settle();
    expect(cubit.state, 0);
    expect(repository.calls, isEmpty);

    sessions.add(signedIn);
    await settle();
    expect(cubit.state, 4);

    sessions.add(guest);
    await settle();
    expect(cubit.state, 0);
  });

  test('waits for the stored session to be restored', () async {
    final cubit = build(const SessionState());
    await settle();
    expect(repository.calls, isEmpty);
    sessions.add(signedIn);
    await settle();
    expect(cubit.state, 4);
  });

  test('stops listening when closed', () async {
    live.value = true;
    final cubit = build(signedIn);
    await cubit.close();
    liveCount.value = 9;
    expect(cubit.state, 0);
  });
}

class _SlowCount implements GetUnreadNotificationCount {
  _SlowCount(this._gate, this._count);

  final Future<void> _gate;
  final int _count;

  @override
  Future<Result<int>> call() async {
    await _gate;
    return Ok(_count);
  }
}
