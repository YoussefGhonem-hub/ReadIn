import { pushLinkToPath, pushNotificationId, pushType, toPushMessage } from './push-message';

const ORIGIN = 'https://readin.app';

describe('push messages', () => {
  describe('toPushMessage', () => {
    it('reads the notification part and maps the deep link with the article language', () => {
      const message = toPushMessage(
        { notification: { title: 'أحمد رد عليك', body: 'تعليق جميل' }, data: { link: 'readin://a/my-post#comment-9', lang: 'en' } },
        ORIGIN,
        'ar',
      );
      expect(message).toEqual({ title: 'أحمد رد عليك', body: 'تعليق جميل', path: '/en/a/my-post#comment-9', notificationId: null });
    });

    it('falls back to data-only payloads and the UI language', () => {
      expect(toPushMessage({ data: { title: 'Daily article', body: 'Ready', link: 'readin://a/today' } }, ORIGIN, 'ar')).toEqual({
        title: 'Daily article',
        body: 'Ready',
        path: '/ar/a/today',
        notificationId: null,
      });
    });

    it('opens the daily-article push in the article language the API sends (F07)', () => {
      // docs/api/contract-v1.md, "Push payloads". The service worker builds the same path for background pushes.
      const daily = {
        notification: { title: 'مقال اليوم جاهز ☕', body: 'RAG ولا Fine-tuning؟' },
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
        title: 'مقال اليوم جاهز ☕',
        body: 'RAG ولا Fine-tuning؟',
        path: '/en/a/rag-vs-fine-tuning',
        notificationId: null,
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

  it('carries the notification-center row behind the push (F17)', () => {
    const push = {
      notification: { title: 'علّق أحمد و9 آخرون على مقالك' },
      data: { type: 'article_comment', notificationId: '6f1c0000-0000-0000-0000-000000000009', link: 'readin://a/clean-code#comment-c9', lang: 'ar' },
    };
    expect(toPushMessage(push, ORIGIN, 'en')).toEqual({
      title: 'علّق أحمد و9 آخرون على مقالك',
      body: '',
      path: '/ar/a/clean-code#comment-c9',
      notificationId: '6f1c0000-0000-0000-0000-000000000009',
    });
    expect(pushNotificationId(push)).toBe('6f1c0000-0000-0000-0000-000000000009');
    expect(pushNotificationId({ data: { notificationId: '  ' } })).toBeNull();
    expect(pushNotificationId(null)).toBeNull();
  });

  it('reads the push type from its data', () => {
    expect(pushType({ notification: { title: 'x' }, data: { type: 'moderation_notice', noticeId: 'n1' } })).toBe('moderation_notice');
    expect(pushType({ notification: { title: 'x' } })).toBeNull();
    expect(pushType(null)).toBeNull();
  });

  describe('pushLinkToPath', () => {
    it.each([
      ['readin://a/slug', '/ar/a/slug'],
      ['readin://notifications', '/notifications'],
      // F17's deep links: a profile, its followers, your reading stats, your account settings.
      ['readin://u/salma', '/@salma'],
      ['readin://u/mona/followers', '/@mona/followers'],
      ['readin://me/stats', '/me/stats'],
      ['readin://settings/account', '/settings#account'],
      // F19: a writer verification result opens your verification page.
      ['readin://verification', '/verification'],
      ['/ar/a/slug#comment-1', '/ar/a/slug#comment-1'],
      [`${ORIGIN}/@mona?tab=articles`, '/@mona?tab=articles'],
    ])('maps %s to %s', (link, path) => {
      expect(pushLinkToPath(link, ORIGIN, 'ar')).toBe(path);
    });

    it.each([['https://evil.example/phish'], ['//evil.example'], ['/\\evil.example'], ['readin:///evil.example'], ['readin://u/'], ['javascript:alert(1)'], ['']])(
      'drops %s so a push can never open another site',
      (link) => {
        expect(pushLinkToPath(link, ORIGIN, 'ar')).toBeNull();
      },
    );
  });
});
