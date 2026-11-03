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

/// Maps a push link to an in-app route (SPEC §21.1). Deep links
/// (`readin://a/{slug}#comment-{id}`), App Links (`https://readin.app/a/{slug}`,
/// `https://readin.app/ar/a/{slug}`), profiles (`readin://u/{username}`, `https://readin.app/@{username}`) and app
/// paths open the matching screen;
/// anything else returns null, so a push can never open an arbitrary location.
String? pushLinkToPath(String? link) {
  final text = link?.trim() ?? '';
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri == null) return null;

  final List<String> segments;
  if (uri.scheme == 'readin') {
    segments = [uri.host, ...uri.pathSegments];
  } else if (uri.scheme == 'https' && uri.host == 'readin.app') {
    segments = uri.pathSegments;
  } else if (!uri.hasScheme && !uri.hasAuthority && text.startsWith('/')) {
    segments = uri.pathSegments;
  } else {
    return null;
  }

  var parts = segments.where((s) => s.isNotEmpty).toList();
  // Web article URLs carry the article language: /ar/a/{slug}, /en/a/{slug}.
  if (parts.length == 3 && (parts[0] == 'ar' || parts[0] == 'en') && parts[1] == 'a') parts = parts.sublist(1);
  if (parts.length == 2 && parts[0] == 'a') return '/a/${Uri.encodeComponent(parts[1])}';
  if (parts.length == 1 && parts[0] == 'notifications') return '/notifications';
  // Profiles (F14): the app's /u/{username} and the web's /@{username} (e.g. a "new follower" push).
  if (parts.length == 2 && parts[0] == 'u' && _isHandle(parts[1])) return '/u/${parts[1].toLowerCase()}';
  if (parts.length == 1 && parts[0].startsWith('@') && _isHandle(parts[0].substring(1))) {
    return '/u/${parts[0].substring(1).toLowerCase()}';
  }
  return null;
}

final _handle = RegExp(r'^[A-Za-z0-9_.]{1,30}$');

bool _isHandle(String value) => _handle.hasMatch(value);
