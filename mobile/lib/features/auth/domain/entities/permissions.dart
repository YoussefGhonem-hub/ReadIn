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

  /// Highlight sentences in articles and remove your highlights (every Member, F30).
  static const highlightsCreate = 'highlights.create';

  /// The admin console and its dashboard (F23): the entry in Settings, the More sheet and the Me sheet.
  static const adminAccess = 'admin.access';

  /// The console's Users: list and open any account (F23); also suspended accounts' profiles.
  static const usersRead = 'users.read';

  /// See phone numbers: reveal one in the console (audited), search by number (F23).
  static const usersReadPii = 'users.read.pii';

  /// Reset an account's password (F23).
  static const usersResetPassword = 'users.reset_password';

  /// Feature articles on Explore (F23).
  static const articlesFeature = 'articles.feature';

  /// The verification queue and removing a Verified badge (F19, F23).
  static const verificationManage = 'verification.manage';

  /// Send and follow your own support tickets (every Member, F35).
  static const supportCreate = 'support.create';

  /// The console's ticket queue and the `support_ticket` notification (F35).
  static const supportManage = 'support.manage';
}

extension MePermissions on Me {
  /// Writes articles and manages their own writer categories (`GET /me/categories` needs it).
  bool get canWrite => can(Permissions.articlesCreate);

  /// Sees the moderation tools: Settings → Moderation, hide / unhide, warn.
  bool get isModerator => can(Permissions.moderationManage);

  /// Can suspend and unsuspend accounts.
  bool get canSuspend => can(Permissions.usersSuspend);

  /// Gets the reader's Highlight toolbar (F30).
  bool get canHighlight => can(Permissions.highlightsCreate);

  /// Sees the admin console's entry (F23). It replaces "Moderation" in Settings and the sheets; the queues are sections
  /// of the console.
  bool get isAdmin => can(Permissions.adminAccess);

  /// Sends and follows support tickets (F35).
  bool get canContactSupport => can(Permissions.supportCreate);

  /// Answers support tickets in the console (F35).
  bool get canManageSupport => can(Permissions.supportManage);

  /// Reviews writer verification requests and removes badges (F19).
  bool get canManageVerification => can(Permissions.verificationManage);

  /// Opens accounts in the console (F23).
  bool get canReadUsers => can(Permissions.usersRead);

  /// Features articles on Explore (F23).
  bool get canFeature => can(Permissions.articlesFeature);
}
