import { TestBed } from '@angular/core/testing';
import { AdminSummaryStore } from '../../../core/admin/admin-summary.store';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { renderAdmin, testAdminUser, testPage, testUserRow } from '../../../../testing/admin-testing';
import { testMe } from '../../../../testing/auth-testing';
import { TEST_API, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { AdminUsersPage } from './users.page';
import { AdminUserPage } from './user.page';

const params = (req: TestRequest) => Object.fromEntries(req.request.params.keys().map((k) => [k, req.request.params.get(k)]));

describe('Admin console: Users (F23)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    // The console's badge store is not what these pages test.
    const testing = setupSocialTesting({ providers: [{ provide: AdminSummaryStore, useValue: { refresh: () => Promise.resolve() } }] });
    http = testing.http;
    testing.session.setMe(testMe({ permissions: ['admin.access', 'users.read', 'users.read.pii', 'users.suspend', 'moderation.manage', 'audit.read'] }));
  });

  afterEach(() => http.verify());

  it('the table reads its query from the URL (unknown values dropped) and pages through 50 at a time', async () => {
    const t = renderAdmin(AdminUsersPage, { q: ' @sal ', status: 'suspended', verified: 'true', method: 'google', sort: 'lastSeen', dir: 'asc', hasReports: 'true', page: '2', joinedFrom: 'yesterday' });
    const req = http.expectOne((r) => r.url === `${TEST_API}/admin/users`);
    expect(params(req)).toEqual({ q: '@sal', status: 'suspended', verified: 'true', method: 'google', hasReports: 'true', sort: 'lastSeen', dir: 'asc', page: '2', pageSize: '50' });
    req.flush(
      testPage(
        [
          testUserRow(),
          testUserRow({ id: 'u-omar', username: 'omar', displayName: 'Omar', status: 'suspended', suspendedUntil: null, openReports: 2, lastSeenAt: null, isSystemAccount: true }),
        ],
        { page: 2, totalPages: 3, totalCount: 120 },
      ),
    );
    await t.stable();
    const rows = t.$$('[data-user-row]');
    expect(rows.map((r) => r.getAttribute('data-user-row'))).toEqual(['u-salma', 'u-omar']);
    expect(rows[0].querySelector('a')!.getAttribute('href')).toBe('/admin/users/u-salma');
    expect(rows[0].querySelector('[data-phone-masked]')!.textContent).toBe('+20***4567');
    expect(rows[1].querySelector('[data-user-status]')!.textContent).toContain('موقوف نهائيًا');
    expect(t.$('[data-pager-page]')!.textContent).toContain('2');
  });

  it('filters and pages navigate (back to page 1 on a new filter)', async () => {
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    const t = renderAdmin(AdminUsersPage, { page: '2' });
    http.expectOne((r) => r.url === `${TEST_API}/admin/users`).flush(testPage([testUserRow()], { page: 2, totalPages: 3, totalCount: 101 }));
    await t.stable();

    t.type('[data-filter="status"]', 'suspended', 'change');
    expect(navigate).toHaveBeenLastCalledWith(['/admin/users'], { queryParams: { page: null, status: 'suspended' }, queryParamsHandling: 'merge' });
    t.$('[data-pager-next]')!.click();
    expect(navigate).toHaveBeenLastCalledWith(['/admin/users'], { queryParams: { page: 3 }, queryParamsHandling: 'merge' });
    t.type('[data-users-q]', ' +201001234567 ');
    t.$<HTMLFormElement>('[data-users-filters]')!.dispatchEvent(new Event('submit'));
    expect(navigate).toHaveBeenLastCalledWith(['/admin/users'], { queryParams: { page: null, q: '+201001234567' }, queryParamsHandling: 'merge' });
  });

  async function userPage(user = testAdminUser()) {
    const t = renderAdmin(AdminUserPage, { id: user.id });
    http.expectOne(`${TEST_API}/admin/users/${user.id}`).flush(user);
    await t.stable();
    return t;
  }

  it("a user's page: profile, stats, and only the actions `actions` allows", async () => {
    const t = await userPage();
    expect(t.$('[data-user-profile]')!.textContent).toContain('Salma Nabil');
    expect(t.$('[data-user-headline]')!.textContent).toContain('Backend engineer');
    expect(t.$$('[data-user-action]').map((b) => b.getAttribute('data-user-action'))).toEqual([
      'suspend',
      'warn',
      'hideContent',
      'resetPassword',
      'logoutAll',
      'clearHeadline',
    ]);
    expect(t.$('[data-user-moderation]')).not.toBeNull();
    expect(t.$('[data-user-articles]')!.getAttribute('href')).toBe('/admin/content?writer=u-salma');
  });

  it('a protected account (staff) has no actions and says why; sections without the permission are left out', async () => {
    const none = { canSuspend: false, canWarn: false, canLogoutAll: false, canResetPassword: false, canRemoveBadge: false, canClearProfile: false, canRestoreContent: false, canRevealPhone: false };
    const t = await userPage(testAdminUser({ isStaff: true, actions: none, moderation: null, reports: null, tickets: null, audit: null, verification: null }));
    expect(t.$$('[data-user-action]').length).toBe(0);
    expect(t.$('[data-user-no-actions]')!.textContent).toContain('لا يمكن إيقاف');
    expect(t.$('[data-user-moderation]')).toBeNull();
    expect(t.$('[data-user-tickets]')).toBeNull();
    expect(t.$('[data-phone-reveal]')).toBeNull();
  });

  it('a suspended account offers Unsuspend; flagged content offers Restore', async () => {
    const user = testAdminUser({ status: 'suspended', suspendedUntil: '2026-11-20T00:00:00Z', actions: { ...testAdminUser().actions, canRestoreContent: true } });
    const t = await userPage(user);
    const ids = t.$$('[data-user-action]').map((b) => b.getAttribute('data-user-action'));
    expect(ids).toContain('unsuspend');
    expect(ids).toContain('restoreContent');
    expect(ids).not.toContain('suspend');
  });

  it('"Show" reveals the phone number once (audited by the API)', async () => {
    const t = await userPage();
    t.$('[data-phone-reveal]')!.click();
    http.expectOne(`${TEST_API}/admin/users/u-salma/phone`).flush({ phoneNumber: '+201001234567' });
    await t.stable();
    expect(t.$('[data-phone-full]')!.textContent).toBe('+201001234567');
  });

  it('suspend uses the moderation form: 3 days, a reason of 5+ characters, hiding all content too', async () => {
    const t = await userPage();
    t.$('[data-user-action="suspend"]')!.click();
    await t.stable();
    expect(t.$$('[data-duration]').map((d) => d.getAttribute('data-duration'))).toEqual(['1', '3', '7', '30', 'custom', 'permanent']);
    t.$<HTMLInputElement>('[data-duration="custom"]')!.click();
    await t.stable();
    t.type('[data-custom-days]', '400');
    t.type('[data-moderation-note]', 'Spam');
    const confirm = t.$<HTMLButtonElement>('[data-moderation-confirm]')!;
    expect(confirm.disabled).toBe(true); // 400 days and a 4-character reason
    t.type('[data-custom-days]', '90');
    expect(confirm.disabled).toBe(true);
    t.type('[data-moderation-note]', 'Spam links');
    await t.stable();
    expect(confirm.disabled).toBe(false);
    t.$<HTMLInputElement>('[data-hide-content] input')!.click();
    await t.stable();
    confirm.click();
    const req = http.expectOne(`${TEST_API}/moderation/actions`);
    expect(req.request.body).toEqual({ action: 'suspend', targetType: 'user', targetId: 'u-salma', note: 'Spam links', durationDays: 90, hideContent: true });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    // The page loads again.
    http.expectOne(`${TEST_API}/admin/users/u-salma`).flush(testAdminUser({ status: 'suspended' }));
    await t.stable();
  });

  it('reset password: asks first, then shows the temporary password once', async () => {
    const t = await userPage();
    t.$('[data-user-action="resetPassword"]')!.click();
    await t.stable();
    expect(t.$('[data-admin-confirm]')!.textContent).toContain('هل تريد إعادة تعيين كلمة مرور');
    t.$('[data-confirm-ok]')!.click();
    http.expectOne({ method: 'POST', url: `${TEST_API}/admin/users/u-salma/reset-password` }).flush({ temporaryPassword: 'Tmp-4821-xq' });
    await t.stable();
    expect(t.$('[data-temp-password-value]')!.textContent).toBe('Tmp-4821-xq');
    http.expectOne(`${TEST_API}/admin/users/u-salma`).flush(testAdminUser());
    await t.stable();
  });

  it('sign out of all devices: a refusal stays in the dialog', async () => {
    const t = await userPage();
    t.$('[data-user-action="logoutAll"]')!.click();
    await t.stable();
    t.$('[data-confirm-ok]')!.click();
    http.expectOne(`${TEST_API}/admin/users/u-salma/logout-all`).flush(problem(403, 'moderation.staff_target'), { status: 403, statusText: 'Forbidden' });
    await t.stable();
    expect(t.$('[data-confirm-error]')!.textContent).toContain('فريق الإشراف');
  });

  it('an unknown user is "not found"', async () => {
    const t = renderAdmin(AdminUserPage, { id: 'nobody' });
    http.expectOne(`${TEST_API}/admin/users/nobody`).flush(problem(404, 'user.not_found'), { status: 404, statusText: 'Not Found' });
    await t.stable();
    expect(t.$('[data-user-not-found]')).not.toBeNull();
  });
});
