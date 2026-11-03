import { pushLinkToPath, toPushMessage } from './push-message';

const ORIGIN = 'https://readin.app';

describe('push messages', () => {
  describe('toPushMessage', () => {
    it('reads the notification part and maps the deep link with the article language', () => {
      const message = toPushMessage(
        { notification: { title: 'أحمد رد عليك', body: 'تعليق جميل' }, data: { link: 'readin://a/my-post#comment-9', lang: 'en' } },
        ORIGIN,
        'ar',
      );
      expect(message).toEqual({ title: 'أحمد رد عليك', body: 'تعليق جميل', path: '/en/a/my-post#comment-9' });
    });

    it('falls back to data-only payloads and the UI language', () => {
      expect(toPushMessage({ data: { title: 'Daily article', body: 'Ready', link: 'readin://a/today' } }, ORIGIN, 'ar')).toEqual({
        title: 'Daily article',
        body: 'Ready',
        path: '/ar/a/today',
      });
    });

    it('opens the daily-article push in the article language the API sends (F07)', () => {
      // docs/api/contract-v1.md, "Push payloads". The service worker builds the same path for background pushes.
      const daily = {
        notification: { title: 'مقال النهارده جاهز ☕', body: 'RAG ولا Fine-tuning؟' },
        data: {
          type: 'daily_article',
          articleId: '0a1b2c3d-0000-0000-0000-000000000001',
          slug: 'rag-vs-fine-tuning',
          link: 'readin://a/rag-vs-fine-tuning',
          lang: 'en',
          tag: 'daily_article',
        },
      };
      expect(toPushMessage(daily, ORIGIN, 'ar')).toEqual({
        title: 'مقال النهارده جاهز ☕',
        body: 'RAG ولا Fine-tuning؟',
        path: '/en/a/rag-vs-fine-tuning',
      });
    });

    it('uses the FCM link option when the data has none', () => {
      expect(toPushMessage({ notification: { title: 'Hi' }, fcmOptions: { link: `${ORIGIN}/notifications` } }, ORIGIN, 'en')?.path).toBe(
        '/notifications',
      );
    });

    it('returns null when there is nothing to show', () => {
      expect(toPushMessage({ data: { link: 'readin://a/x' } }, ORIGIN, 'ar')).toBeNull();
      expect(toPushMessage('push', ORIGIN, 'ar')).toBeNull();
      expect(toPushMessage(null, ORIGIN, 'ar')).toBeNull();
    });
  });

  describe('pushLinkToPath', () => {
    it.each([
      ['readin://a/slug', '/ar/a/slug'],
      ['readin://notifications', '/notifications'],
      ['/ar/a/slug#comment-1', '/ar/a/slug#comment-1'],
      [`${ORIGIN}/@mona?tab=articles`, '/@mona?tab=articles'],
    ])('maps %s to %s', (link, path) => {
      expect(pushLinkToPath(link, ORIGIN, 'ar')).toBe(path);
    });

    it.each([['https://evil.example/phish'], ['//evil.example'], ['/\\evil.example'], ['readin:///evil.example'], ['javascript:alert(1)'], ['']])(
      'drops %s so a push can never open another site',
      (link) => {
        expect(pushLinkToPath(link, ORIGIN, 'ar')).toBeNull();
      },
    );
  });
});
