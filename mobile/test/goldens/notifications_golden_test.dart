@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/notifications/domain/entities/app_notification.dart';
import 'package:readin/features/notifications/domain/entities/notification_settings.dart';
import 'package:readin/features/notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:readin/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:readin/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:readin/features/notifications/presentation/pages/notifications_page.dart';
import 'package:readin/features/notifications/presentation/widgets/notification_tile.dart';

import '../helpers/notification_fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/test_app.dart';

class MockNotificationsCubit extends MockCubit<NotificationsState> implements NotificationsCubit {}

class MockNotificationSettingsCubit extends MockCubit<NotificationSettingsState> implements NotificationSettingsCubit {}

/// The notification center and Settings → Notifications (F17), in ar/en × light/dark.
void main() {
  setUp(() => NotificationClock.now = () => notificationsNow);
  tearDown(() => NotificationClock.now = DateTime.now);

  for (final variant in Variant.all) {
    // Every kind of row: unread and read, aggregated ("Ahmed Samir and 9 others"), a deleted actor, an English article
    // in the Arabic UI and the other way round, comment excerpts, and the actorless types.
    testWidgets('notification center ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 1260));
      final cubit = MockNotificationsCubit()
        ..hold(NotificationsState(status: NotificationsStatus.ready, items: mixedNotifications));
      await tester.pumpWidget(testApp(BlocProvider<NotificationsCubit>.value(value: cubit, child: const NotificationsView()), variant: variant));
      await tester.pump();
      await expectLater(find.byType(NotificationsView), matchesVariantGolden(variant, 'goldens/notifications_center_${variant.name}.png'));
    });

    testWidgets('notification settings ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 1000));
      final cubit = MockNotificationSettingsCubit()
        ..hold(const NotificationSettingsState(
          status: NotificationSettingsStatus.ready,
          settings: NotificationSettings(
            types: {
              NotificationType.mention: NotificationMode.inApp,
              NotificationType.reactionsMilestone: NotificationMode.inApp,
              NotificationType.streakReminder: NotificationMode.off,
            },
          ),
        ));
      await tester.pumpWidget(testApp(
        BlocProvider<NotificationSettingsCubit>.value(value: cubit, child: const NotificationSettingsView()),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(
        find.byType(NotificationSettingsView),
        matchesVariantGolden(variant, 'goldens/notification_settings_${variant.name}.png'),
      );
    });
  }
}
