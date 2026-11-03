import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Size-limited disk cache for every network image in the app (feed images,
/// PDF page renders, covers, avatars). Uploaded media URLs are immutable, so
/// entries only need to expire to bound disk usage.
class MediaCacheManager extends CacheManager with ImageCacheManager {
  MediaCacheManager._() : super(Config(key, stalePeriod: stalePeriod, maxNrOfCacheObjects: maxObjects));

  static const key = 'readinMediaCache';

  /// Feed variants are ≤ ~150 KB and PDF thumbs smaller, so 400 objects keep
  /// the cache around 40–60 MB.
  static const maxObjects = 400;
  static const stalePeriod = Duration(days: 14);

  static MediaCacheManager? _instance;

  /// Created lazily on first use (it touches the file system and sqlite).
  static MediaCacheManager get instance => _instance ??= MediaCacheManager._();

  /// Registers the cache once for the whole app, including widgets that use
  /// `CachedNetworkImageProvider` without passing a cache manager.
  static void register() => CachedNetworkImageProvider.defaultCacheManager = instance;
}
