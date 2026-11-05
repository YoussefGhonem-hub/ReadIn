import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/profile/domain/entities/profile_link.dart';
import 'package:readin/features/profile/presentation/widgets/platform_icon.dart';
import 'package:readin/shared/utils/svg_path.dart';

/// The SVG path parser behind the bundled brand icons (SPEC F14).
void main() {
  test('absolute and relative lines and a close', () {
    final path = parseSvgPath('M2 2h20v20H2z');
    expect(path.getBounds(), const Rect.fromLTRB(2, 2, 22, 22));
    expect(path.contains(const Offset(12, 12)), isTrue);
  });

  test('compact numbers: "1.5.5" is two numbers, "1-2" too, exponents stay whole', () {
    final path = parseSvgPath('M0 0L1.5.5l-1-2L1e1 0z');
    final bounds = path.getBounds();
    expect(bounds.right, 10);
    expect(bounds.top, closeTo(-1.5, 1e-9));
  });

  test('arcs with packed flags ("a1 1 0 011 1") and the smooth curve commands', () {
    expect(() => parseSvgPath('M0 0a1 1 0 011 1A12 12 0 0 0 12 24c1 1 2 2 3 3s1 1 2 2q1 1 2 2t2 2Z'), returnsNormally);
    final circle = parseSvgPath('M12 0a12 12 0 1 0 0 24a12 12 0 1 0 0-24z');
    final bounds = circle.getBounds();
    expect(bounds.width, closeTo(24, 0.5));
    expect(bounds.height, closeTo(24, 0.5));
  });

  test('bad data is refused', () {
    expect(() => parseSvgPath('12 12'), throwsFormatException);
    expect(() => parseSvgPath('M0 0 A1 1 0 2 1 1 1'), throwsFormatException);
  });

  test('every bundled brand icon parses and fills its 24 × 24 box', () {
    for (final platform in LinkPlatform.values) {
      final path = PlatformIcon.pathOf(platform);
      if (platform == LinkPlatform.website || platform == LinkPlatform.other) {
        expect(path, isNull, reason: platform.name);
        continue;
      }
      expect(path, isNotNull, reason: platform.name);
      // Curve control points may reach a hair past the grid; the marks themselves stay inside it.
      final bounds = path!.getBounds();
      expect(bounds.left, greaterThanOrEqualTo(-0.25), reason: platform.name);
      expect(bounds.top, greaterThanOrEqualTo(-0.25), reason: platform.name);
      expect(bounds.right, inInclusiveRange(18, 24.25), reason: platform.name);
      expect(bounds.bottom, inInclusiveRange(18, 24.25), reason: platform.name);
    }
  });
}
