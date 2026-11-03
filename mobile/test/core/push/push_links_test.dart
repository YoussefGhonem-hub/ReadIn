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

  group('pushDataLink', () {
    test('uses the link the API sends', () {
      // The daily-article payload (docs/api/contract-v1.md, "Push payloads").
      const data = {
        'type': 'daily_article',
        'articleId': '0a1b2c3d-0000-0000-0000-000000000001',
        'slug': 'rag-vs-fine-tuning',
        'link': 'readin://a/rag-vs-fine-tuning',
        'lang': 'ar',
      };
      expect(pushDataLink(data), 'readin://a/rag-vs-fine-tuning');
      expect(pushLinkToPath(pushDataLink(data)), '/a/rag-vs-fine-tuning');
    });

    test('opens the reader of a daily-article push from its slug when it has no link', () {
      final link = pushDataLink({'type': 'daily_article', 'slug': 'use-client-does-not-mean-client-only'});
      expect(pushLinkToPath(link), '/a/use-client-does-not-mean-client-only');
    });

    test('opens nothing specific for other pushes without a link', () {
      expect(pushDataLink({'type': 'new_follower', 'slug': 'x'}), isNull);
      expect(pushDataLink({'type': 'daily_article', 'slug': '  '}), isNull);
      expect(pushDataLink(const {}), isNull);
    });
  });
}
