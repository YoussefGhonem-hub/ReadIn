import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { testProfile } from '../../../testing/profile-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ProfileDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { MuteStore } from '../../core/social/mute.store';
import { ProfileHeader } from './profile-header';

async function render(options: { guest?: boolean; permissions?: string[]; isMe?: boolean; profile?: Partial<ProfileDto> } = {}) {
  const { http, session, toasts } = setupSocialTesting({ guest: options.guest });
  if (!options.guest) session.setMe(testMe({ permissions: options.permissions ?? ['articles.read', 'reports.create'] }));
  const fixture = TestBed.createComponent(ProfileHeader);
  fixture.componentRef.setInput('profile', testProfile(options.profile));
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

describe('Profile "⋯" menu (F22, F28)', () => {
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
    expect(await t.openMenu()).toEqual(['muteUser', 'blockUser', 'report']);
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
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['شكرًا، سنراجع البلاغ']);
  });

  it('guests get the sign-in prompt', async () => {
    const t = await render({ guest: true });
    http = t.http;
    expect(await t.openMenu()).toEqual(['muteUser', 'blockUser', 'report']);
    await t.pick('report');
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
  });

  it('guests get the sign-in prompt for Mute user too', async () => {
    const t = await render({ guest: true });
    http = t.http;
    await t.openMenu();
    await t.pick('muteUser');
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
    t.http.expectNone(`${TEST_API}/users/writer-1/mute`);
  });

  it('Mute user mutes them like Mute author: the toast has Undo, which follows again when the mute ended your follow', async () => {
    const t = await render();
    http = t.http;
    const mutes = TestBed.inject(MuteStore);
    await t.openMenu();
    expect(document.querySelector('[data-menu-action="muteUser"]')!.textContent!.trim()).toBe('كتم المستخدم');
    await t.pick('muteUser');
    expect(mutes.isAuthorMuted('writer-1')).toBe(true);
    const put = t.http.expectOne(`${TEST_API}/users/writer-1/mute`);
    expect(put.request.method).toBe('PUT');
    put.flush({ isMuted: true, isFollowing: false, followerCount: 40, followRemoved: true });
    await t.stable();
    const [toast] = t.toasts.toasts();
    expect(toast.message.startsWith('تم كتم ')).toBe(true);
    expect(toast.message).toContain('Karim Hassan');
    expect(toast.action!.label).toBe('تراجع');

    // The menu now offers to unmute.
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
    await t.openMenu();
    expect(document.querySelector('[data-menu-action="muteUser"]')!.textContent!.trim()).toBe('إلغاء كتم المستخدم');
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));

    toast.action!.run();
    expect(mutes.isAuthorMuted('writer-1')).toBe(false);
    const undo = t.http.expectOne(`${TEST_API}/users/writer-1/mute?restoreFollow=true`);
    expect(undo.request.method).toBe('DELETE');
    undo.flush({ isMuted: false, isFollowing: true, followerCount: 41, followRemoved: false });
    await t.stable();
  });

  it('a muted user is unmuted from the menu, with the unmute toast', async () => {
    const t = await render({ profile: { isMuted: true } });
    http = t.http;
    await t.openMenu();
    await t.pick('muteUser');
    const del = t.http.expectOne(`${TEST_API}/users/writer-1/mute`);
    expect(del.request.method).toBe('DELETE');
    del.flush({ isMuted: false, isFollowing: false, followerCount: 40, followRemoved: false });
    await t.stable();
    expect(TestBed.inject(MuteStore).isAuthorMuted('writer-1', true)).toBe(false);
    const messages = t.toasts.toasts().map((toast) => toast.message);
    expect(messages).toHaveLength(1);
    expect(messages[0].startsWith('تم إلغاء كتم ')).toBe(true);
  });

  it("the official ReadIn account can't be muted: no Mute item", async () => {
    const t = await render({ profile: { isSystemAccount: true } });
    http = t.http;
    expect(await t.openMenu()).toEqual(['blockUser', 'report']);
  });

  it('moderators warn with a required note the user will see', async () => {
    const t = await render({ permissions: ['articles.read', 'moderation.manage'] });
    http = t.http;
    expect(await t.openMenu()).toEqual(['muteUser', 'blockUser', 'warn', 'report']);
    await t.pick('warn');
    expect(t.$('#moderation-sheet-title')!.textContent!.trim()).toBe('تحذير ⁨Karim Hassan⁩');
    expect(t.$('label[for="moderation-note"]')!.textContent!.trim()).toBe('ملاحظة');
    expect(t.$('#moderation-note-hint')!.textContent).toContain('ستصل الملاحظة إلى صاحب الحساب.');
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
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['تم إرسال التحذير']);
  });

  // F23 changed the form: 1, 3, 7 or 30 days, a custom 1–365, or permanently.
  it('with users.suspend: suspend for 1, 3, 7, 30 days, a custom length or permanently, with a note', async () => {
    const t = await render({ permissions: ['articles.read', 'moderation.manage', 'users.suspend'] });
    http = t.http;
    expect(await t.openMenu()).toEqual(['muteUser', 'blockUser', 'warn', 'suspend', 'report']);
    await t.pick('suspend');
    expect([...t.root.querySelectorAll('[data-duration]')].map((el) => el.getAttribute('data-duration'))).toEqual(['1', '3', '7', '30', 'custom', 'permanent']);
    expect(t.$<HTMLInputElement>('[data-duration="7"]')!.checked).toBe(true);
    expect(t.$('[data-suspend-duration]')!.textContent).toContain('نهائي');

    t.$<HTMLInputElement>('[data-duration="30"]')!.click();
    await t.note('Spam links after a warning.');
    t.$('[data-moderation-confirm]')!.click();
    const first = t.http.expectOne(`${TEST_API}/moderation/actions`);
    expect(first.request.body).toEqual({ action: 'suspend', targetType: 'user', targetId: 'writer-1', note: 'Spam links after a warning.', durationDays: 30 });
    first.flush(problem(403, 'moderation.staff_target'), { status: 403, statusText: 'Forbidden' });
    await t.stable();
    expect(t.$('[data-moderation-error]')!.textContent!.trim()).toBe('لا يمكنك تحذير أحد أعضاء فريق الإشراف أو إيقافه.');

    t.$<HTMLInputElement>('[data-duration="permanent"]')!.click();
    await t.stable();
    t.$('[data-moderation-confirm]')!.click();
    const second = t.http.expectOne(`${TEST_API}/moderation/actions`);
    expect(second.request.body).toEqual({ action: 'suspend', targetType: 'user', targetId: 'writer-1', note: 'Spam links after a warning.', durationDays: null });
    second.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['تم إيقاف الحساب']);
  });

  // F23: the console's actions in the profile "⋯".
  it('admins: Unsuspend a suspended account, Remove verified badge (asks first), Open in console', async () => {
    const ADMIN = ['articles.read', 'moderation.manage', 'users.suspend', 'verification.manage', 'users.read', 'admin.access'];
    const t = await render({ permissions: ADMIN, profile: { admin: { isSuspended: true, suspendedUntil: null, isStaff: false } } });
    http = t.http;
    expect(await t.openMenu()).toEqual(['muteUser', 'blockUser', 'warn', 'unsuspend', 'removeBadge', 'openInConsole', 'report']);
    await t.pick('removeBadge');
    t.$('[data-remove-badge-confirm]')!.click();
    t.http.expectOne({ method: 'DELETE', url: `${TEST_API}/admin/users/writer-1/verification` }).flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.$('[data-remove-badge-sheet]')).toBeNull();
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
    expect(await t.openMenu()).not.toContain('removeBadge');
  });

  it("staff can't be warned or suspended (ProfileDto.admin.isStaff)", async () => {
    const t = await render({ permissions: ['articles.read', 'moderation.manage', 'users.suspend', 'users.read'], profile: { admin: { isSuspended: false, suspendedUntil: null, isStaff: true } } });
    http = t.http;
    expect(await t.openMenu()).toEqual(['muteUser', 'blockUser', 'report']);
  });
});
