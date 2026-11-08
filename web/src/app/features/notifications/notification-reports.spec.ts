import { Component, input } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { testNotification } from '../../../testing/notifications-testing';
import { setupSocialTesting } from '../../../testing/social-testing';
import { NotificationDto } from '../../core/api/models';
import { provideNotificationIcons } from './notification-icons';
import { NotificationItem } from './notification-item';
import { isActorType, notificationDetail, notificationIcon, notificationPath, notificationText } from './notification-view';

const ORIGIN = 'https://readin.app';

/** The panel and the page provide the notification icons. */
@Component({
  imports: [NotificationItem],
  providers: [provideNotificationIcons()],
  template: `<rd-notification-item [notification]="notification()" />`,
})
class Host {
  readonly notification = input.required<NotificationDto>();
}

function reportNew(data: NotificationDto['data'] = {}): NotificationDto {
  return testNotification({
    type: 'report_new',
    actor: null,
    actorCount: 0,
    article: null,
    comment: null,
    data: { targetType: 'comment', targetId: 'c1', targetLabel: 'This is spam, buy now', reportCount: 2, system: false, ...data },
    link: 'readin://admin/reports/comment/c1',
  });
}

function reportResolved(data: NotificationDto['data'] = {}): NotificationDto {
  return testNotification({
    type: 'report_resolved',
    actor: null,
    actorCount: 0,
    article: null,
    comment: null,
    data: { targetType: 'article', targetLabel: 'Clean code in practice', outcome: 'actioned', ...data },
    link: 'readin://notifications',
  });
}

describe('report notifications (F22, store requirements)', () => {
  let transloco: TranslocoService;

  beforeEach(() => {
    TestBed.resetTestingModule();
    setupSocialTesting();
    transloco = TestBed.inject(TranslocoService);
  });

  const sentence = (n: NotificationDto, lang: 'ar' | 'en') => {
    const { before, actor, after } = notificationText(n, transloco, lang);
    return `${before}${actor ?? ''}${after}`;
  };

  it('report_new names what was reported, never who reported it, and opens the console case', () => {
    expect(isActorType('report_new')).toBe(false);
    const expected: [string, string, string][] = [
      ['article', 'بلاغ جديد عن مقال', 'New report: article'],
      ['comment', 'بلاغ جديد عن تعليق', 'New report: comment'],
      ['user', 'بلاغ جديد عن حساب', 'New report: account'],
      ['repost', 'بلاغ جديد عن إعادة نشر', 'New report: repost'],
      ['something-new', 'بلاغ جديد', 'New report'],
    ];
    for (const [targetType, ar, en] of expected) {
      const n = reportNew({ targetType: targetType as never });
      expect(sentence(n, 'ar')).toBe(ar);
      expect(sentence(n, 'en')).toBe(en);
    }
    const n = reportNew();
    expect(notificationText(n, transloco, 'ar').actor).toBeNull();
    expect(notificationDetail(n)).toBe('This is spam, buy now');
    expect(notificationIcon(n)).toBe('Flag');
    expect(notificationPath(n, 'ar', ORIGIN)).toBe('/admin/reports/comment/c1');
  });

  it("report_resolved tells the reporter the outcome only, and stays in the notification center", () => {
    expect(sentence(reportResolved(), 'ar')).toBe('راجعنا بلاغك وأزلنا المحتوى');
    expect(sentence(reportResolved(), 'en')).toBe('We reviewed your report and removed the content');
    expect(sentence(reportResolved({ targetType: 'user', targetLabel: '@omar' }), 'ar')).toBe('راجعنا بلاغك واتخذنا الإجراء المناسب');
    expect(sentence(reportResolved({ outcome: 'no_violation' }), 'ar')).toBe('راجعنا بلاغك، والمحتوى لا يخالف قواعد المجتمع');
    expect(sentence(reportResolved({ outcome: 'no_violation' }), 'en')).toBe("We reviewed your report; the content doesn't break our guidelines");
    expect(notificationDetail(reportResolved())).toBe('Clean code in practice');
    expect(notificationIcon(reportResolved())).toBe('ShieldCheck');
    expect(notificationPath(reportResolved(), 'ar', ORIGIN)).toBeNull();
  });

  it('the row: a content-filter report says so before the label, in the danger tone', () => {
    const fixture = TestBed.createComponent(Host);
    fixture.componentRef.setInput('notification', reportNew({ system: true, targetLabel: 'A bad caption' }));
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    expect(root.textContent).toContain('بلاغ جديد عن تعليق');
    const system = root.querySelector('[data-notification-system]')!;
    expect(system.textContent!.replace(/\s+/g, ' ').trim()).toBe('رصده فلتر المحتوى · A bad caption');
    expect(root.querySelector('[data-notification-detail]')).toBeNull();
    expect(root.querySelector('.bg-callout-danger')).not.toBeNull();

    fixture.componentRef.setInput('notification', reportNew());
    fixture.detectChanges();
    expect(root.querySelector('[data-notification-system]')).toBeNull();
    expect(root.querySelector('[data-notification-detail]')!.textContent!.trim()).toBe('This is spam, buy now');
  });
});
