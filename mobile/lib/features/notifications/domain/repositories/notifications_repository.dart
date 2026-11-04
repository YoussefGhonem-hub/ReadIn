import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../entities/app_notification.dart';
import '../entities/notification_settings.dart';

/// The notification center and its settings (F17). Every call needs a signed-in user.
abstract interface class NotificationsRepository {
  /// `GET /me/notifications?cursor=&limit=`: newest activity first.
  Future<Result<CursorPage<AppNotification>>> list({String? cursor, int limit = 20});

  /// `GET /me/notifications/unread-count`: the badge when the Realtime Database is unavailable.
  Future<Result<int>> unreadCount();

  /// `POST /me/notifications/seen`: the center was opened, the badge goes to 0. Items stay unread.
  Future<Result<void>> markSeen();

  /// `POST /me/notifications/{id}/read`: idempotent; `404 notification.not_found`.
  Future<Result<void>> markRead(String id);

  /// `POST /me/notifications/read-all`.
  Future<Result<void>> markAllRead();

  /// `GET /me/notification-settings`.
  Future<Result<NotificationSettings>> getSettings();

  /// `PUT /me/notification-settings`: `400 notification.type_invalid`, `notification.mode_invalid`,
  /// `notification.quiet_hours_invalid`.
  Future<Result<void>> updateSettings(NotificationSettings settings);
}
