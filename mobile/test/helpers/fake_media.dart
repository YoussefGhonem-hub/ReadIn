import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:readin/shared/media/media_image.dart';

/// Deterministic stand-ins for network/file images in widget and golden
/// tests: images are painted once (real async, call [install] from
/// `setUpAll`) and then served synchronously, so the first frame already
/// shows them — no network, no disk cache, no flaky decoding.
abstract final class FakeMedia {
  static final _photos = <ui.Image>[];
  static ui.Image? _page;

  // Test-only palette (not app UI colors).
  static const _palettes = [
    (Color(0xFF2F6F62), Color(0xFFE9C46A)),
    (Color(0xFF264653), Color(0xFF8AB17D)),
    (Color(0xFF9C4A3A), Color(0xFFF4A261)),
    (Color(0xFF3D405B), Color(0xFF81B29A)),
  ];

  static Future<void> install() async {
    if (_photos.isEmpty) {
      for (final (a, b) in _palettes) {
        _photos.add(await _paint(320, 320, (canvas, size) {
          final rect = Offset.zero & size;
          canvas.drawRect(rect, Paint()..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [a, b]));
          canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.3), size.width * 0.14, Paint()..color = b);
          final hill = Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width * 0.38, size.height * 0.52)
            ..lineTo(size.width * 0.7, size.height)
            ..close();
          canvas.drawPath(hill, Paint()..color = a.withValues(alpha: 0.85));
        }));
      }
      _page = await _paint(283, 400, (canvas, size) {
        canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));
        canvas.drawRect(const Rect.fromLTWH(24, 28, 180, 18), Paint()..color = const Color(0xFF0F5E52));
        final line = Paint()..color = const Color(0xFFB8B8B8);
        for (var i = 0; i < 14; i++) {
          canvas.drawRect(Rect.fromLTWH(24, 70.0 + i * 20, i % 4 == 3 ? 150 : 235, 8), line);
        }
      });
    }
    MediaImages.networkProvider = FakeImageProvider.new;
    MediaImages.fileProvider = (path, _) => FakeImageProvider(path);
  }

  static Future<ui.Image> _paint(int width, int height, void Function(Canvas, Size) draw) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder), Size(width.toDouble(), height.toDouble()));
    return recorder.endRecording().toImage(width, height);
  }

  static ui.Image imageFor(String key) {
    if (key.contains('page')) return _page!;
    final hash = key.codeUnits.fold<int>(0, (h, c) => (h * 31 + c) & 0x7fffffff);
    return _photos[hash % _photos.length];
  }
}

/// Serves a [FakeMedia] image synchronously.
@immutable
class FakeImageProvider extends ImageProvider<FakeImageProvider> {
  const FakeImageProvider(this.key);

  final String key;

  @override
  Future<FakeImageProvider> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(FakeImageProvider key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: FakeMedia.imageFor(key.key).clone())));

  @override
  bool operator ==(Object other) => other is FakeImageProvider && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
