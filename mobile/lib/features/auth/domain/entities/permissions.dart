import 'me.dart';

/// Permission names in `MeDto.permissions` (SPEC §10.2). Clients only hide what the API refuses anyway.
abstract final class Permissions {
  /// Report articles, comments and users (Member and up, F22).
  static const reportsCreate = 'reports.create';

  /// The moderation queue, hide / unhide / delete content, warn users (Moderator, Admin, SuperAdmin; F22).
  static const moderationManage = 'moderation.manage';

  /// Suspend and unsuspend accounts (F22).
  static const usersSuspend = 'users.suspend';
}

extension MePermissions on Me {
  /// Sees the moderation tools: Settings → Moderation, hide / unhide, warn.
  bool get isModerator => can(Permissions.moderationManage);

  /// Can suspend and unsuspend accounts.
  bool get canSuspend => can(Permissions.usersSuspend);
}
