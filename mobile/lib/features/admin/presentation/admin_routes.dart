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
}
