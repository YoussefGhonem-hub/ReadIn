import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_api.dart';
import '../models/notification_models.dart';

@LazySingleton(as: NotificationsRepository)
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._api);

  final NotificationsApi _api;

  @override
  Future<Result<CursorPage<AppNotification>>> list({String? cursor, int limit = 20}) => guardApi(() async {
        final page = await _api.list(cursor, limit);
        return CursorPage(items: [for (final item in page.items) item.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<int>> unreadCount() => guardApi(() async => (await _api.unreadCount()).unread);

  @override
  Future<Result<void>> markSeen() => guardApi(_api.markSeen);

  @override
  Future<Result<void>> markRead(String id) => guardApi(() => _api.markRead(Uri.encodeComponent(id)));

  @override
  Future<Result<void>> markAllRead() => guardApi(_api.markAllRead);

  @override
  Future<Result<NotificationSettings>> getSettings() => guardApi(() async => (await _api.settings()).toEntity());

  @override
  Future<Result<void>> updateSettings(NotificationSettings settings) =>
      guardApi(() => _api.updateSettings(NotificationSettingsModel.fromEntity(settings)));
}
