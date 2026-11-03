import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/app/live_session_bridge.dart';
import 'package:readin/core/push/push_service.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';

import '../helpers/fixtures.dart';

class MockSessionCubit extends MockCubit<SessionState> implements SessionCubit {}

class MockRealtimeService extends Mock implements RealtimeService {}

class MockPushService extends Mock implements PushService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('waits for the session, then follows sign-in and sign-out once each', () async {
    final session = MockSessionCubit();
    final realtime = MockRealtimeService();
    final push = MockPushService();
    when(() => realtime.followUser(any())).thenAnswer((_) async {});
    when(() => push.followUser(any())).thenAnswer((_) async {});
    whenListen(
      session,
      Stream.fromIterable(const [
        SessionState(status: SessionStatus.authenticated, me: sampleMe),
        SessionState(status: SessionStatus.authenticated, me: sampleMe), // same user again
        SessionState(status: SessionStatus.guest),
      ]),
      initialState: const SessionState(), // unknown: the persisted session isn't restored yet
    );

    final bridge = LiveSessionBridge(session, realtime, push)..start();
    await Future<void>.delayed(Duration.zero);

    verifyInOrder([() => realtime.followUser(sampleMe.id), () => realtime.followUser(null)]);
    verifyInOrder([() => push.followUser(sampleMe.id), () => push.followUser(null)]);
    verifyNoMoreInteractions(push);
    await bridge.dispose();
  });
}
