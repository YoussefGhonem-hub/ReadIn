import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/usecases/auth_usecases.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';

import '../../helpers/fixtures.dart';

class MockWatchSession extends Mock implements WatchSession {}

class MockRestoreSession extends Mock implements RestoreSession {}

class MockGetMe extends Mock implements GetMe {}

class MockSignOut extends Mock implements SignOut {}

class MockSignOutEverywhere extends Mock implements SignOutEverywhere {}

void main() {
  late StreamController<Me?> changes;
  late MockWatchSession watch;
  late MockRestoreSession restore;
  late MockGetMe getMe;
  late MockSignOut signOut;
  late MockSignOutEverywhere signOutEverywhere;

  SessionCubit build() => SessionCubit(watch, restore, getMe, signOut, signOutEverywhere);

  setUp(() {
    changes = StreamController<Me?>.broadcast();
    watch = MockWatchSession();
    restore = MockRestoreSession();
    getMe = MockGetMe();
    signOut = MockSignOut();
    signOutEverywhere = MockSignOutEverywhere();
    when(() => watch()).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  blocTest<SessionCubit, SessionState>(
    'restores a stored session on start',
    setUp: () => when(() => restore()).thenAnswer((_) async => const Ok(sampleMe)),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => const [SessionState(status: SessionStatus.authenticated, me: sampleMe)],
  );

  blocTest<SessionCubit, SessionState>(
    'is a guest without a stored session',
    setUp: () => when(() => restore()).thenAnswer((_) async => const Ok(null)),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => const [SessionState(status: SessionStatus.guest)],
  );

  blocTest<SessionCubit, SessionState>(
    'is a guest when the refresh token was rejected',
    setUp: () => when(() => restore())
        .thenAnswer((_) async => const Err(Failure('auth.refresh_invalid', statusCode: 401))),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => const [
      SessionState(status: SessionStatus.guest, failure: Failure('auth.refresh_invalid', statusCode: 401)),
    ],
  );

  blocTest<SessionCubit, SessionState>(
    'stays signed in while offline, without a user yet',
    setUp: () => when(() => restore()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline))),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => const [
      SessionState(status: SessionStatus.authenticated, failure: Failure(FailureCodes.networkOffline)),
    ],
  );

  blocTest<SessionCubit, SessionState>(
    'follows sign in, account changes and sign out',
    setUp: () => when(() => restore()).thenAnswer((_) async => const Ok(null)),
    build: build,
    act: (cubit) async {
      await cubit.start();
      changes.add(const Me(id: 'u', displayName: 'New', username: 'reader_abc', isProfileComplete: false));
      await Future<void>.delayed(Duration.zero);
      changes.add(sampleMe);
      await Future<void>.delayed(Duration.zero);
      changes.add(null);
    },
    expect: () => const [
      SessionState(status: SessionStatus.guest),
      SessionState(
        status: SessionStatus.authenticated,
        me: Me(id: 'u', displayName: 'New', username: 'reader_abc', isProfileComplete: false),
      ),
      SessionState(status: SessionStatus.authenticated, me: sampleMe),
      SessionState(status: SessionStatus.guest),
    ],
  );

  group('gate (SPEC §9.2 order)', () {
    SessionState with_(Me me) => SessionState(status: SessionStatus.authenticated, me: me);
    const base = Me(id: 'u', displayName: 'N', username: 'n', onboardingCompleted: true);

    test('applies the guards in order', () {
      expect(
        with_(const Me(
          id: 'u',
          displayName: 'N',
          username: 'n',
          mustChangePassword: true,
          mustSetRecoveryPin: true,
          isProfileComplete: false,
        )).gate,
        AccountGate.changePassword,
      );
      expect(
        with_(const Me(id: 'u', displayName: 'N', username: 'n', mustSetRecoveryPin: true, isProfileComplete: false)).gate,
        AccountGate.setRecoveryPin,
      );
      expect(with_(const Me(id: 'u', displayName: 'N', username: 'n', isProfileComplete: false)).gate, AccountGate.completeProfile);
      expect(with_(const Me(id: 'u', displayName: 'N', username: 'n')).gate, AccountGate.onboarding);
      expect(with_(base).gate, isNull);
      expect(const SessionState(status: SessionStatus.guest).gate, isNull);
    });
  });

  test('signOutEverywhere reports the failure, if any', () async {
    when(() => restore()).thenAnswer((_) async => const Ok(sampleMe));
    when(() => signOutEverywhere()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
    final cubit = build();
    await cubit.start();
    expect((await cubit.signOutEverywhere())?.code, FailureCodes.networkOffline);
    when(() => signOutEverywhere()).thenAnswer((_) async => const Ok(sampleMe));
    expect(await cubit.signOutEverywhere(), isNull);
    await cubit.close();
  });

  test('refresh keeps the user and records the failure', () async {
    when(() => restore()).thenAnswer((_) async => const Ok(sampleMe));
    when(() => getMe()).thenAnswer((_) async => const Err(Failure(FailureCodes.networkTimeout)));
    final cubit = build();
    await cubit.start();
    await cubit.refresh();
    expect(cubit.state.me, sampleMe);
    expect(cubit.state.failure?.code, FailureCodes.networkTimeout);
    await cubit.close();
  });

  test('a session the server ended for a suspended account keeps why (F22)', () async {
    when(() => restore()).thenAnswer((_) async => const Ok(sampleMe));
    final suspended = Failure(FailureCodes.userSuspended, statusCode: 403, suspendedUntil: DateTime.utc(2026, 11, 9));
    final cubit = build();
    await cubit.start();

    when(() => watch.endedBy).thenReturn(suspended);
    changes.add(null);
    await pumpEventQueue();

    expect(cubit.state, SessionState(status: SessionStatus.guest, failure: suspended));
    await cubit.close();
  });
}
