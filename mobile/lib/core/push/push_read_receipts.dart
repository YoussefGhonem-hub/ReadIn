/// Marks the notification of a tapped push read (F17, `POST /me/notifications/{id}/read`). The notifications feature
/// implements it; [PushService] calls it once the tapping account is signed in.
abstract interface class PushReadReceipts {
  /// Best effort: failures are swallowed (the item stays unread in the notification center).
  Future<void> markRead(String notificationId);
}
