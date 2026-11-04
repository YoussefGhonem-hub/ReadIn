import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { testProfile } from '../../../testing/profile-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { ProfileHeader } from './profile-header';

async function render(options: { guest?: boolean; permissions?: string[]; isMe?: boolean } = {}) {
  const { http, session, toasts } = setupSocialTesting({ guest: options.guest });
  if (!options.guest) session.setMe(testMe({ permissions: options.permissions ?? ['articles.read', 'reports.create'] }));
  const fixture = TestBed.createComponent(ProfileHeader);
  fixture.componentRef.setInput('profile', testProfile());
  fixture.componentRef.setInput('isMe', !!options.isMe);
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  const openMenu = async () => {
    $('[data-profile-menu]')!.click();
    await stable();
    return [...document.querySelectorAll('[data-profile-menu-panel] [data-menu-action]')].map((el) => el.getAttribute('data-menu-action'));
  };
  const pick = async (action: string) => {
    (document.querySelector(`[data-profile-menu-panel] [data-menu-action="${action}"]`) as HTMLElement).click();
    await stable();
  };
  const note = async (text: string) => {
    const field = $<HTMLTextAreaElement>('[data-moderation-note]')!;
    field.value = text;
    field.dispatchEvent(new Event('input'));
    await stable();
  };
  return { fixture, root, http, toasts, stable, $, openMenu, pick, note };
}

describe('Profile "⋯" menu (F22)', () => {
  let http: HttpTestingController;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    http.verify();
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
  });

  it("is only on someone else's profile", async () => {
    const mine = await render({ isMe: true });
    http = mine.http;
    expect(mine.$('[data-profile-menu]')).toBeNull();
    expect(mine.$('[data-edit-profile]')).not.toBeNull();
  });

  it('members report the user with the shared sheet', async () => {
    const t = await render();
    http = t.http;
    expect(t.$('[data-profile-menu]')!.getAttribute('aria-label')).toBe('خيارات الحساب');
    expect(await t.openMenu()).toEqual(['report']);
    expect(document.querySelector('[data-menu-action="report"]')!.textContent!.trim()).toBe('الإبلاغ عن المستخدم');
    await t.pick('report');
    expect(t.$('[data-report-sheet]')!.getAttribute('data-report-target')).toBe('user');
    t.$<HTMLInputElement>('[data-reason="harassment"]')!.click();
    await t.stable();
    t.$('[data-report-submit]')!.click();
    const req = t.http.expectOne(`${TEST_API}/reports`);
    expect(req.request.body).toEqual({ targetType: 'user', targetId: 'writer-1', reason: 'harassment' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['شكرًا، هنراجع البلاغ']);
  });

  it('guests get the sign-in prompt', async () => {
    const t = await render({ guest: true });
    http = t.http;
    expect(await t.openMenu()).toEqual(['report']);
    await t.pick('report');
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
  });

  it('moderators warn with a required note the user will see', async () => {
    const t = await render({ permissions: ['articles.read', 'moderation.manage'] });
    http = t.http;
    expect(await t.openMenu()).toEqual(['warn', 'report']);
    await t.pick('warn');
    expect(t.$('#moderation-sheet-title')!.textContent!.trim()).toBe('تحذير ⁨Karim Hassan⁩');
    expect(t.$('label[for="moderation-note"]')!.textContent!.trim()).toBe('ملاحظة');
    expect(t.$('#moderation-note-hint')!.textContent).toContain('الملاحظة هتوصل لصاحب الحساب.');
    const confirm = t.$<HTMLButtonElement>('[data-moderation-confirm]')!;
    expect(confirm.disabled).toBe(true);
    await t.note('   ');
    expect(confirm.disabled).toBe(true);
    await t.note('Please keep it civil.');
    expect(confirm.disabled).toBe(false);
    confirm.click();
    const req = t.http.expectOne(`${TEST_API}/moderation/actions`);
    expect(req.request.body).toEqual({ action: 'warn', targetType: 'user', targetId: 'writer-1', note: 'Please keep it civil.' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.$('[data-moderation-sheet]')).toBeNull();
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['التحذير اتبعت']);
  });

  it('with users.suspend: suspend for 1, 7, 30 days or permanently, with a note', async () => {
    const t = await render({ permissions: ['articles.read', 'moderation.manage', 'users.suspend'] });
    http = t.http;
    expect(await t.openMenu()).toEqual(['warn', 'suspend', 'report']);
    await t.pick('suspend');
    expect([...t.root.querySelectorAll('[data-duration]')].map((el) => el.getAttribute('data-duration'))).toEqual(['1', '7', '30', 'permanent']);
    expect(t.$<HTMLInputElement>('[data-duration="7"]')!.checked).toBe(true);
    expect(t.$('[data-suspend-duration]')!.textContent).toContain('نهائي');

    t.$<HTMLInputElement>('[data-duration="30"]')!.click();
    await t.note('Spam links after a warning.');
    t.$('[data-moderation-confirm]')!.click();
    const first = t.http.expectOne(`${TEST_API}/moderation/actions`);
    expect(first.request.body).toEqual({ action: 'suspend', targetType: 'user', targetId: 'writer-1', note: 'Spam links after a warning.', durationDays: 30 });
    first.flush(problem(403, 'moderation.staff_target'), { status: 403, statusText: 'Forbidden' });
    await t.stable();
    expect(t.$('[data-moderation-error]')!.textContent!.trim()).toBe('مينفعش تحذّر أو توقف حد من فريق الإشراف.');

    t.$<HTMLInputElement>('[data-duration="permanent"]')!.click();
    await t.stable();
    t.$('[data-moderation-confirm]')!.click();
    const second = t.http.expectOne(`${TEST_API}/moderation/actions`);
    expect(second.request.body).toEqual({ action: 'suspend', targetType: 'user', targetId: 'writer-1', note: 'Spam links after a warning.', durationDays: null });
    second.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['الحساب اتوقف']);
  });
});
