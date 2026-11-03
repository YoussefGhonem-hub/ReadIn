import '../../../shared/media/media_item.dart';
import '../domain/entities/media.dart';

/// Maps attachment entities to the shared carousel/viewer items.
abstract final class MediaItems {
  static MediaItem image(ImageAttachment a) => MediaItem(
        sources: [for (final v in a.variants) ImageSource(width: v.width, height: v.height, url: v.url)],
        width: a.width,
        height: a.height,
        blurHash: a.blurHash,
        caption: a.caption,
        altText: a.altText,
      );

  static ImageSource _thumb(MediaPage p) =>
      ImageSource(width: MediaPage.thumbWidth, height: (MediaPage.thumbWidth / p.aspectRatio).round(), url: p.thumbUrl);

  /// Feed / article slides: always the 400 px thumb.
  static MediaItem pageThumb(MediaPage p) =>
      MediaItem(sources: [_thumb(p)], width: p.width, height: p.height, blurHash: p.blurHash);

  /// Full-screen viewer: the thumb for the strip, the 1080 px view for the page.
  static MediaItem pageView(MediaPage p) => MediaItem(
        sources: [_thumb(p), ImageSource(width: p.width, height: p.height, url: p.viewUrl)],
        width: p.width,
        height: p.height,
        blurHash: p.blurHash,
      );
}
