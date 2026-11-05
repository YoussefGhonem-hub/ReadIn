import { signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { testNotification } from '../../../testing/notifications-testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { NotificationDto } from '../../core/api/models';
import { ModerationNotices } from '../../core/moderation/moderation-notices';
import { NotificationBadge } from '../../core/notifications/notification-badge';
import { NotificationsMenu } from './notifications-menu';
import { PANEL_ITEMS } from './notifications-panel';

const LIST = `${TEST_API}/me/notifications`;

const many = (count: number): NotificationDto[] =>
  Array.from({ length: count }, (_, i) => testNotification({ id: `n-${i + 1}`, isRead: i > 1, updatedAt: '2026-11-04T09:40:00Z' }));

describe('NotificationsMenu (F17 dropdown)', () => {
  let http: HttpTestingController;
  const badge = { count: signal(0), markSeen: vi.fn(async () => undefined), markRead: vi.fn(async () => undefined), refresh: vi.fn(async () => undefined) };
  const notices = { reload: vi.fn() };

  function setup(guest = false) {
    TestBed.resetTestingModule();
    badge.count.set(0);
    vi.clearAllMocks();
    ({ http } = setupSocialTesting({
      guest,
      providers: [
        { provide: NotificationBadge, useValue: badge },
        { provide: ModerationNotices, useValue: notices },
      ],
    }));
  }

  afterEach(() => http.verify());

  async function render(variant: 'icon' | 'stacked' = 'icon') {
    const fixture = TestBed.createComponent(NotificationsMenu);
    fixture.componentRef.setInput('variant', variant);
    fixture.detectChanges();
    await fixture.whenStable();
    const root = fixture.nativeElement as HTMLElement;
    return { fixture, root, trigger: () => root.querySelector<HTMLElement>('[data-notifications-link]')! };
  }

  /** Opens the dropdown, lets the panel's chunk load and answers its first page. */
  async function open(fixture: ComponentFixture<NotificationsMenu>, items: NotificationDto[]) {
    const root = fixture.nativeElement as HTMLElement;
    root.querySelector<HTMLButtonElement>('[data-notifications-link]')!.click();
    fixture.detectChanges();
    await vi.waitFor(() => {
      fixture.detectChanges();
      expect(root.querySelector('[data-notifications-panel]')).not.toBeNull();
    });
    http.expectOne((r) => r.url === LIST).flush({ items, nextCursor: null });
    await flushMicrotasks();
    fixture.detectChanges();
    return root;
  }

  it('is a plain link to the center for guests', async () => {
    setup(true);
    const { root, trigger } = await render();
    expect(trigger().tagName).toBe('A');
    expect(trigger().getAttribute('href')).toBe('/notifications');
    expect(root.querySelector('button')).toBeNull();
  });

  it('is a bell button for members: the unread dot, a label that says how many are new, closed at first', async () => {
    setup();
    badge.count.set(3);
    const { root, trigger } = await render();
    expect(trigger().tagName).toBe('BUTTON');
    expect(trigger().getAttribute('aria-expanded')).toBe('false');
    expect(trigger().getAttribute('aria-haspopup')).toBe('dialog');
    expect(trigger().getAttribute('aria-label')).toBe('الإشعارات، 3 إشعارات جديدة'); // the test UI is Arabic
    expect(root.querySelector('[data-unread-badge]')).not.toBeNull();
    expect(root.querySelector('[data-notifications-dropdown]')).toBeNull();
  });

  it(`opens a panel with the latest ${PANEL_ITEMS} notifications, marks them seen and links to the center`, async () => {
    setup();
    const { fixture, trigger } = await render();
    const root = await open(fixture, many(12));

    expect(trigger().getAttribute('aria-expanded')).toBe('true');
    const dialog = root.querySelector('[data-notifications-dropdown]')!;
    expect(dialog.getAttribute('role')).toBe('dialog');
    expect(trigger().getAttribute('aria-controls')).toBe(dialog.id);
    expect(badge.markSeen).toHaveBeenCalledTimes(1);
    expect(root.querySelectorAll('[data-notification]').length).toBe(PANEL_ITEMS);
    expect(root.querySelector('[data-mark-all-read]')).not.toBeNull();
    expect(root.querySelector('[data-see-all]')?.getAttribute('href')).toBe('/notifications');
  });

  it('shows the empty state when there is nothing yet', async () => {
    setup();
    const { fixture } = await render();
    const root = await open(fixture, []);
    expect(root.querySelector('[data-panel-empty]')).not.toBeNull();
    expect(root.querySelector('[data-mark-all-read]')).toBeNull();
  });

  it('Escape closes it and gives the focus back to the bell', async () => {
    setup();
    const { fixture, trigger } = await render();
    const root = await open(fixture, many(2));

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    fixture.detectChanges();
    expect(root.querySelector('[data-notifications-dropdown]')).toBeNull();
    expect(document.activeElement).toBe(trigger());
  });

  it('a click outside closes it', async () => {
    setup();
    const { fixture } = await render();
    const root = await open(fixture, many(2));

    document.body.dispatchEvent(new Event('pointerdown', { bubbles: true }));
    fixture.detectChanges();
    expect(root.querySelector('[data-notifications-dropdown]')).toBeNull();
  });

  it('opening a row marks it read and closes the dropdown', async () => {
    setup();
    const { fixture } = await render();
    const root = await open(fixture, many(3));

    const navigate = vi.spyOn(TestBed.inject(Router), 'navigateByUrl').mockResolvedValue(true);
    root.querySelector<HTMLElement>('[data-notification="n-1"]')!.click();
    await flushMicrotasks();
    fixture.detectChanges();
    expect(badge.markRead).toHaveBeenCalledWith('n-1');
    expect(navigate).toHaveBeenCalledWith('/en/a/clean-code#comment-c9'); // the row's comment
    expect(root.querySelector('[data-notifications-dropdown]')).toBeNull();
  });

  it('the stacked navbar item has the icon above a label, and the dot', async () => {
    setup();
    badge.count.set(1);
    const { root, trigger } = await render('stacked');
    expect(trigger().textContent).toContain('الإشعارات');
    expect(trigger().classList.contains('flex-col')).toBe(true);
    expect(root.querySelector('[data-unread-badge]')).not.toBeNull();
  });
});
