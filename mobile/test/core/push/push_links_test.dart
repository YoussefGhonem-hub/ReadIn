import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/push/push_links.dart';

void main() {
  group('pushLinkToPath', () {
    const cases = {
      'readin://a/my-post#comment-9': '/a/my-post',
      'readin://notifications': '/notifications',
      'https://readin.app/a/my-post': '/a/my-post',
      'https://readin.app/en/a/my-post': '/a/my-post',
      '/ar/a/my-post': '/a/my-post',
    };
    cases.forEach((link, path) {
      test('maps $link to $path', () => expect(pushLinkToPath(link), path));
    });

    for (final link in ['https://evil.example/a/x', '//evil.example/a/x', 'javascript:alert(1)', 'readin://settings/danger', '', null]) {
      test('drops ${link ?? 'null'}', () => expect(pushLinkToPath(link), isNull));
    }
  });
}
