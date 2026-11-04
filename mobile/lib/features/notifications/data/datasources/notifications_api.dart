import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/notification_models.dart';

part 'notifications_api.g.dart';

/// The notification center and its settings (F17). Bearer only; reads are unthrottled, writes use the `writes` limit.
@lazySingleton
@RestApi()
abstract class NotificationsApi {
  @factoryMethod
  factory NotificationsApi(Dio dio) = _NotificationsApi;

  @GET('/me/notifications')
  Future<NotificationPageModel> list(@Query('cursor') String? cursor, @Query('limit') int limit);

  @GET('/me/notifications/unread-count')
  Future<UnreadCountModel> unreadCount();

  @POST('/me/notifications/seen')
  Future<void> markSeen();

  /// Retrofit doesn't encode path parameters: pass `Uri.encodeComponent(id)`.
  @POST('/me/notifications/{id}/read')
  Future<void> markRead(@Path('id') String id);

  @POST('/me/notifications/read-all')
  Future<void> markAllRead();

  @GET('/me/notification-settings')
  Future<NotificationSettingsModel> settings();

  @PUT('/me/notification-settings')
  Future<void> updateSettings(@Body() NotificationSettingsModel body);
}
