import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { testMe } from '../../../../testing/auth-testing';
import { NotificationSettingsDto } from '../../../core/api/models';
import { SessionStore } from '../../../core/auth/session.store';
import { PushService } from '../../../core/push/push.service';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { CONFIGURABLE_TYPES, NotificationSettingsPage } from './notification-settings.page';

const URL = `${TEST_API}/me/notification-settings`;

function settings(patch: Partial<NotificationSettingsDto> = {}): NotificationSettingsDto {
  return {
    quietHours: { enabled: true, start: '23:00', end: '07:00' },
    types: Object.fromEntries(CONFIGURABLE_TYPES.map((type) => [type, 'all'])),
    ...patch,
  };
}

describe('NotificationSettingsPage (F17)', () => {
  let http: HttpTestingController;
  const push = { permission: signal<'default' | 'granted' | 'denied' | 'unsupported'>('granted'), enable: vi.fn(async () => 'granted') };

  beforeEach(() => {
    TestBed.resetTestingModule();
    push.permission.set('granted');
    push.enable.mockClear();
    ({ http } = setupSocialTesting({ providers: [{ provide: PushService, useValue: push }] }));
  });

  afterEach(() => http.verify());

  async function render(loaded: NotificationSettingsDto = settings()) {
    const fixture = TestBed.createComponent(NotificationSettingsPage);
    fixture.detectChanges();
    http.expectOne({ method: 'GET', url: URL }).flush(loaded);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
    };
    await stable();
    const typeRow = (type: string) => root.querySelector<HTMLElement>(`[data-notification-type="${type}"]`)!;
    const choose = (type: string, mode: 'all' | 'inApp' | 'off') =>
      typeRow(type).querySelectorAll<HTMLButtonElement>('[role="radio"]')[['all', 'inApp', 'off'].indexOf(mode)].click();
    const put = (): TestRequest => http.expectOne({ method: 'PUT', url: URL });
    return { fixture, root, stable, typeRow, choose, put };
  }

  it('lists every configurable type with its mode (a type the API leaves out is "All")', async () => {
    const { root, typeRow } = await render(settings({ types: { mention: 'off', daily_article: 'inApp' } }));
    // F35: support tickets only for holders of support.manage, and (F22, store) new reports only for holders of
    // moderation.manage, so a member's list leaves both out.
    expect([...root.querySelectorAll('[data-notification-type]')].map((e) => e.getAttribute('data-notification-type'))).toEqual(
      CONFIGURABLE_TYPES.filter((type) => type !== 'support_ticket' && type !== 'report_new'),
    );
    expect(typeRow('mention').getAttribute('data-mode')).toBe('off');
    expect(typeRow('daily_article').getAttribute('data-mode')).toBe('inApp');
    expect(typeRow('new_follower').getAttribute('data-mode')).toBe('all');
    expect(typeRow('mention').textContent).toContain('الإشارات');
    // Mentions cover comments and articles.
    expect(typeRow('mention').textContent).toContain('عندما يشير إليك أحد في تعليق أو مقال');
    expect(TestBed.inject(TranslocoService).translate('settings.notifications.types.mention.hint', {}, 'en')).toBe('When someone mentions you in a comment or an article');
    // F29: reposts are the 9th configurable type; F23 and F35 add announcements and support tickets after it, and the
    // F22 store additions new reports.
    expect(CONFIGURABLE_TYPES).toHaveLength(12);
    expect(CONFIGURABLE_TYPES.slice(-4)).toEqual(['article_reposted', 'announcement', 'support_ticket', 'report_new']);
    expect(typeRow('announcement').textContent).toContain('الإعلانات');
    expect(typeRow('article_reposted').getAttribute('data-mode')).toBe('all');
    expect(typeRow('article_reposted').textContent).toContain('إعادة النشر');
    expect(typeRow('article_reposted').textContent).toContain('عندما يعيد أحد نشر مقالك');
    expect(TestBed.inject(TranslocoService).translate('settings.notifications.types.article_reposted.label', {}, 'en')).toBe('Reposts');
    expect(root.querySelector('[data-notification-types]')!.textContent).toContain('لا يمكن إيقاف تنبيهات الأمان وإشعارات فريق الإشراف');
    expect(root.querySelector<HTMLInputElement>('#quiet-start')!.value).toBe('23:00');
    expect(root.querySelector<HTMLInputElement>('#quiet-end')!.value).toBe('07:00');
  });

  it('moderators (moderation.manage) also get New reports, which they can turn off (F22, store)', async () => {
    TestBed.inject(SessionStore).setMe(testMe({ permissions: ['moderation.manage'] }));
    const { root, typeRow, choose, put, stable } = await render();
    const shown = [...root.querySelectorAll('[data-notification-type]')].map((e) => e.getAttribute('data-notification-type'));
    expect(shown).toContain('report_new');
    expect(shown).not.toContain('support_ticket');
    expect(typeRow('report_new').textContent).toContain('البلاغات الجديدة');
    expect(typeRow('report_new').textContent).toContain('عندما يبلغ أحد عن محتوى أو حساب');
    choose('report_new', 'off');
    await stable();
    const request = put();
    expect(request.request.body.types).toEqual({ report_new: 'off' });
    request.flush(null, { status: 204, statusText: 'No Content' });
    await stable();
    expect(typeRow('report_new').getAttribute('data-mode')).toBe('off');
  });

  it('saves a changed mode at once, sending that type only; a refusal puts it back', async () => {
    const { typeRow, choose, put, stable } = await render();
    choose('mention', 'off');
    await stable();
    const first = put();
    expect(first.request.body).toEqual({ quietHours: { enabled: true, start: '23:00', end: '07:00' }, types: { mention: 'off' } });
    expect(typeRow('mention').getAttribute('data-mode')).toBe('off');
    first.flush(null, { status: 204, statusText: 'No Content' });
    await stable();

    choose('comment_reply', 'inApp');
    await stable();
    put().flush(problem(400, 'notification.mode_invalid'), { status: 400, statusText: 'Bad Request' });
    await stable();
    expect(typeRow('comment_reply').getAttribute('data-mode')).toBe('all');
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'error', message: 'اختر «الكل» أو «داخل التطبيق» أو «إيقاف».' })]);
  });

  it('choosing "All" asks for push permission in context when this browser was never asked', async () => {
    push.permission.set('default');
    const { choose, put, stable } = await render(settings({ types: { mention: 'off' } }));
    choose('mention', 'inApp');
    await stable();
    put().flush(null, { status: 204, statusText: 'No Content' });
    await stable();
    expect(push.enable).not.toHaveBeenCalled();

    choose('mention', 'all');
    await stable();
    put().flush(null, { status: 204, statusText: 'No Content' });
    expect(push.enable).toHaveBeenCalledTimes(1);
  });

  it('turns quiet hours off and on (the times hide while off)', async () => {
    const { root, put, stable } = await render();
    root.querySelector<HTMLButtonElement>('[data-quiet-toggle] [role="switch"]')!.click();
    await stable();
    const off = put();
    expect(off.request.body).toEqual({ quietHours: { enabled: false, start: '23:00', end: '07:00' }, types: {} });
    off.flush(null, { status: 204, statusText: 'No Content' });
    await stable();
    expect(root.querySelector('#quiet-start')).toBeNull();
    expect(root.querySelector('[data-quiet-toggle] [role="switch"]')!.getAttribute('aria-checked')).toBe('false');
  });

  it('checks the times before saving, and shows the API\'s refusal under them', async () => {
    const { root, put, stable } = await render();
    const start = root.querySelector<HTMLInputElement>('#quiet-start')!;
    const save = () => root.querySelector<HTMLButtonElement>('[data-quiet-save]')!;
    expect(save().disabled).toBe(true);

    // The same time twice is no window at all.
    start.value = '07:00';
    start.dispatchEvent(new Event('input'));
    await stable();
    save().click();
    await stable();
    http.expectNone({ method: 'PUT', url: URL });
    expect(root.querySelector('[data-quiet-error]')!.textContent).toBe('اختر وقتَي بداية ونهاية (HH:mm) مختلفين.');
    expect(start.getAttribute('aria-invalid')).toBe('true');

    start.value = '22:30';
    start.dispatchEvent(new Event('input'));
    await stable();
    expect(root.querySelector('[data-quiet-error]')).toBeNull();
    save().click();
    await stable();
    put().flush(problem(400, 'notification.quiet_hours_invalid'), { status: 400, statusText: 'Bad Request' });
    await stable();
    expect(root.querySelector('[data-quiet-error]')).not.toBeNull();
    expect(start.value).toBe('22:30'); // kept, to fix

    save().click();
    await stable();
    const saved = put();
    expect(saved.request.body).toEqual({ quietHours: { enabled: true, start: '22:30', end: '07:00' }, types: {} });
    saved.flush(null, { status: 204, statusText: 'No Content' });
    await stable();
    expect(root.querySelector('[data-quiet-error]')).toBeNull();
    expect(save().disabled).toBe(true);
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'success' })]);
  });

  it('shows an error state with a retry when the settings cannot load', async () => {
    const fixture = TestBed.createComponent(NotificationSettingsPage);
    fixture.detectChanges();
    http.expectOne(URL).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    await flushMicrotasks();
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    expect(root.querySelector('rd-error-state')!.textContent).toContain('تعذّر تحميل إعدادات الإشعارات');
    root.querySelector<HTMLButtonElement>('rd-error-state button')!.click();
    http.expectOne(URL).flush(settings());
    await flushMicrotasks();
    fixture.detectChanges();
    // A member doesn't get support tickets (F35: support.manage only) or new reports (F22: moderation.manage only).
    expect(root.querySelectorAll('[data-notification-type]')).toHaveLength(CONFIGURABLE_TYPES.length - 2);
  });
});
