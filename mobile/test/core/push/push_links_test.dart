import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/push/push_links.dart';

void main() {
  group('pushLinkToPath', () {
    const cases = {
      // A comment link keeps its anchor: the reader opens the comments (F17).
      'readin://a/my-post#comment-9': '/a/my-post#comment-9',
      'readin://a/my-post#comment-0a1b2c3d-0000-0000-0000-000000000001': '/a/my-post#comment-0a1b2c3d-0000-0000-0000-000000000001',
      // Any other anchor is dropped.
      'readin://a/my-post#b-p40': '/a/my-post',
      'readin://a/my-post#comment-x/../settings': '/a/my-post',
      'readin://notifications': '/notifications',
      // F17: several new followers, the streak reminder, security alerts.
      'readin://u/Mona_Dev/followers': '/u/mona_dev/followers',
      'readin://me/stats': '/me/stats',
      'readin://settings/account': '/settings?section=account',
      // F19: a verification result opens Settings → Writer verification (the web's /verification).
      'readin://verification': '/settings/verification',
      'https://readin.app/verification': '/settings/verification',
      'https://readin.app/a/my-post': '/a/my-post',
      // The web's article links (F24) open the version that was shared, and keep a comment anchor.
      'https://readin.app/en/a/my-post': '/a/my-post?lang=en',
      'https://readin.app/ar/a/my-post#comment-9': '/a/my-post?lang=ar-EG#comment-9',
      'https://READIN.app/ar/a/my-post#b-p40': '/a/my-post?lang=ar-EG',
      '/ar/a/my-post': '/a/my-post?lang=ar-EG',
      // Profiles (F14): the app's /u/{username} and the web's /@{username}.
      'readin://u/mona_dev': '/u/mona_dev',
      'https://readin.app/@Mona_Dev': '/u/mona_dev',
      '/u/omar': '/u/omar',
      // Tag pages (F32): the app's readin://tags/{slug} and the web's /tags/{slug}; an Arabic slug stays encoded.
      'readin://tags/csharp': '/tags/csharp',
      'https://readin.app/tags/asp-net-core': '/tags/asp-net-core',
      'https://readin.app/tags/CSharp': '/tags/csharp',
      '/tags/dotnet': '/tags/dotnet',
      // Field pages (F15): the app's readin://f/{slug} and the web's /f/{slug}, keeping a topic (?topic=) and nothing else.
      'readin://f/dotnet': '/f/dotnet',
      'https://readin.app/f/DotNet': '/f/dotnet',
      'https://readin.app/f/dotnet?topic=EF-Core': '/f/dotnet?topic=ef-core',
      'readin://f/dotnet?topic=ef-core&utm_source=x': '/f/dotnet?topic=ef-core',
      'https://readin.app/f/dotnet?topic=': '/f/dotnet',
      'https://readin.app/f/dotnet?topic=..%2Fsettings': '/f/dotnet',
      '/f/ai-fundamentals': '/f/ai-fundamentals',
      // A writer's category pages (F31): the app's readin://u/{username}/c/{slug} and the web's /@{username}/c/{slug};
      // "مقالات تانية" is _other. Slugs are matched ignoring case.
      'readin://u/mona_dev/c/ef-core': '/u/mona_dev/c/ef-core',
      'https://readin.app/@Mona_Dev/c/EF-Core': '/u/mona_dev/c/ef-core',
      'https://readin.app/@mona_dev/c/_other': '/u/mona_dev/c/_other',
      '/u/omar/c/flutter-notes': '/u/omar/c/flutter-notes',
    };
    cases.forEach((link, path) {
      test('maps $link to $path', () => expect(pushLinkToPath(link), path));
    });

    test('an Arabic tag slug arrives decoded and goes to the router percent-encoded (F32)', () {
      const slug = 'الذكاء-الاصطناعي';
      final encoded = Uri.encodeComponent(slug);
      expect(pushLinkToPath('readin://tags/$encoded'), '/tags/$encoded');
      expect(pushLinkToPath('https://readin.app/tags/$slug'), '/tags/$encoded');
    });

    for (final link in [
      'https://evil.example/a/x',
      // Only the configured web host (WEB_ORIGIN), never a look-alike, and only https.
      'https://readin.app.evil.example/ar/a/x',
      'https://www.readin.app/ar/a/x',
      'http://readin.app/ar/a/x',
      'https://readin.app/fr/a/x',
      '//evil.example/a/x',
      'javascript:alert(1)',
      'readin://settings/danger',
      'readin://settings/account/delete',
      'readin://me/settings',
      'readin://verification/42',
      'readin://verification/../settings',
      'readin://u/mona/edit',
      'readin://u/mona/following/x',
      'readin://u/..%2Fsettings/followers',
      'https://readin.app/@',
      'readin://u/..%2Fsettings',
      'readin://tags',
      'readin://tags/csharp/articles',
      'readin://tags/..%2Fsettings',
      'readin://tags/c%23',
      'https://evil.example/tags/csharp',
      'readin://f',
      'readin://f/dotnet/articles',
      'readin://f/..%2Fsettings',
      'https://evil.example/f/dotnet',
      'readin://u/mona/c',
      'readin://u/mona/c/ef-core/articles',
      'readin://u/mona/c/..%2Fsettings',
      'readin://u/mona/c/_admin',
      'https://readin.app/@mona/c',
      'https://readin.app/@mona/x/ef-core',
      'https://readin.app/@mona/c/ef-core/x',
      'https://evil.example/@mona/c/ef-core',
      '',
      null,
    ]) {
      test('drops ${link ?? 'null'}', () => expect(pushLinkToPath(link), isNull));
    }
  });

  group('webArticleRoute', () {
    test('maps the web\x27s article links, which App Links hand to the router, to the reader in that version', () {
      expect(webArticleRoute(Uri.parse('https://readin.app/en/a/rag-vs-fine-tuning')), '/a/rag-vs-fine-tuning?lang=en');
      expect(webArticleRoute(Uri.parse('/ar/a/rag-vs-fine-tuning')), '/a/rag-vs-fine-tuning?lang=ar-EG');
      expect(webArticleRoute(Uri.parse('/ar/a/%D9%85%D9%82%D8%A7%D9%84#comment-7')), '/a/%D9%85%D9%82%D8%A7%D9%84?lang=ar-EG#comment-7');
    });

    test('leaves every other path alone', () {
      for (final path in ['/a/x', '/fr/a/x', '/ar/b/x', '/ar/a', '/ar/a/x/y', '/home', '/']) {
        expect(webArticleRoute(Uri.parse(path)), isNull, reason: path);
      }
    });
  });

  group('webProfileRoute', () {
    test("maps the web's profile and category links, which App Links hand to the router, to /u/… (F14, F31)", () {
      expect(webProfileRoute(Uri.parse('https://readin.app/@Mona_Dev')), '/u/mona_dev');
      expect(webProfileRoute(Uri.parse('/@mona_dev/c/ef-core')), '/u/mona_dev/c/ef-core');
      expect(webProfileRoute(Uri.parse('/@mona_dev/c/_other')), '/u/mona_dev/c/_other');
      final encoded = Uri.encodeComponent('نصايح-backend');
      expect(webProfileRoute(Uri.parse('/@mona_dev/c/$encoded')), '/u/mona_dev/c/$encoded', reason: 'an Arabic slug stays encoded');
    });

    test('leaves every other path alone', () {
      for (final path in ['/u/mona', '/@', '/@mona/c', '/@mona/followers', '/@mona/c/x/y', '/@..%2Fsettings', '/home', '/']) {
        expect(webProfileRoute(Uri.parse(path)), isNull, reason: path);
      }
    });
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

    test('reads the notification id of a push (F17)', () {
      expect(pushNotificationId({'type': 'mention', 'notificationId': ' n-1 ', 'link': 'readin://a/x'}), 'n-1');
      expect(pushNotificationId({'type': 'daily_article'}), isNull);
      expect(pushNotificationId({'notificationId': 7}), isNull);
    });

    test('opens nothing specific for other pushes without a link', () {
      expect(pushDataLink({'type': 'new_follower', 'slug': 'x'}), isNull);
      expect(pushDataLink({'type': 'daily_article', 'slug': '  '}), isNull);
      expect(pushDataLink(const {}), isNull);
    });
  });
}
