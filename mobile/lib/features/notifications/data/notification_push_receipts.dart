import 'package:injectable/injectable.dart';

import '../../../core/push/push_read_receipts.dart';
import '../domain/usecases/notification_usecases.dart';

/// A tapped push marks its notification read (F17). Failures leave it unread in the notification center.
@LazySingleton(as: PushReadReceipts)
class NotificationPushReceipts implements PushReadReceipts {
  NotificationPushReceipts(this._markRead);

  final MarkNotificationRead _markRead;

  @override
  Future<void> markRead(String notificationId) async {
    await _markRead(notificationId);
  }
}
