import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';

class MockRealtimeService extends Mock implements RealtimeService {}

void main() {
  test('follows the live unread count and stops listening when closed', () async {
    final unread = ValueNotifier(2);
    final realtime = MockRealtimeService();
    when(() => realtime.unreadNotifications).thenReturn(unread);

    final cubit = UnreadBadgeCubit(realtime);
    expect(cubit.state, 2);

    unread.value = 5;
    expect(cubit.state, 5);

    await cubit.close();
    unread.value = 9;
    expect(cubit.state, 5);
  });
}
