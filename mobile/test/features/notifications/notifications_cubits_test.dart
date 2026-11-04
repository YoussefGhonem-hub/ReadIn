import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/platform/time_zone_service.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/notifications/domain/entities/app_notification.dart';
import 'package:readin/features/notifications/domain/entities/notification_settings.dart';
import 'package:readin/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:readin/features/notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:readin/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/settings/data/datasources/preferences_api.dart';
import 'package:readin/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:readin/features/settings/data/repositories/settings_repository_impl.dart';

import '../../helpers/notification_fixtures.dart';

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

const offline = Failure(FailureCodes.networkOffline);

void main() {
  late FakeNotificationsRepository repository;
  late MockUnreadBadgeCubit badge;

  setUp(() {
    repository = FakeNotificationsRepository(items: mixedNotifications);
    badge = MockUnreadBadgeCubit();
  });

  NotificationsCubit center() => NotificationsCubit(
        GetNotifications(repository),
        MarkNotificationsSeen(repository),
        MarkNotificationRead(repository),
        MarkAllNotificationsRead(repository),
        badge,
      );

  List<bool> readFlags(NotificationsCubit cubit) => [for (final n in cubit.state.items) n.isRead];

  group('NotificationsCubit', () {
    test('opening marks everything seen (the badge clears) and loads the first page', () async {
      final cubit = center();
      await cubit.open();
      expect(repository.calls, ['seen', 'list -']);
      verify(badge.clear).called(1);
      expect(cubit.state.status, NotificationsStatus.ready);
      expect(cubit.state.items, mixedNotifications);
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.hasUnread, isTrue);
    });

    test('pages with the cursor, never listing a row twice, and keeps a failed page retryable', () async {
      repository.pageSize = 4;
      final cubit = center();
      await cubit.open();
      expect(cubit.state.items.length, 4);
      expect(cubit.state.nextCursor, '4');

      // A row of the first page moved down with new activity: it isn't listed twice.
      repository.items = [...mixedNotifications.sublist(0, 4), mixedNotifications[0], ...mixedNotifications.sublist(4)];
      await cubit.loadMore();
      expect(repository.calls.last, 'list 4');
      expect(cubit.state.items.map((n) => n.id), [for (final n in mixedNotifications.sublist(0, 7)) n.id]);

      repository.listFailure = offline;
      await cubit.loadMore();
      expect(cubit.state.loadMoreFailure, offline);
      expect(cubit.state.items.length, 7, reason: 'the list stays');

      repository.listFailure = null;
      await cubit.loadMore();
      expect(cubit.state.loadMoreFailure, isNull);
      expect(cubit.state.items.length, mixedNotifications.length);
      expect(cubit.state.hasMore, isFalse);

      await cubit.loadMore();
      expect(repository.calls.where((c) => c.startsWith('list')).length, 4, reason: 'nothing more to load');
    });

    test('a failed first load shows the error; a failed refresh keeps the list and returns the failure', () async {
      repository.listFailure = offline;
      final cubit = center();
      await cubit.open();
      expect((cubit.state.status, cubit.state.failure), (NotificationsStatus.failure, offline));

      repository.listFailure = null;
      expect(await cubit.refresh(), isNull);
      expect(cubit.state.status, NotificationsStatus.ready);

      repository.listFailure = offline;
      expect(await cubit.refresh(), offline);
      expect(cubit.state.status, NotificationsStatus.ready);
      expect(cubit.state.items, mixedNotifications);
    });

    test('pull to refresh marks what arrived since seen too', () async {
      final cubit = center();
      await cubit.open();
      repository.calls.clear();
      await cubit.refresh();
      expect(repository.calls, ['seen', 'list -']);
      verify(badge.clear).called(2);
    });

    test('opening a row marks it read at once; it turns unread again only if the request fails', () async {
      final cubit = center();
      await cubit.open();
      final reply = cubit.state.items.first;

      await cubit.markRead(reply);
      expect(repository.calls.last, 'read n-reply');
      expect(cubit.state.items.first.isRead, isTrue);

      // Already read: no request.
      await cubit.markRead(cubit.state.items.first);
      expect(repository.calls.where((c) => c == 'read n-reply').length, 1);

      repository.readFailure = offline;
      await cubit.markRead(cubit.state.items[1]);
      expect(cubit.state.items[1].isRead, isFalse);

      // Gone on the server: stays read here.
      repository.readFailure = const Failure(FailureCodes.notificationNotFound, statusCode: 404);
      await cubit.markRead(cubit.state.items[3]);
      expect(cubit.state.items[3].isRead, isTrue);
    });

    test('"Mark all read" reads everything at once, and rolls back with the failure', () async {
      final cubit = center();
      await cubit.open();
      final before = readFlags(cubit);

      repository.readAllFailure = offline;
      expect(await cubit.markAllRead(), offline);
      expect(readFlags(cubit), before);

      repository.readAllFailure = null;
      expect(await cubit.markAllRead(), isNull);
      expect(repository.calls.last, 'read-all');
      expect(readFlags(cubit), everyElement(isTrue));
      expect(cubit.state.hasUnread, isFalse);

      repository.calls.clear();
      expect(await cubit.markAllRead(), isNull);
      expect(repository.calls, isEmpty, reason: 'nothing unread');
    });
  });

  group('NotificationSettingsCubit', () {
    NotificationSettingsCubit settingsCubit() =>
        NotificationSettingsCubit(GetNotificationSettings(repository), UpdateNotificationSettings(repository));

    test('loads, and a failed load can be retried', () async {
      repository.settingsFailure = offline;
      final cubit = settingsCubit();
      await cubit.load();
      expect((cubit.state.status, cubit.state.failure), (NotificationSettingsStatus.failure, offline));

      repository
        ..settingsFailure = null
        ..settings = const NotificationSettings(types: {NotificationType.mention: NotificationMode.inApp});
      await cubit.load();
      expect(cubit.state.status, NotificationSettingsStatus.ready);
      expect(cubit.state.modeOf(NotificationType.mention), NotificationMode.inApp);
      expect(cubit.state.modeOf(NotificationType.newFollower), NotificationMode.all);
    });

    test('a mode change shows at once and saves the whole settings', () async {
      final cubit = settingsCubit();
      await cubit.load();
      final saving = cubit.setMode(NotificationType.streakReminder, NotificationMode.off);
      expect(cubit.state.modeOf(NotificationType.streakReminder), NotificationMode.off);
      expect(await saving, isNull);
      expect(repository.saved.single, const NotificationSettings(types: {NotificationType.streakReminder: NotificationMode.off}));
    });

    test('security alerts and other fixed types are never sent', () async {
      final cubit = settingsCubit();
      await cubit.load();
      expect(await cubit.setMode(NotificationType.securityAlert, NotificationMode.off), isNull);
      expect(await cubit.setMode(NotificationType.moderationNotice, NotificationMode.off), isNull);
      expect(repository.saved, isEmpty);
    });

    test('quiet hours: switch and times', () async {
      final cubit = settingsCubit();
      await cubit.load();
      await cubit.setQuietHoursEnabled(false);
      await cubit.setQuietHours(start: '22:00');
      await cubit.setQuietHours(end: '06:30');
      expect(repository.saved.last.quietHours, const QuietHours(enabled: false, start: '22:00', end: '06:30'));
      expect(cubit.state.settings!.quietHours, const QuietHours(enabled: false, start: '22:00', end: '06:30'));
    });

    test('the same start and end are refused here, with no request, and the screen goes back', () async {
      final cubit = settingsCubit();
      await cubit.load();
      final failure = await cubit.setQuietHours(start: '07:00');
      expect(failure?.code, FailureCodes.notificationQuietHoursInvalid);
      expect(repository.saved, isEmpty);
      expect(cubit.state.settings!.quietHours, const QuietHours());
    });

    for (final code in [
      FailureCodes.notificationTypeInvalid,
      FailureCodes.notificationModeInvalid,
      FailureCodes.notificationQuietHoursInvalid,
    ]) {
      test('a save the API refuses ($code) puts the saved settings back and returns the failure', () async {
        final cubit = settingsCubit();
        await cubit.load();
        await cubit.setMode(NotificationType.mention, NotificationMode.inApp);
        repository.updateFailure = Failure(code, statusCode: 400);
        final failure = await cubit.setMode(NotificationType.newFollower, NotificationMode.off);
        expect(failure?.code, code);
        expect(cubit.state.modeOf(NotificationType.newFollower), NotificationMode.all);
        expect(cubit.state.modeOf(NotificationType.mention), NotificationMode.inApp, reason: 'the earlier save stays');
      });
    }

    test('changes are saved one after another, and only the latest decides what the screen shows', () async {
      final cubit = settingsCubit();
      await cubit.load();
      repository.updateFailure = offline;
      final first = cubit.setMode(NotificationType.mention, NotificationMode.off);
      final second = cubit.setMode(NotificationType.newFollower, NotificationMode.inApp);
      expect(await first, offline);
      expect(cubit.state.modeOf(NotificationType.newFollower), NotificationMode.inApp, reason: 'the second is still on its way');
      expect(await second, offline);
      expect(cubit.state.settings, const NotificationSettings());
      expect(repository.saved.length, 2);
    });
  });

  group('MigrateDailyArticleSwitch', () {
    late InMemoryKeyValueStore store;
    late SettingsRepositoryImpl settings;

    setUp(() {
      store = InMemoryKeyValueStore();
      settings = SettingsRepositoryImpl(SettingsLocalDataSource(store), _NoPreferencesApi(), _NoTimeZone());
    });

    MigrateDailyArticleSwitch migrate() => MigrateDailyArticleSwitch(settings, repository);

    test('nothing stored: nothing to do', () async {
      expect(await migrate()(), isTrue);
      expect(repository.calls, isEmpty);
    });

    test('left on: the server default already matches, the device value is dropped', () async {
      await store.write(SettingsLocalDataSource.legacyDailyNotificationsKey, true);
      expect(await migrate()(), isTrue);
      expect(repository.calls, isEmpty);
      expect(store.read<bool>(SettingsLocalDataSource.legacyDailyNotificationsKey), isNull);
    });

    test('turned off: daily_article becomes off on the account, keeping the rest, then the device value is dropped', () async {
      await store.write(SettingsLocalDataSource.legacyDailyNotificationsKey, false);
      repository.settings = const NotificationSettings(
        quietHours: QuietHours(start: '22:00', end: '06:00'),
        types: {NotificationType.mention: NotificationMode.inApp},
      );
      expect(await migrate()(), isTrue);
      expect(repository.saved.single, const NotificationSettings(
        quietHours: QuietHours(start: '22:00', end: '06:00'),
        types: {NotificationType.mention: NotificationMode.inApp, NotificationType.dailyArticle: NotificationMode.off},
      ));
      expect(store.read<bool>(SettingsLocalDataSource.legacyDailyNotificationsKey), isNull);
      expect(await migrate()(), isTrue, reason: 'once');
      expect(repository.saved.length, 1);
    });

    test('turned off, and the account already keeps the daily push away: nothing to save', () async {
      await store.write(SettingsLocalDataSource.legacyDailyNotificationsKey, false);
      repository.settings = const NotificationSettings(types: {NotificationType.dailyArticle: NotificationMode.inApp});
      expect(await migrate()(), isTrue);
      expect(repository.saved, isEmpty);
      expect(store.read<bool>(SettingsLocalDataSource.legacyDailyNotificationsKey), isNull);
    });

    test('offline: the device value stays for the next try', () async {
      await store.write(SettingsLocalDataSource.legacyDailyNotificationsKey, false);
      repository.settingsFailure = offline;
      expect(await migrate()(), isFalse);
      expect(store.read<bool>(SettingsLocalDataSource.legacyDailyNotificationsKey), isFalse);

      repository
        ..settingsFailure = null
        ..updateFailure = offline;
      expect(await migrate()(), isFalse);
      expect(store.read<bool>(SettingsLocalDataSource.legacyDailyNotificationsKey), isFalse);
    });

    test('the device settings no longer carry the switch', () async {
      await store.write(SettingsLocalDataSource.legacyDailyNotificationsKey, false);
      final local = SettingsLocalDataSource(store);
      await local.write(local.read());
      expect(store.read<bool>(SettingsLocalDataSource.legacyDailyNotificationsKey), isFalse, reason: 'only the move drops it');
    });
  });
}

class _NoPreferencesApi extends Fake implements PreferencesApi {}

class _NoTimeZone extends Fake implements TimeZoneService {}
