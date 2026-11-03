import 'package:url_launcher/url_launcher.dart';

/// Opens http/https links in the external browser. Anything else is ignored
/// (RDoc links are restricted to http/https server-side as well).
Future<bool> openExternalLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
