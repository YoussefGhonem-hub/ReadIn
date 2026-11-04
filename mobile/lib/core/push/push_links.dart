import '../config/app_links.dart';

/// `data.type` of the daily-article push (SPEC F07, docs/api/contract-v1.md).
const dailyArticlePushType = 'daily_article';

/// The link a push opens: its `data.link`, or for a daily-article push without
/// one, the reader of its `data.slug`. Null when the push opens nothing specific.
String? pushDataLink(Map<String, dynamic> data) {
  final link = data['link'];
  if (link is String && link.trim().isNotEmpty) return link.trim();
  final slug = data['slug'];
  if (data['type'] == dailyArticlePushType && slug is String && slug.trim().isNotEmpty) {
    return 'readin://a/${Uri.encodeComponent(slug.trim())}';
  }
  return null;
}

/// The notification a push is about (`data.notificationId`, F17): opening the push marks it read.
String? pushNotificationId(Map<String, dynamic> data) {
  final id = data['notificationId'];
  return id is String && id.trim().isNotEmpty ? id.trim() : null;
}

/// Maps a push or notification link to an in-app route (SPEC §21.1, F17). Deep links
/// (`readin://a/{slug}#comment-{id}`, which keeps the comment anchor), the web's article links
/// (`https://{domain}/ar/a/{slug}`, `/en/a/{slug}`, opened in that version; [AppLinks.webHost] only), profiles
/// (`readin://u/{username}`, `https://{domain}/@{username}`) and their followers (`readin://u/{username}/followers`), the own reading stats
/// (`readin://me/stats`), the account settings (`readin://settings/account`), writer verification
/// (`readin://verification`, F19), the notification center and app paths open the matching screen; anything else
/// returns null, so a push can never open an arbitrary location.
String? pushLinkToPath(String? link) {
  final text = link?.trim() ?? '';
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri == null) return null;

  final List<String> segments;
  if (uri.scheme == 'readin') {
    segments = [uri.host, ...uri.pathSegments];
  } else if (uri.scheme == 'https' && uri.host == AppLinks.webHost) {
    segments = uri.pathSegments;
  } else if (!uri.hasScheme && !uri.hasAuthority && text.startsWith('/')) {
    segments = uri.pathSegments;
  } else {
    return null;
  }

  final parts = segments.where((s) => s.isNotEmpty).toList();
  // Web article URLs carry the article language: /ar/a/{slug}, /en/a/{slug} (F24).
  if (_webArticle(parts, uri.fragment) case final path?) return path;
  if (parts.length == 2 && parts[0] == 'a') return _article(parts[1], fragment: uri.fragment);
  if (parts.length == 1 && parts[0] == 'notifications') return '/notifications';
  // Profiles (F14): the app's /u/{username} and the web's /@{username} (e.g. a "new follower" push), and a profile's
  // followers (several new followers, F17).
  if (parts.length == 2 && parts[0] == 'u' && _isHandle(parts[1])) return '/u/${parts[1].toLowerCase()}';
  if (parts.length == 3 && parts[0] == 'u' && _isHandle(parts[1]) && parts[2] == 'followers') {
    return '/u/${parts[1].toLowerCase()}/followers';
  }
  if (parts.length == 1 && parts[0].startsWith('@') && _isHandle(parts[0].substring(1))) {
    return '/u/${parts[0].substring(1).toLowerCase()}';
  }
  // The streak reminder and security alerts (F17).
  if (parts.length == 2 && parts[0] == 'me' && parts[1] == 'stats') return '/me/stats';
  if (parts.length == 2 && parts[0] == 'settings' && parts[1] == 'account') return '/settings?section=account';
  // A verification result (F19): the web's /verification is Settings → Writer verification here.
  if (parts.length == 1 && parts[0] == 'verification') return '/settings/verification';
  return null;
}

/// The app's route for a web article link, `/ar/a/{slug}` or `/en/a/{slug}`, which App Links and Universal Links hand to
/// the router (F24): `/a/{slug}?lang=ar-EG|en`, so the reader opens the version that was shared. Null for any other
/// path.
String? webArticleRoute(Uri uri) => _webArticle(uri.pathSegments.where((s) => s.isNotEmpty).toList(), uri.fragment);

String? _webArticle(List<String> parts, String fragment) {
  if (parts.length != 3 || parts[1] != 'a' || (parts[0] != 'ar' && parts[0] != 'en')) return null;
  return _article(parts[2], language: parts[0] == 'en' ? 'en' : 'ar-EG', fragment: fragment);
}

/// `/a/{slug}`, with `?lang=` when given and the anchor only when it is a comment's.
String _article(String slug, {String? language, required String fragment}) {
  final query = language == null ? '' : '?lang=$language';
  final anchor = _commentAnchor.hasMatch(fragment) ? '#$fragment' : '';
  return '/a/${Uri.encodeComponent(slug)}$query$anchor';
}

final _handle = RegExp(r'^[A-Za-z0-9_.]{1,30}$');

/// `comment-{id}`: the only anchor a link keeps.
final _commentAnchor = RegExp(r'^comment-[A-Za-z0-9-]{1,64}$');

bool _isHandle(String value) => _handle.hasMatch(value);
