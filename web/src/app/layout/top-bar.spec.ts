import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { testMe } from '../../testing/auth-testing';
import { setupSocialTesting } from '../../testing/social-testing';
import { ModerationSummaryStore } from '../core/moderation/moderation-summary.store';
import { NotificationBadge } from '../core/notifications/notification-badge';
import { TopBar } from './top-bar';

@Component({ template: '' })
class Blank {}

const settle = async (fixture: { whenStable(): Promise<unknown>; detectChanges(): void }) => {
  for (let i = 0; i < 4; i++) {
    await fixture.whenStable();
    fixture.detectChanges();
  }
};

describe('TopBar', () => {
  const count = signal(0);
  const moderationTotal = signal(0);

  function render(options: { guest?: boolean; permissions?: string[] } = {}) {
    TestBed.resetTestingModule();
    count.set(0);
    moderationTotal.set(0);
    const { session } = setupSocialTesting({
      guest: options.guest,
      providers: [
        { provide: NotificationBadge, useValue: { count } },
        { provide: ModerationSummaryStore, useValue: { total: moderationTotal, canModerate: signal((options.permissions ?? []).includes('moderation.manage')) } },
        provideRouter([
          { path: 'explore', component: Blank },
          { path: 'paths', component: Blank },
        ]),
      ],
    });
    if (options.permissions) session.setMe(testMe({ permissions: options.permissions }));
    const fixture = TestBed.createComponent(TopBar);
    fixture.detectChanges();
    return { fixture, root: fixture.nativeElement as HTMLElement };
  }

  describe('notifications bell (F17)', () => {
    it('shows a dot while there are unseen notifications, and says how many to screen readers', () => {
      const { fixture, root } = render();
      // Signed in, the bell opens the dropdown (features/notifications/notifications-menu.ts).
      const bell = root.querySelector<HTMLElement>('[data-notifications-link]')!;
      expect(bell.tagName).toBe('BUTTON');
      expect(bell.getAttribute('aria-haspopup')).toBe('dialog');
      expect(bell.querySelector('[data-unread-badge]')).toBeNull();
      expect(bell.getAttribute('aria-label')).toBe('الإشعارات');

      count.set(3);
      fixture.detectChanges();
      expect(bell.querySelector('[data-unread-badge]')).not.toBeNull();
      expect(bell.getAttribute('aria-label')).toBe('الإشعارات، 3 إشعارات جديدة');

      count.set(0); // the center was opened
      fixture.detectChanges();
      expect(bell.querySelector('[data-unread-badge]')).toBeNull();
    });

    it('is a link to the center for guests, in the nav row and in the compact bar', () => {
      const { root } = render({ guest: true });
      const bells = Array.from(root.querySelectorAll<HTMLAnchorElement>('[data-notifications-link]'));
      expect(bells.length).toBe(2);
      for (const bell of bells) expect(bell.getAttribute('href')).toBe('/notifications');
      expect(root.querySelector('[data-top-nav] rd-notifications-menu')).not.toBeNull();
    });
  });

  it('search (F16): the box on wide screens (a link to the search page until it loads), the icon on narrow ones; none on the search page', () => {
    const { fixture, root } = render();
    const placeholder = root.querySelector<HTMLAnchorElement>('[data-header-search-placeholder]')!;
    expect(placeholder.getAttribute('href')).toBe('/search');
    expect(placeholder.textContent!.trim()).toBe('دوّر في ReadIn');
    const icon = root.querySelector<HTMLAnchorElement>('[data-search-link]')!;
    expect(icon.getAttribute('href')).toBe('/search');
    expect(icon.getAttribute('aria-label')).toBe('بحث');

    fixture.componentRef.setInput('searchBox', false);
    fixture.detectChanges();
    expect(root.querySelector('[data-header-search-placeholder]')).toBeNull();
    expect(root.querySelector('[data-search-link]')).toBeNull();
  });

  it('nav row: Home, Explore, Paths, Saved, Notifications, Write, each an icon with its label; the current one is marked', async () => {
    const { fixture, root } = render();
    const nav = root.querySelector<HTMLElement>('[data-top-nav]')!;
    expect(nav.getAttribute('aria-label')).toBe('التنقل الرئيسي');
    const links = Array.from(nav.querySelectorAll<HTMLAnchorElement>('a[data-nav]'));
    expect(links.map((a) => a.getAttribute('href'))).toEqual(['/', '/explore', '/paths', '/saved', '/write']);
    expect(links.map((a) => a.textContent!.trim())).toEqual(['الرئيسية', 'استكشف', 'المسارات', 'المحفوظات', 'اكتب']);
    // The bell sits between Saved and Write.
    const order = Array.from(nav.querySelectorAll('a[data-nav], rd-notifications-menu')).map((el) => el.getAttribute('data-nav') ?? 'notifications');
    expect(order).toEqual(['home', 'explore', 'paths', 'saved', 'notifications', 'write']);

    await TestBed.inject(Router).navigateByUrl('/paths');
    await settle(fixture);
    const paths = nav.querySelector<HTMLAnchorElement>('a[data-nav="paths"]')!;
    expect(paths.getAttribute('aria-current')).toBe('page');
    expect(paths.classList).toContain('text-text-primary');
    expect(nav.querySelector('a[data-nav="explore"]')!.getAttribute('aria-current')).toBeNull();
    expect(nav.querySelector('a[data-nav="explore"]')!.classList).toContain('text-text-secondary');
  });

  it('guests: the theme toggle and "Sign in", no Me', () => {
    const { root } = render({ guest: true });
    expect(root.querySelectorAll('[data-theme-toggle]').length).toBe(2);
    expect(root.querySelector('[data-me-trigger]')).toBeNull();
    const signIn = Array.from(root.querySelectorAll<HTMLAnchorElement>('a[href="/auth/sign-in"]'));
    expect(signIn.length).toBe(2);
    expect(signIn[0].textContent!.trim()).toBe('تسجيل الدخول');
  });

  it('signed in: Me opens its menu (loaded on demand), Escape closes it and gives the focus back', async () => {
    const { fixture, root } = render();
    expect(root.querySelector('a[href="/auth/sign-in"]')).toBeNull();
    const me = root.querySelector<HTMLButtonElement>('[data-me-trigger="stacked"]')!;
    expect(me.getAttribute('aria-haspopup')).toBe('menu');
    expect(me.getAttribute('aria-expanded')).toBe('false');
    expect(me.textContent).toContain('أنا');

    me.click();
    fixture.detectChanges();
    expect(me.getAttribute('aria-expanded')).toBe('true');
    await settle(fixture);
    await vi.waitFor(() => {
      fixture.detectChanges();
      expect(root.querySelector('[data-me-menu]')).not.toBeNull();
    });
    expect(me.getAttribute('aria-controls')).toBe('rd-me-menu');
    expect(root.querySelector('[data-me-item="profile"]')!.getAttribute('href')).toBe('/@mona');

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    fixture.detectChanges();
    expect(root.querySelector('[data-me-menu]')).toBeNull();
    expect(me.getAttribute('aria-expanded')).toBe('false');
    expect(document.activeElement).toBe(me);
  });

  it('a click outside closes the Me menu; the narrow bar has its own Me button', async () => {
    const { fixture, root } = render();
    const narrow = root.querySelector<HTMLButtonElement>('[data-me-trigger="icon"]')!;
    expect(narrow.querySelector('.sr-only')!.textContent!.trim()).toBe('أنا');
    narrow.click();
    fixture.detectChanges();
    expect(narrow.getAttribute('aria-expanded')).toBe('true');

    document.body.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
    fixture.detectChanges();
    expect(narrow.getAttribute('aria-expanded')).toBe('false');
    expect(root.querySelector('[data-me-menu-panel]')).toBeNull();
  });

  it('moderators see a dot on Me while reports are open (the count is in the menu)', () => {
    const { fixture, root } = render({ permissions: ['articles.read', 'moderation.manage'] });
    expect(root.querySelector('[data-me-attention]')).toBeNull();
    moderationTotal.set(4);
    fixture.detectChanges();
    expect(root.querySelectorAll('[data-me-attention]').length).toBe(2);
  });
});
