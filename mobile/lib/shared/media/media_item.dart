import 'package:equatable/equatable.dart';

/// One rendition of an image: a WebP variant or a PDF page thumb/view.
class ImageSource extends Equatable {
  const ImageSource({required this.width, required this.height, required this.url});

  final int width;
  final int height;
  final String url;

  @override
  List<Object?> get props => [width, height, url];
}

/// Picks the smallest source whose width covers [neededPx] (layout width ×
/// device pixel ratio), else the largest one. [sources] must be sorted by
/// ascending width (the API returns variants that way).
ImageSource pickSource(List<ImageSource> sources, double neededPx) {
  assert(sources.isNotEmpty, 'pickSource needs at least one source');
  for (final source in sources) {
    if (source.width >= neededPx) return source;
  }
  return sources.last;
}

/// A slide in the carousel / full-screen viewer: an image or a PDF page.
class MediaItem extends Equatable {
  const MediaItem({
    required this.sources,
    required this.width,
    required this.height,
    this.blurHash,
    this.caption,
    this.altText,
  });

  /// Ascending width.
  final List<ImageSource> sources;

  /// Intrinsic size (any unit), used for the aspect ratio.
  final int width;
  final int height;
  final String? blurHash;

  /// Optional one-line caption under image slides (`dir="auto"`).
  final String? caption;

  /// Screen-reader description (images).
  final String? altText;

  double get aspectRatio => width > 0 && height > 0 ? width / height : 1;

  bool get hasCaption => caption != null && caption!.trim().isNotEmpty;

  @override
  List<Object?> get props => [sources, width, height, blurHash, caption, altText];
}

/// Base83 alphabet used by BlurHash (https://blurha.sh).
const _base83 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#\$%*+,-.:;=?@[]^_{|}~';

/// True when [hash] is a structurally valid BlurHash: decoding an invalid one
/// throws asynchronously, so placeholders check first and fall back to a
/// plain token-colored box.
bool isValidBlurHash(String? hash) {
  if (hash == null || hash.length < 6) return false;
  for (final c in hash.split('')) {
    if (!_base83.contains(c)) return false;
  }
  final sizeFlag = _base83.indexOf(hash[0]);
  final numY = sizeFlag ~/ 9 + 1;
  final numX = sizeFlag % 9 + 1;
  return hash.length == 4 + 2 * numX * numY;
}
