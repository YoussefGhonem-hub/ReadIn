import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { translocoTesting } from '../../../testing/transloco-testing';
import { testNotification } from '../../../testing/notifications-testing';
import { NotificationDto } from '../../core/api/models';
import { dayKey, notificationIcon, notificationPath, notificationText } from './notification-view';

const ORIGIN = 'https://readin.app';

describe('notification view (F17)', () => {
  let transloco: TranslocoService;

  beforeEach(() => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ imports: [translocoTesting()] });
    transloco = TestBed.inject(TranslocoService);
  });

  const sentence = (n: NotificationDto, lang: 'ar' | 'en') => {
    const { before, actor, after } = notificationText(n, transloco, lang);
    return `${before}${actor ?? ''}${after}`;
  };

  describe('text', () => {
    it('"X and N others" with the actor apart, so it can be bold and isolated', () => {
      const n = testNotification({ actorCount: 10 });
      expect(notificationText(n, transloco, 'en')).toEqual({ before: '', actor: 'Ahmed Samir', after: ' and 9 others commented on your article' });
      expect(sentence(n, 'ar')).toBe('Ahmed Samir و9 غيره علّقوا على مقالك');
      expect(sentence(testNotification({ actorCount: 1 }), 'en')).toBe('Ahmed Samir commented on your article');
    });

    it('uses every Arabic plural form for the others', () => {
      const text = (actorCount: number) => sentence(testNotification({ type: 'new_follower', actorCount }), 'ar');
      expect(text(1)).toBe('Ahmed Samir بدأ يتابعك');
      expect(text(2)).toBe('Ahmed Samir وواحد غيره بدأوا يتابعوك');
      expect(text(3)).toBe('Ahmed Samir واتنين غيره بدأوا يتابعوك');
      expect(text(4)).toBe('Ahmed Samir و3 غيره بدأوا يتابعوك');
      expect(text(12)).toBe('Ahmed Samir و11 غيره بدأوا يتابعوك');
      expect(text(101)).toBe('Ahmed Samir و100 غيره بدأوا يتابعوك');
      expect(sentence(testNotification({ type: 'new_follower', actorCount: 2 }), 'en')).toBe('Ahmed Samir and 1 other started following you');
    });

    it('says "Deleted user" when the actor\'s account is gone', () => {
      const n = testNotification({ type: 'comment_reply', actor: null });
      expect(notificationText(n, transloco, 'ar').actor).toBe('مستخدم محذوف');
      expect(sentence(n, 'en')).toBe('Deleted user replied to your comment');
    });

    it.each([
      ['mention', 'Ahmed Samir mentioned you in a comment', 'Ahmed Samir عملك منشن في تعليق'],
      ['followed_writer_article', 'Ahmed Samir published a new article', 'Ahmed Samir نشر مقال جديد'],
      ['daily_article', "Today's article is ready ☕", 'مقال النهارده جاهز ☕'],
      ['verification_result', "There's an update on your writer verification request", 'فيه جديد في طلب توثيقك ككاتب'],
    ] as const)('%s', (type, en, ar) => {
      const n = testNotification({ type });
      expect(sentence(n, 'en')).toBe(en);
      expect(sentence(n, 'ar')).toBe(ar);
    });

    it('milestones and streaks count with plurals', () => {
      expect(sentence(testNotification({ type: 'reactions_milestone', actor: null, data: { threshold: 50 } }), 'en')).toBe('Your article reached 50 reactions 🎉');
      expect(sentence(testNotification({ type: 'reactions_milestone', actor: null, data: { threshold: 10 } }), 'ar')).toBe('مقالك وصل لـ 10 تفاعلات 🎉');
      expect(sentence(testNotification({ type: 'reactions_milestone', actor: null, data: { threshold: 100 } }), 'ar')).toBe('مقالك وصل لـ 100 تفاعل 🎉');
      expect(sentence(testNotification({ type: 'streak_reminder', actor: null, data: { streakDays: 6 } }), 'ar')).toBe(
        'سلسلتك 6 أيام. اقرا حاجة النهارده عشان متضيعش 🔥',
      );
      expect(sentence(testNotification({ type: 'streak_reminder', actor: null, data: { streakDays: 1 } }), 'en')).toBe(
        'Your streak is 1 day. Read something today to keep it 🔥',
      );
    });

    it('security alerts say what changed; an unknown change gets the general line', () => {
      const alert = (securityChange: string) =>
        sentence(testNotification({ type: 'security_alert', actor: null, article: null, data: { securityChange: securityChange as never } }), 'en');
      expect(alert('passwordChanged')).toBe('Your password was changed');
      expect(alert('phoneNumberChanged')).toBe('Your phone number was changed');
      expect(alert('recoveryLockedOut')).toBe('Too many wrong PIN attempts, so account recovery is locked for a while');
      expect(alert('somethingNew')).toBe('There was a security change on your account');
    });

    it('a moderation notice is a warning, or "your article was hidden" when it names one', () => {
      expect(sentence(testNotification({ type: 'moderation_notice', actor: null, article: null }), 'ar')).toBe('وصلك تحذير من فريق الإشراف');
      expect(sentence(testNotification({ type: 'moderation_notice', actor: null }), 'en')).toBe('The moderators hid your article');
      expect(notificationIcon(testNotification({ type: 'moderation_notice', article: null }))).toBe('TriangleAlert');
    });

    it('a type this version does not know gets a generic line', () => {
      expect(sentence(testNotification({ type: 'path_completed' as never, actor: null }), 'en')).toBe('You have a new notification');
    });
  });

  describe('where a tap goes', () => {
    it('opens an article in the language of the version it names, with its comment', () => {
      expect(notificationPath(testNotification(), 'ar', ORIGIN)).toBe('/en/a/clean-code#comment-c9');
      expect(notificationPath(testNotification({ article: { id: 'a1', slug: 'di', title: 'DI', language: 'ar-EG' }, link: 'readin://a/di' }), 'en', ORIGIN)).toBe(
        '/ar/a/di',
      );
    });

    it.each([
      ['readin://u/omar_dev', '/@omar_dev'],
      ['readin://u/sara/followers', '/@sara/followers'],
      ['readin://me/stats', '/me/stats'],
      ['readin://settings/account', '/settings#account'],
      ['https://evil.example/x', null],
      // A moderation warning: the center itself, so its dialog opens instead.
      ['readin://notifications', null],
    ])('%s → %s', (link, path) => {
      expect(notificationPath(testNotification({ article: null, link }), 'ar', ORIGIN)).toBe(path);
    });
  });

  it('"today" is the calendar day in the user\'s time zone', () => {
    const late = new Date('2026-11-03T22:30:00Z'); // 00:30 on the 4th in Cairo
    expect(dayKey(late, 'Africa/Cairo')).toBe('2026-11-04');
    expect(dayKey(late, 'UTC')).toBe('2026-11-03');
    expect(dayKey(late, 'Not/AZone')).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});
