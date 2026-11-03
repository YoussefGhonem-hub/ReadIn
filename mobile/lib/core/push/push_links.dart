/// Maps a push link to an in-app route (SPEC §21.1). Deep links
/// (`readin://a/{slug}#comment-{id}`), App Links (`https://readin.app/a/{slug}`,
/// `https://readin.app/ar/a/{slug}`) and app paths open the matching screen;
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
  return null;
}
