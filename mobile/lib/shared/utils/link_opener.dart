import 'package:url_launcher/url_launcher.dart';

/// Opens http/https links in the external browser. Anything else is ignored
/// (RDoc links are restricted to http/https server-side as well).
Future<bool> openExternalLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Opens an https page of ReadIn's own site in the in-app browser (Custom Tabs / SFSafariViewController), e.g. the
/// legal pages (F37). Anything else is ignored. A test can replace it.
Future<bool> Function(String url) openInAppBrowser = _openInAppBrowser;

Future<bool> _openInAppBrowser(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;
  return launchUrl(uri, mode: LaunchMode.inAppBrowserView);
}
