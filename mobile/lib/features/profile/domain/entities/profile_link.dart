import 'package:equatable/equatable.dart';

/// A profile link's platform (SPEC F14, `ProfileLinkDto.platform`). The wire name is [name], lower case.
enum LinkPlatform {
  linkedin('LinkedIn', ['linkedin.com', 'lnkd.in']),
  x('X', ['x.com', 'twitter.com']),
  instagram('Instagram', ['instagram.com', 'instagr.am']),
  facebook('Facebook', ['facebook.com', 'fb.com', 'fb.me']),
  youtube('YouTube', ['youtube.com', 'youtu.be']),
  tiktok('TikTok', ['tiktok.com']),
  snapchat('Snapchat', ['snapchat.com']),
  threads('Threads', ['threads.net', 'threads.com']),
  telegram('Telegram', ['t.me', 'telegram.me']),
  github('GitHub', ['github.com']),
  medium('Medium', ['medium.com']),
  behance('Behance', ['behance.net']),

  /// Any https site; its name is translated ("الموقع" / "Website").
  website(null, []),

  /// Any https site, with the member's own label; the only platform that may repeat.
  other(null, []);

  const LinkPlatform(this.brandName, this.hosts);

  /// The brand's own name, the same in both languages; null for [website] and [other].
  final String? brandName;

  /// The hosts a link of this platform must be on (the host itself or a subdomain); empty = any host.
  final List<String> hosts;

  String get wire => name;

  /// Null for a platform this app version doesn't know.
  static LinkPlatform? fromWire(Object? wire) => values.where((platform) => platform.name == wire).firstOrNull;

  /// [host] is one of [hosts] or a subdomain of one; always true for [website] and [other].
  bool allowsHost(String host) {
    if (hosts.isEmpty) return true;
    final h = host.toLowerCase().replaceAll(RegExp(r'\.+$'), '');
    return hosts.any((allowed) => h == allowed || h.endsWith('.$allowed'));
  }
}

/// One social link on a profile (`ProfileLinkDto` `{ platform, url, label }`), in the member's order.
class ProfileLink extends Equatable {
  const ProfileLink({required this.platform, required this.url, this.label});

  final LinkPlatform platform;

  /// Normalized by the server (`https://` added).
  final String url;

  /// [LinkPlatform.other] only: the member's name for it (2–30 characters).
  final String? label;

  @override
  List<Object?> get props => [platform, url, label];
}

/// The client-side copy of the server's link rules (contract "Title and social links"), so the editor shows the same
/// error under each field before saving. Codes are keyed like the API's `errors`: `links`, `links[2].url`.
abstract final class ProfileLinkRules {
  static const maxLinks = 8;
  static const maxUrlLength = 500;
  static const minLabelLength = 2;
  static const maxLabelLength = 30;

  static const tooMany = 'link.too_many';
  static const platformInvalid = 'link.platform_invalid';
  static const duplicatePlatform = 'link.duplicate_platform';
  static const urlRequired = 'validation.required';
  static const tooLong = 'link.too_long';
  static const httpsRequired = 'link.https_required';
  static const urlInvalid = 'link.url_invalid';
  static const hostMismatch = 'link.host_mismatch';
  static const labelRequired = 'link.label_required';
  static const labelInvalid = 'link.label_invalid';
  static const labelNotAllowed = 'link.label_not_allowed';

  static String key(int index, String part) => 'links[$index].$part';

  /// Trimmed, with `https://` added when there is no scheme (`instagram.com/mona` → `https://instagram.com/mona`);
  /// empty stays empty.
  static String normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed.contains('://')) return trimmed;
    return 'https://$trimmed';
  }

  /// The code [url] (already normalized) breaks for [platform], or null.
  static String? urlProblem(LinkPlatform platform, String url) {
    if (url.isEmpty) return urlRequired;
    if (url.length > maxUrlLength) return tooLong;
    final scheme = url.substring(0, url.indexOf('://'));
    if (scheme.toLowerCase() != 'https') return httpsRequired;
    if (url.runes.any(_isSpaceOrControl)) return urlInvalid;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute || uri.scheme.toLowerCase() != 'https') return urlInvalid;
    if (uri.userInfo.isNotEmpty || (uri.hasPort && uri.port != 443)) return urlInvalid;
    // Dart percent-encodes a non-ASCII (IDN) host; the server checks its IDN form, so read it back as letters.
    final host = Uri.decodeComponent(uri.host).replaceAll(RegExp(r'\.+$'), '');
    if (host.isEmpty || !host.contains('.') || _isIp(host) || !_dnsHost.hasMatch(host)) return urlInvalid;
    return platform.allowsHost(host) ? null : hostMismatch;
  }

  /// The code [label] breaks for [platform], or null. [label] is trimmed first; blank counts as none.
  static String? labelProblem(LinkPlatform platform, String? label) {
    final value = label?.trim() ?? '';
    if (platform != LinkPlatform.other) return value.isEmpty ? null : labelNotAllowed;
    if (value.isEmpty) return labelRequired;
    if (value.length < minLabelLength || value.length > maxLabelLength || !isOneCleanLine(value)) return labelInvalid;
    return null;
  }

  /// Every rule over the whole list, in the server's order: field key → code. Empty when the list can be saved.
  static Map<String, String> check(List<ProfileLink> links) {
    final errors = <String, String>{};
    if (links.length > maxLinks) errors['links'] = tooMany;
    final seen = <LinkPlatform>{};
    for (final (i, link) in links.indexed) {
      if (link.platform != LinkPlatform.other && !seen.add(link.platform)) errors[key(i, 'platform')] = duplicatePlatform;
      if (urlProblem(link.platform, normalizeUrl(link.url)) case final code?) errors[key(i, 'url')] = code;
      if (labelProblem(link.platform, link.label) case final code?) errors[key(i, 'label')] = code;
    }
    return errors;
  }

  /// No line breaks, tabs or other control characters, no direction marks, overrides or isolates (titles and link
  /// labels; the app isolates them itself, SPEC §14.2).
  static bool isOneCleanLine(String text) => !text.runes.any(_isForbidden);

  static bool _isForbidden(int c) =>
      c <= 0x1F ||
      (c >= 0x7F && c <= 0x9F) ||
      c == 0x2028 ||
      c == 0x2029 ||
      c == 0x200E ||
      c == 0x200F ||
      (c >= 0x202A && c <= 0x202E) ||
      (c >= 0x2066 && c <= 0x2069);

  static bool _isSpaceOrControl(int c) => c <= 0x20 || (c >= 0x7F && c <= 0x9F) || c == 0xA0 || c == 0x2028 || c == 0x2029;

  static final _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

  /// Letters (any script), digits, `-` and dots: a DNS name, not `[::1]` or `a_b`.
  static final _dnsHost = RegExp(r'^[\p{L}\p{N}](?:[\p{L}\p{N}-]*[\p{L}\p{N}])?(?:\.[\p{L}\p{N}](?:[\p{L}\p{N}-]*[\p{L}\p{N}])?)+$', unicode: true);

  static bool _isIp(String host) => _ipv4.hasMatch(host) || host.contains(':') || host.startsWith('[');
}

/// The writer's title (`headline`, "المسمى", SPEC F14): optional, one line, at most [maxLength] characters.
abstract final class HeadlineRules {
  static const maxLength = 120;

  static const tooLong = 'profile.headline_too_long';
  static const invalid = 'profile.headline_invalid';

  /// The counter shows in the last 20 characters.
  static const counterWithin = 20;

  /// Trimmed; blank → null.
  static String? normalize(String? headline) {
    final value = headline?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  /// The code a title breaks, or null.
  static String? problem(String? headline) {
    final value = normalize(headline);
    if (value == null) return null;
    if (value.length > maxLength) return tooLong;
    return ProfileLinkRules.isOneCleanLine(value) ? null : invalid;
  }
}
