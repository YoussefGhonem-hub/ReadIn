import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';

/// Network image with disk caching, a token-colored placeholder and a subtle
/// border in dark mode (SPEC §15.5 rule 5).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.semanticLabel,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.aspectRatio,
    this.errorLabel,
  });

  final String url;
  final String? semanticLabel;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? aspectRatio;
  final String? errorLabel;

  /// Test seam: widget tests swap in [NetworkImage] (no plugin/disk cache).
  static ImageProvider Function(String url) providerFactory = CachedNetworkImageProvider.new;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = borderRadius ?? BorderRadius.circular(12);
    Widget image = Image(
      image: providerFactory(url),
      fit: fit,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      frameBuilder: (context, child, frame, wasSync) =>
          frame == null && !wasSync ? ColoredBox(color: colors.surfaceVariant, child: const SizedBox.expand()) : child,
      errorBuilder: (context, error, stack) => ColoredBox(
        color: colors.surfaceVariant,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined, color: colors.textSecondary, semanticLabel: errorLabel),
        ),
      ),
    );
    if (aspectRatio != null) image = AspectRatio(aspectRatio: aspectRatio!, child: image);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: context.isDark ? Border.all(color: colors.border) : null,
      ),
      child: image,
    );
  }
}
