import 'package:flutter_test/flutter_test.dart';
import 'package:readin/shared/media/media_item.dart';

void main() {
  const sources = [
    ImageSource(width: 320, height: 240, url: 'u/320'),
    ImageSource(width: 640, height: 480, url: 'u/640'),
    ImageSource(width: 1080, height: 810, url: 'u/1080'),
    ImageSource(width: 1600, height: 1200, url: 'u/1600'),
  ];

  test('picks the smallest variant that covers width × pixel ratio', () {
    expect(pickSource(sources, 300).url, 'u/320');
    expect(pickSource(sources, 342 * 1.0).url, 'u/640');
    expect(pickSource(sources, 342 * 3.0).url, 'u/1080');
    expect(pickSource(sources, 1080).url, 'u/1080');
    expect(pickSource(sources, 4000).url, 'u/1600', reason: 'falls back to the largest');
  });

  test('BlurHash strings are validated before decoding', () {
    expect(isValidBlurHash('LEHV6nWB2yk8pyo0adR*.7kCMdnj'), isTrue);
    expect(isValidBlurHash(null), isFalse);
    expect(isValidBlurHash('LEHV6'), isFalse);
    expect(isValidBlurHash('LEHV6nWB2yk8pyo0adR*.7kCMdn'), isFalse, reason: 'wrong length for its size flag');
    expect(isValidBlurHash('LEHV6nWB2yk8pyo0adR*.7kCMd"j'), isFalse, reason: 'not base83');
  });
}
