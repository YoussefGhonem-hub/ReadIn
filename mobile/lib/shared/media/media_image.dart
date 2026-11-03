import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens.g.dart';
import 'media_cache_manager.dart';
import 'media_item.dart';

/// Image loading seams. Production uses the size-limited disk cache and real
/// BlurHash decoding; tests swap in synchronous fakes so goldens are
/// deterministic (see test/helpers/fake_media.dart).
abstract final class MediaImages {
  static ImageProvider Function(String url) networkProvider =
      (url) => CachedNetworkImageProvider(url, cacheManager: MediaCacheManager.instance);

  /// Local files picked on the device (composer thumbnails), decoded small.
  static ImageProvider Function(String path, int cacheWidth) fileProvider =
      (path, cacheWidth) => ResizeImage(FileImage(File(path)), width: cacheWidth, policy: ResizeImagePolicy.fit);

  /// Placeholder shown while an image loads (or instead of it, off-screen).
  static Widget Function(BuildContext context, String? blurHash) placeholder = _blurHashPlaceholder;

  static Widget _blurHashPlaceholder(BuildContext context, String? blurHash) {
    final color = context.colors.surfaceVariant;
    if (!isValidBlurHash(blurHash)) return ColoredBox(color: color, child: const SizedBox.expand());
    return BlurHash(hash: blurHash!, color: color, imageFit: BoxFit.cover);
  }
}

/// Network image that loads the variant matching its laid-out width × device
/// pixel ratio (or the [largest] one for the full-screen viewer), over a
/// BlurHash placeholder, with a fade-in that respects reduce-motion.
///
/// When [load] is false only the placeholder is shown — carousels use this to
/// keep off-screen slides cheap on low-end phones.
class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    required this.sources,
    this.blurHash,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.largest = false,
    this.load = true,
    this.errorLabel,
  });

  final List<ImageSource> sources;
  final String? blurHash;
  final BoxFit fit;
  final String? semanticLabel;
  final bool largest;
  final bool load;
  final String? errorLabel;

  @override
  Widget build(BuildContext context) {
    final placeholder = MediaImages.placeholder(context, blurHash);
    if (!load || sources.isEmpty) {
      return Semantics(label: semanticLabel, image: semanticLabel != null, child: placeholder);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
        final source = largest ? sources.last : pickSource(sources, width * dpr);
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        final colors = context.colors;
        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            Image(
              image: MediaImages.networkProvider(source.url),
              fit: fit,
              semanticLabel: semanticLabel,
              excludeFromSemantics: semanticLabel == null,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: reduceMotion ? Duration.zero : ReadInMotion.slow,
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              errorBuilder: (context, error, stack) => Center(
                child: Icon(Icons.image_not_supported_outlined, color: colors.textSecondary, semanticLabel: errorLabel),
              ),
            ),
          ],
        );
      },
    );
  }
}
