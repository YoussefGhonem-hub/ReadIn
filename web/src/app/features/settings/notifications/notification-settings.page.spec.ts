import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { NotificationSettingsDto } from '../../../core/api/models';
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
    expect([...root.querySelectorAll('[data-notification-type]')].map((e) => e.getAttribute('data-notification-type'))).toEqual([...CONFIGURABLE_TYPES]);
    expect(typeRow('mention').getAttribute('data-mode')).toBe('off');
    expect(typeRow('daily_article').getAttribute('data-mode')).toBe('inApp');
    expect(typeRow('new_follower').getAttribute('data-mode')).toBe('all');
    expect(typeRow('mention').textContent).toContain('المنشن');
    expect(root.querySelector('[data-notification-types]')!.textContent).toContain('تنبيهات الأمان وإشعارات فريق الإشراف مش بتتقفل');
    expect(root.querySelector<HTMLInputElement>('#quiet-start')!.value).toBe('23:00');
    expect(root.querySelector<HTMLInputElement>('#quiet-end')!.value).toBe('07:00');
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
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'error', message: 'اختار الكل أو جوه التطبيق أو مقفول.' })]);
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
    expect(root.querySelector('[data-quiet-error]')!.textContent).toBe('اختار وقت بداية ووقت نهاية (HH:mm) مختلفين.');
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
    expect(root.querySelector('rd-error-state')!.textContent).toContain('معرفناش نحمّل إعدادات الإشعارات');
    root.querySelector<HTMLButtonElement>('rd-error-state button')!.click();
    http.expectOne(URL).flush(settings());
    await flushMicrotasks();
    fixture.detectChanges();
    expect(root.querySelectorAll('[data-notification-type]')).toHaveLength(CONFIGURABLE_TYPES.length);
  });
});
