import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../entities/app_notification.dart';
import '../entities/notification_settings.dart';
import '../repositories/notifications_repository.dart';

/// A page of the notification center (F17), newest activity first.
@injectable
class GetNotifications {
  const GetNotifications(this._repository);

  final NotificationsRepository _repository;

  static const pageSize = 20;

  Future<Result<CursorPage<AppNotification>>> call({String? cursor}) => _repository.list(cursor: cursor, limit: pageSize);
}

/// The bell's count when the Realtime Database is unavailable.
@injectable
class GetUnreadNotificationCount {
  const GetUnreadNotificationCount(this._repository);

  final NotificationsRepository _repository;

  Future<Result<int>> call() => _repository.unreadCount();
}

/// The center was opened: the badge goes to 0 (items stay unread until opened).
@injectable
class MarkNotificationsSeen {
  const MarkNotificationsSeen(this._repository);

  final NotificationsRepository _repository;

  Future<Result<void>> call() => _repository.markSeen();
}

/// A notification was opened, in the center or from its push.
@injectable
class MarkNotificationRead {
  const MarkNotificationRead(this._repository);

  final NotificationsRepository _repository;

  Future<Result<void>> call(String id) => _repository.markRead(id);
}

@injectable
class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);

  final NotificationsRepository _repository;

  Future<Result<void>> call() => _repository.markAllRead();
}

@injectable
class GetNotificationSettings {
  const GetNotificationSettings(this._repository);

  final NotificationsRepository _repository;

  Future<Result<NotificationSettings>> call() => _repository.getSettings();
}

/// Saves the whole settings. Quiet hours that aren't two different `HH:mm` times are refused here with the API's
/// `notification.quiet_hours_invalid`, without a request.
@injectable
class UpdateNotificationSettings {
  const UpdateNotificationSettings(this._repository);

  final NotificationsRepository _repository;

  static const quietHoursInvalid = Failure(FailureCodes.notificationQuietHoursInvalid, statusCode: 400);

  Future<Result<void>> call(NotificationSettings settings) async {
    if (!settings.quietHours.isValid) return const Err(quietHoursInvalid);
    return _repository.updateSettings(settings);
  }
}

/// The device-only "daily article notification" switch of earlier versions became the server's `daily_article` mode
/// (F17). Its stored value is moved to the signed-in account once: turned off, the account's `daily_article` becomes
/// `off` (unless it already keeps pushes away); turned on is the server default. The device value is dropped once
/// that is done; a failed call leaves it for the next sign in or start.
@injectable
class MigrateDailyArticleSwitch {
  const MigrateDailyArticleSwitch(this._settings, this._notifications);

  final SettingsRepository _settings;
  final NotificationsRepository _notifications;

  /// True when there is nothing left to move.
  Future<bool> call() async {
    final enabled = _settings.legacyDailyNotifications();
    if (enabled == null) return true;
    if (!enabled) {
      final current = (await _notifications.getSettings()).valueOrNull;
      if (current == null) return false;
      if (current.modeOf(NotificationType.dailyArticle) == NotificationMode.all) {
        final saved = await _notifications.updateSettings(current.withMode(NotificationType.dailyArticle, NotificationMode.off));
        if (!saved.isOk) return false;
      }
    }
    await _settings.clearLegacyDailyNotifications();
    return true;
  }
}
