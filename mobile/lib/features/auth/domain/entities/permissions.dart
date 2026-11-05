import 'me.dart';

/// Permission names in `MeDto.permissions` (SPEC §10.2). Clients only hide what the API refuses anyway.
///
/// The app gates on these, never on a role name in `MeDto.roles` (`Member` or `SuperAdmin` today; a staff role with
/// some of these permissions may come later), and shows the Verified badge from `isVerified`, which isn't a role.
abstract final class Permissions {
  /// Write articles, and group them into writer categories (every Member, F05, F31).
  static const articlesCreate = 'articles.create';

  /// Report articles, comments and users (every Member, F22).
  static const reportsCreate = 'reports.create';

  /// The moderation queue, hide / unhide / delete content, warn users (holders of the permission: today the
  /// SuperAdmin; F22).
  static const moderationManage = 'moderation.manage';

  /// Suspend and unsuspend accounts (holders of the permission: today the SuperAdmin; F22).
  static const usersSuspend = 'users.suspend';
}

extension MePermissions on Me {
  /// Writes articles and manages their own writer categories (`GET /me/categories` needs it).
  bool get canWrite => can(Permissions.articlesCreate);

  /// Sees the moderation tools: Settings → Moderation, hide / unhide, warn.
  bool get isModerator => can(Permissions.moderationManage);

  /// Can suspend and unsuspend accounts.
  bool get canSuspend => can(Permissions.usersSuspend);
}
