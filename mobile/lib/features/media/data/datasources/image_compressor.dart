import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';

/// Client-side image compression before upload (SPEC F26 "Image optimization"):
/// longest side ≤ 2048 px, JPEG quality 85, EXIF orientation applied, EXIF
/// dropped. HEIC from iOS becomes JPEG. Returns null when compression fails —
/// callers then upload the original (the server re-processes everything).
@lazySingleton
class ImageCompressor {
  static const maxSide = 2048;
  static const quality = 85;

  /// `flutter_image_compress` names its bounds `minWidth`/`minHeight`, but
  /// they act as a *max*: `scale = max(1, min(w / minWidth, h / minHeight))`.
  /// Passing the same bound for both, derived from the short side, caps the
  /// long side at [maxSide] whatever the EXIF orientation is (the plugin may
  /// see the un-rotated width/height), and never upscales.
  static int boundFor(int width, int height, {int maxSide = ImageCompressor.maxSide}) {
    final long = math.max(width, height);
    final short = math.min(width, height);
    if (long <= maxSide) return math.max(1, short);
    return math.max(1, (short * maxSide / long).floor());
  }

  Future<Uint8List?> compress(String path) async {
    try {
      final size = await _decodedSize(path);
      final bound = size == null ? maxSide : boundFor(size.$1, size.$2);
      var bytes = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: bound,
        minHeight: bound,
        quality: quality,
        autoCorrectionAngle: true,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      if (bytes == null || bytes.isEmpty) return null;
      if (size == null) {
        // The engine couldn't read the source header (e.g. HEIC on some
        // devices), so the first pass only capped the short side. The JPEG
        // output is always readable: cap the long side now if needed.
        final out = await _bytesSize(bytes);
        if (out != null && math.max(out.$1, out.$2) > maxSide) {
          final second = boundFor(out.$1, out.$2);
          bytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: second,
            minHeight: second,
            quality: quality,
            autoCorrectionAngle: false,
            keepExif: false,
            format: CompressFormat.jpeg,
          );
        }
      }
      return bytes;
    } on Object {
      return null;
    }
  }

  static Future<(int, int)?> _decodedSize(String path) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(path);
      return _describe(buffer);
    } on Object {
      return null;
    }
  }

  static Future<(int, int)?> _bytesSize(Uint8List bytes) async {
    try {
      return _describe(await ui.ImmutableBuffer.fromUint8List(bytes));
    } on Object {
      return null;
    }
  }

  static Future<(int, int)?> _describe(ui.ImmutableBuffer buffer) async {
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (descriptor.width, descriptor.height);
      descriptor.dispose();
      return size;
    } finally {
      buffer.dispose();
    }
  }
}
