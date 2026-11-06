import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../core/config/app_config.dart';

/// Size-limited disk cache for every network image in the app (feed images,
/// PDF page renders, covers, avatars). Uploaded media URLs are immutable, so
/// entries only need to expire to bound disk usage.
class MediaCacheManager extends CacheManager with ImageCacheManager {
  MediaCacheManager._()
    : super(Config(key, stalePeriod: stalePeriod, maxNrOfCacheObjects: maxObjects, fileService: _MediaFileService()));

  static const key = 'readinMediaCache';

  /// Feed variants are ≤ ~150 KB and PDF thumbs smaller, so 400 objects keep
  /// the cache around 40–60 MB.
  static const maxObjects = 400;
  static const stalePeriod = Duration(days: 14);

  static MediaCacheManager? _instance;

  /// Where a dev build fetches uploads the API names on `localhost` (see [fetchUrl]); null in production.
  static String? _apiHost;

  /// Created lazily on first use (it touches the file system and sqlite).
  static MediaCacheManager get instance => _instance ??= MediaCacheManager._();

  /// Registers the cache once for the whole app, including widgets that use
  /// `CachedNetworkImageProvider` without passing a cache manager.
  static void register([AppConfig? config]) {
    _apiHost = config == null ? null : devApiHost(config);
    CachedNetworkImageProvider.defaultCacheManager = instance;
  }

  /// The local API's host for a dev build that does not reach it on `localhost` (`10.0.2.2` on the Android
  /// emulator, the computer's address on a phone); null otherwise.
  static String? devApiHost(AppConfig config) {
    if (config.flavor != Flavor.dev) return null;
    final host = Uri.tryParse(config.apiBaseUrl)?.host;
    return host == null || host.isEmpty || _loopback.contains(host) ? null : host;
  }

  static const _loopback = {'localhost', '127.0.0.1'};

  /// [url] as this device can fetch it. The dev API names uploads on `http://localhost:5080`
  /// (`Storage:PublicBaseUrl`), which on the emulator or a phone is the device itself: those come from [apiHost]
  /// instead. Anything else is unchanged. The cache still keys the image by [url].
  static String fetchUrl(String url, {required String? apiHost}) {
    if (apiHost == null) return url;
    final uri = Uri.tryParse(url);
    if (uri == null || !_loopback.contains(uri.host)) return url;
    return uri.replace(host: apiHost).toString();
  }
}

class _MediaFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) =>
      super.get(MediaCacheManager.fetchUrl(url, apiHost: MediaCacheManager._apiHost), headers: headers);
}
