import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/media/data/datasources/image_compressor.dart';
import 'package:readin/features/media/domain/entities/media.dart';

/// The plugin's scale rule (flutter_image_compress README): bounds act as a max.
(double, double) output(int w, int h, int bound) {
  final scale = math.max(1.0, math.min(w / bound, h / bound));
  return (w / scale, h / scale);
}

void main() {
  test('caps the longest side at 2048 px in both orientations, never upscales', () {
    for (final (w, h) in const [(4032, 3024), (3024, 4032), (8000, 1000), (1000, 8000), (2049, 2049), (6000, 4000)]) {
      final bound = ImageCompressor.boundFor(w, h);
      final (ow, oh) = output(w, h, bound);
      expect(math.max(ow, oh), lessThanOrEqualTo(2048), reason: '$w×$h');
      expect(math.max(ow, oh), greaterThan(2040), reason: '$w×$h keeps nearly 2048 px');
      // EXIF rotation may hand the plugin the swapped size: same result.
      final (sw, sh) = output(h, w, bound);
      expect(math.max(sw, sh), math.max(ow, oh));
    }
    for (final (w, h) in const [(1200, 900), (2048, 1536), (640, 640)]) {
      final (ow, oh) = output(w, h, ImageCompressor.boundFor(w, h));
      expect((ow, oh), (w.toDouble(), h.toDouble()), reason: 'small images keep their size');
    }
    expect(ImageCompressor.boundFor(100000, 1), 1);
  });

  test('downloaded PDF names are safe and end in .pdf', () {
    expect(pdfFileName('Clean Architecture: notes/v2'), 'Clean Architecture_ notes_v2.pdf');
    expect(pdfFileName('ملخص .NET.pdf'), 'ملخص .NET.pdf');
    expect(pdfFileName('   '), 'document.pdf');
  });
}
