/// Help & support in the app (F35): Settings → «المساعدة والدعم» (`/settings/support`), a new ticket, and a ticket's
/// page (`/settings/support/tickets/{id}`, where a `support_reply` push lands).
abstract final class SupportRoutes {
  static const home = '/settings/support';
  static const newTicket = '/settings/support/new';
  static const ticketsPrefix = '/settings/support/tickets';

  static String ticket(String id) => '$ticketsPrefix/${Uri.encodeComponent(id)}';

  /// The new-ticket form, remembering the screen the member came from (sent with the ticket).
  static String newTicketFrom(String? screen) =>
      screen == null || screen.isEmpty ? newTicket : Uri(path: newTicket, queryParameters: {'from': screen}).toString();

  /// `?from=` of [uri]: a route of the app (starts with `/`, at most 100 characters), else null.
  static String? fromOf(Uri uri) {
    final from = uri.queryParameters['from']?.trim() ?? '';
    if (!from.startsWith('/') || from.length > 100) return null;
    return from;
  }

  static bool isSupport(String path) => path == home || path.startsWith('$home/');
}
