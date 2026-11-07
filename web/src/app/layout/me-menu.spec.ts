import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { testMe } from '../../testing/auth-testing';
import { setupSocialTesting, TEST_API } from '../../testing/social-testing';
import { AuthService } from '../core/auth/auth.service';
import { AdminSummaryStore } from '../core/admin/admin-summary.store';
import { ThemeService } from '../core/theme/theme.service';
import { MeMenu } from './me-menu';
import { MeMenuHost } from './me-menu-host';

@Component({ template: '' })
class Blank {}

describe('MeMenu', () => {
  const adminTotal = signal(0);
  let adminRefresh: ReturnType<typeof vi.fn>;
  let host: { closeMeMenu: ReturnType<typeof vi.fn> };
  let auth: { signOut: ReturnType<typeof vi.fn> };

  function render(permissions?: string[], patch: Parameters<typeof testMe>[0] = {}) {
    TestBed.resetTestingModule();
    document.cookie = 'theme=; Path=/; Max-Age=0';
    adminTotal.set(0);
    adminRefresh = vi.fn(() => Promise.resolve());
    host = { closeMeMenu: vi.fn() };
    auth = { signOut: vi.fn(() => Promise.resolve()) };
    const testing = setupSocialTesting({
      providers: [
        { provide: MeMenuHost, useValue: host },
        { provide: AuthService, useValue: auth },
        { provide: AdminSummaryStore, useValue: { total: adminTotal, refresh: adminRefresh } },
        provideRouter([{ path: '**', component: Blank }]),
      ],
    });
    testing.session.setMe(testMe({ ...(permissions ? { permissions } : {}), ...patch }));
    const fixture = TestBed.createComponent(MeMenu);
    fixture.detectChanges();
    return { ...testing, fixture, root: fixture.nativeElement as HTMLElement };
  }

  afterEach(() => {
    document.cookie = 'theme=; Path=/; Max-Age=0';
  });

  it('is a menu: who you are, "View profile", then Settings, My articles and My paths', () => {
    const { root } = render(undefined, { isVerified: true });
    expect(root.getAttribute('role')).toBe('menu');
    expect(root.getAttribute('aria-label')).toBe('أنا');
    expect(root.textContent).toContain('Mona Adel');
    expect(root.textContent).toContain('@mona');
    expect(root.querySelector('svg[aria-label="كاتب موثّق"]')).not.toBeNull();

    const profile = root.querySelector<HTMLAnchorElement>('[data-me-item="profile"]')!;
    expect(profile.getAttribute('href')).toBe('/@mona');
    expect(profile.getAttribute('role')).toBe('menuitem');
    expect(profile.textContent!.trim()).toBe('عرض الملف الشخصي');

    expect(root.querySelector('[data-me-item="settings"]')!.getAttribute('href')).toBe('/settings');
    expect(root.querySelector('[data-me-item="myArticles"]')!.getAttribute('href')).toBe('/write');
    expect(root.querySelector('[data-me-item="myArticles"]')!.textContent!.trim()).toBe('مقالاتي');
    expect(root.querySelector('[data-me-item="myPaths"]')!.getAttribute('href')).toBe('/paths?tab=mine');
    expect(root.querySelector('[data-me-item="myPaths"]')!.textContent!.trim()).toBe('مساراتي');
    // Without the permissions: no admin entries.
    expect(root.querySelector('[data-me-item="admin"]')).toBeNull();
    expect(root.querySelector('a[href^="/admin"]')).toBeNull();
  });

  it('"My articles" needs articles.create', () => {
    const { root } = render(['articles.read']);
    expect(root.querySelector('[data-me-item="myArticles"]')).toBeNull();
  });

  // F23: one entry for the console replaced Moderation (F22) and Verification requests (F19); the queues are inside it.
  it('"Admin console" only with admin.access, with the console badge; opening the menu refreshes it', () => {
    const member = render(['articles.read', 'articles.create', 'moderation.manage', 'verification.manage']).root;
    expect(member.querySelector('[data-me-item="admin"]')).toBeNull();
    expect(member.querySelector('a[href="/moderation"]')).toBeNull();
    expect(member.querySelector('a[href="/admin/verification"]')).toBeNull();

    const { fixture, root } = render(['articles.read', 'admin.access', 'moderation.manage']);
    expect(adminRefresh).toHaveBeenCalledTimes(1);
    const link = root.querySelector<HTMLAnchorElement>('[data-me-item="admin"]')!;
    expect(link.getAttribute('href')).toBe('/admin');
    expect(link.textContent).toContain('لوحة التحكم');
    expect(link.querySelector('[data-admin-badge]')).toBeNull();
    adminTotal.set(4);
    fixture.detectChanges();
    expect(link.querySelector('[data-admin-badge]')!.textContent!.trim()).toBe('4');
    adminTotal.set(140);
    fixture.detectChanges();
    expect(link.querySelector('[data-admin-badge]')!.textContent!.trim()).toBe('99+');
  });

  it('Appearance: Light / Dark / System radios, the current one checked; picking one applies and saves it', () => {
    const { fixture, root, http } = render();
    const radios = Array.from(root.querySelectorAll<HTMLButtonElement>('[role="menuitemradio"]'));
    expect(radios.map((r) => r.textContent!.trim())).toEqual(['حسب الجهاز', 'فاتح', 'داكن']);
    expect(radios.map((r) => r.getAttribute('aria-checked'))).toEqual(['true', 'false', 'false']);
    expect(root.querySelector('[data-me-appearance]')!.getAttribute('aria-labelledby')).toBe('rd-me-menu-appearance');

    root.querySelector<HTMLButtonElement>('[data-me-theme="dark"]')!.click();
    expect(TestBed.inject(ThemeService).preference()).toBe('dark');
    const req = http.expectOne({ method: 'PUT', url: `${TEST_API}/me/preferences` });
    expect(req.request.body.theme).toBe('dark');
    req.flush(null);
    fixture.detectChanges();
    expect(radios.map((r) => r.getAttribute('aria-checked'))).toEqual(['false', 'false', 'true']);
    // Picking a theme keeps the menu open.
    expect(host.closeMeMenu).not.toHaveBeenCalled();
  });

  it('Sign out: the existing sign-out, then Home', async () => {
    const { root } = render();
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigateByUrl');
    root.querySelector<HTMLButtonElement>('[data-me-item="signOut"]')!.click();
    await vi.waitFor(() => expect(navigate).toHaveBeenCalledWith('/'));
    expect(auth.signOut).toHaveBeenCalledTimes(1);
    expect(host.closeMeMenu).toHaveBeenCalledWith(false);
  });

  it('keyboard: the first item takes the focus; arrows, Home and End move it; Escape and Tab close with the focus back', async () => {
    const { root } = render();
    const items = Array.from(root.querySelectorAll<HTMLElement>('[role="menuitem"], [role="menuitemradio"]'));
    await vi.waitFor(() => expect(document.activeElement).toBe(items[0]));
    const key = (k: string) => root.dispatchEvent(new KeyboardEvent('keydown', { key: k, bubbles: true, cancelable: true }));

    key('ArrowDown');
    expect(document.activeElement).toBe(items[1]);
    key('ArrowUp');
    key('ArrowUp');
    expect(document.activeElement).toBe(items[items.length - 1]);
    key('Home');
    expect(document.activeElement).toBe(items[0]);
    key('End');
    expect(document.activeElement!.getAttribute('data-me-item')).toBe('signOut');

    key('Escape');
    expect(host.closeMeMenu).toHaveBeenCalledWith(true);
    key('Tab');
    expect(host.closeMeMenu).toHaveBeenCalledTimes(2);
  });

  it('picking a link closes the menu', () => {
    const { root } = render();
    root.querySelector<HTMLAnchorElement>('[data-me-item="settings"]')!.click();
    expect(host.closeMeMenu).toHaveBeenCalledWith(true);
  });
});
