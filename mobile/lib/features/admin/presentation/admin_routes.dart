import '../../auth/domain/entities/permissions.dart';
import '../../moderation/presentation/moderation_routes.dart';

/// Where the admin console lives in the app (F23): Settings / the More sheet → «لوحة التحكم» (`/admin`), with
/// Dashboard, Users, Content, Reports (the F22 queue), Tickets (F35) and Verification (F19). The other sections are web
/// only.
abstract final class AdminRoutes {
  static const home = '/admin';
  static const dashboard = '/admin/dashboard';
  static const users = '/admin/users';
  static const content = '/admin/content';
  static const tickets = '/admin/tickets';
  static const verification = '/admin/verification';

  /// Reports: the F22 moderation queue, as before.
  static const reports = ModerationRoutes.home;

  static String user(String id) => '$users/${Uri.encodeComponent(id)}';

  static String article(String id) => '$content/${Uri.encodeComponent(id)}';

  /// Content filtered to a dashboard period (local dates, both included).
  static String contentFor({required String from, required String to}) =>
      Uri(path: content, queryParameters: {'from': from, 'to': to}).toString();

  /// Content filtered to one writer's articles ("Their articles" on a user's page); [label] names the chip.
  static String contentForWriter(String writerId, {String? label}) =>
      Uri(path: content, queryParameters: {'writer': writerId, 'writerName': ?label}).toString();

  static String ticket(String id) => '$tickets/${Uri.encodeComponent(id)}';

  static String verificationRequest(String id) => '$verification/${Uri.encodeComponent(id)}';

  /// Whether [path] is a console route (they need an account; the pages check the permissions).
  static bool isConsole(String path) => path == home || path.startsWith('$home/');

  /// Whether [path] is a ticket of the console (`/admin/tickets/{id}`): without `support.manage` a push opens the
  /// notification center instead (F35).
  static bool isTicket(String path) => path.startsWith('$tickets/');

  /// The admin's bottom bar (holders of `admin.access`): its tabs are branches of the main shell, under `/console`.
  /// The app opens on [consoleDashboard] for them; Home (`/home`) is the app as a reader sees it.
  static const console = '/console';
  static const consoleDashboard = '$console/dashboard';
  static const consoleTickets = '$console/tickets';
  static const consoleUsers = '$console/users';
  static const consoleNotifications = '$console/notifications';

  /// Whether [path] is one of the admin bar's tabs.
  static bool isConsoleTab(String path) => path == console || path.startsWith('$console/');

  /// The permission a console tab needs besides `admin.access` (null for the dashboard and the notifications).
  static String? consoleTabPermission(String path) => switch (path) {
        consoleTickets => Permissions.supportManage,
        consoleUsers => Permissions.usersRead,
        _ => null,
      };
}
