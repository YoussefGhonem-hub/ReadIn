import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { translocoTesting } from '../../../testing/transloco-testing';
import { testNotification } from '../../../testing/notifications-testing';
import { NotificationDto } from '../../core/api/models';
import { dayKey, notificationIcon, notificationPath, notificationText, verificationOutcome } from './notification-view';

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
      expect(sentence(n, 'ar')).toBe('علّق Ahmed Samir و9 آخرون على مقالك');
      expect(sentence(testNotification({ actorCount: 1 }), 'en')).toBe('Ahmed Samir commented on your article');
    });

    it('uses every Arabic plural form for the others', () => {
      const text = (actorCount: number) => sentence(testNotification({ type: 'new_follower', actorCount }), 'ar');
      expect(text(1)).toBe('بدأ Ahmed Samir متابعتك');
      expect(text(2)).toBe('بدأ Ahmed Samir وشخص آخر متابعتك');
      expect(text(3)).toBe('بدأ Ahmed Samir وشخصان آخران متابعتك');
      expect(text(4)).toBe('بدأ Ahmed Samir و3 آخرون متابعتك');
      expect(text(12)).toBe('بدأ Ahmed Samir و11 آخرون متابعتك');
      expect(text(101)).toBe('بدأ Ahmed Samir و100 آخرون متابعتك');
      expect(sentence(testNotification({ type: 'new_follower', actorCount: 2 }), 'en')).toBe('Ahmed Samir and 1 other started following you');
    });

    it('says "Deleted user" when the actor\'s account is gone', () => {
      const n = testNotification({ type: 'comment_reply', actor: null });
      expect(notificationText(n, transloco, 'ar').actor).toBe('مستخدم محذوف');
      expect(sentence(n, 'en')).toBe('Deleted user replied to your comment');
    });

    it.each([
      ['mention', 'Ahmed Samir mentioned you in a comment', 'أشار إليك Ahmed Samir في تعليق'],
      ['followed_writer_article', 'Ahmed Samir published a new article', 'نشر Ahmed Samir مقالًا جديدًا'],
      ['daily_article', "Today's article is ready ☕", 'مقال اليوم جاهز ☕'],
    ] as const)('%s', (type, en, ar) => {
      const n = testNotification({ type });
      expect(sentence(n, 'en')).toBe(en);
      expect(sentence(n, 'ar')).toBe(ar);
    });

    it('a repost (F29): "X reposted your article", grouped per article with every Arabic plural, its icon and its article link', () => {
      const repost = (actorCount: number) =>
        testNotification({
          type: 'article_reposted',
          actorCount,
          comment: null,
          data: {},
          article: { id: 'a1', slug: 'clean-code', title: 'Clean Code', language: 'en' },
          link: 'readin://a/clean-code',
        });
      expect(notificationText(repost(1), transloco, 'en')).toEqual({ before: '', actor: 'Ahmed Samir', after: ' reposted your article' });
      expect(sentence(repost(1), 'ar')).toBe('أعاد Ahmed Samir نشر مقالك');
      expect(sentence(repost(2), 'ar')).toBe('أعاد Ahmed Samir وشخص آخر نشر مقالك');
      expect(sentence(repost(3), 'ar')).toBe('أعاد Ahmed Samir وشخصان آخران نشر مقالك');
      expect(sentence(repost(5), 'ar')).toBe('أعاد Ahmed Samir و4 آخرون نشر مقالك');
      expect(sentence(repost(2), 'en')).toBe('Ahmed Samir and 1 other reposted your article');
      expect(sentence(repost(12), 'en')).toBe('Ahmed Samir and 11 others reposted your article');
      expect(notificationIcon(repost(1))).toBe('Repeat2');
      expect(notificationPath(repost(1), 'ar', ORIGIN)).toBe('/en/a/clean-code');
      // A reposter who deleted their account.
      expect(sentence(testNotification({ type: 'article_reposted', actor: null, actorCount: 1 }), 'en')).toBe('Deleted user reposted your article');
    });

    it('a writer verification result says approved or not by data.approved; without it, the general line (F19)', () => {
      const result = (approved?: boolean) =>
        testNotification({ type: 'verification_result', actor: null, actorCount: 0, article: null, comment: null, data: approved === undefined ? {} : { approved }, link: 'readin://verification' });
      expect(sentence(result(true), 'en')).toBe("You're now a verified writer ✓");
      expect(sentence(result(true), 'ar')).toBe('أصبحت الآن كاتبًا موثّقًا ✓');
      expect(sentence(result(false), 'en')).toBe("Your verification request wasn't approved");
      expect(sentence(result(false), 'ar')).toBe('لم تتم الموافقة على طلب توثيقك');
      expect(sentence(result(), 'en')).toBe("There's an update on your writer verification request");
      expect(sentence(result(), 'ar')).toBe('هناك تحديث بشأن طلب توثيقك ككاتب');
      expect(notificationIcon(result(true))).toBe('BadgeCheck');
      expect(notificationIcon(result(false))).toBe('BadgeX');
      expect(notificationIcon(result())).toBe('BadgeCheck');
      // The reason is never in the notification: it opens the verification page.
      expect(notificationPath(result(false), 'ar', ORIGIN)).toBe('/verification');
      expect(verificationOutcome(result(true))).toBe('approved');
      expect(verificationOutcome(result(false))).toBe('rejected');
      expect(verificationOutcome(result())).toBe('other');
    });

    it('a mention without a comment is a mention in an article (the article title is shown under it)', () => {
      const n = testNotification({
        type: 'mention',
        comment: null,
        article: { id: 'a2', slug: 'di', title: 'يعني إيه Dependency Injection؟', language: 'ar-EG' },
        link: 'readin://a/di',
      });
      expect(notificationText(n, transloco, 'en')).toEqual({ before: '', actor: 'Ahmed Samir', after: ' mentioned you in an article' });
      expect(sentence(n, 'ar')).toBe('أشار إليك Ahmed Samir في مقال');
      expect(notificationIcon(n)).toBe('AtSign');
      // No #comment: the article itself, in its own language.
      expect(notificationPath(n, 'en', ORIGIN)).toBe('/ar/a/di');
      // With a comment it stays a mention in a comment.
      expect(sentence(testNotification({ type: 'mention' }), 'en')).toBe('Ahmed Samir mentioned you in a comment');
    });

    it('milestones and streaks count with plurals', () => {
      expect(sentence(testNotification({ type: 'reactions_milestone', actor: null, data: { threshold: 50 } }), 'en')).toBe('Your article reached 50 reactions 🎉');
      expect(sentence(testNotification({ type: 'reactions_milestone', actor: null, data: { threshold: 10 } }), 'ar')).toBe('بلغ مقالك 10 تفاعلات 🎉');
      expect(sentence(testNotification({ type: 'reactions_milestone', actor: null, data: { threshold: 100 } }), 'ar')).toBe('بلغ مقالك 100 تفاعل 🎉');
      expect(sentence(testNotification({ type: 'streak_reminder', actor: null, data: { streakDays: 6 } }), 'ar')).toBe(
        'سلسلة قراءتك: 6 أيام. اقرأ شيئًا اليوم للحفاظ عليها 🔥',
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
      expect(sentence(testNotification({ type: 'moderation_notice', actor: null, article: null }), 'ar')).toBe('تلقّيت تحذيرًا من فريق الإشراف');
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
      ['readin://verification', '/verification'],
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
