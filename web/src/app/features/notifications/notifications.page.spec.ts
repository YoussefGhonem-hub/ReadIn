import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { testNotification } from '../../../testing/notifications-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { NotificationDto } from '../../core/api/models';
import { ModerationNotices } from '../../core/moderation/moderation-notices';
import { NotificationBadge } from '../../core/notifications/notification-badge';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { NotificationsPage } from './notifications.page';

const LIST = `${TEST_API}/me/notifications`;
/** 12:00 in Cairo (the test user's time zone). */
const NOW = new Date('2026-11-04T10:00:00Z');

const page = (items: NotificationDto[], nextCursor: string | null = null) => ({ items, nextCursor });

const FIXTURES: NotificationDto[] = [
  testNotification({ id: 'n-comments', actorCount: 10, updatedAt: '2026-11-04T09:40:00Z' }),
  testNotification({
    id: 'n-reply',
    type: 'comment_reply',
    actor: null,
    isRead: true,
    article: { id: 'a2', slug: 'transformers', title: 'يعني إيه Transformer؟', language: 'ar-EG' },
    comment: { id: 'c2', parentId: 'c1', excerpt: 'متفق معاك جدًا' },
    link: 'readin://a/transformers#comment-c2',
    updatedAt: '2026-11-03T22:30:00Z', // 00:30 on the 4th in Cairo: still today
  }),
  testNotification({
    id: 'n-warning',
    type: 'moderation_notice',
    actor: null,
    actorCount: 0,
    article: null,
    comment: null,
    link: 'readin://notifications',
    updatedAt: '2026-11-03T21:00:00Z', // 23:00 on the 3rd in Cairo
  }),
];

describe('NotificationsPage (F17)', () => {
  let http: HttpTestingController;
  const badge = { count: signal(0), markSeen: vi.fn(async () => undefined), markRead: vi.fn(async () => undefined), refresh: vi.fn(async () => undefined) };
  const notices = { reload: vi.fn() };

  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(NOW);
    TestBed.resetTestingModule();
    badge.count.set(0);
    vi.clearAllMocks();
    ({ http } = setupSocialTesting({
      providers: [
        { provide: NotificationBadge, useValue: badge },
        { provide: ModerationNotices, useValue: notices },
      ],
    }));
  });

  afterEach(() => {
    vi.useRealTimers();
    http.verify();
  });

  async function render(first = page(FIXTURES)) {
    const fixture = TestBed.createComponent(NotificationsPage);
    fixture.detectChanges();
    const request = http.expectOne((r) => r.url === LIST);
    expect(request.request.params.get('limit')).toBe('20');
    expect(request.request.params.has('cursor')).toBe(false);
    request.flush(first);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
    };
    await stable();
    const row = (id: string) => root.querySelector<HTMLElement>(`[data-notification="${id}"]`)!;
    return { fixture, root, stable, row, store: (fixture.componentInstance as unknown as { store: { loadMore(): Promise<void> } }).store };
  }

  it('opening it marks everything seen (the badge clears) and lists Today / Earlier in the user\'s day', async () => {
    const { root, row } = await render();
    expect(badge.markSeen).toHaveBeenCalledTimes(1);

    const today = root.querySelector('[data-section="today"]')!;
    const earlier = root.querySelector('[data-section="earlier"]')!;
    expect([...today.querySelectorAll('[data-notification]')].map((e) => e.getAttribute('data-notification'))).toEqual(['n-comments', 'n-reply']);
    expect([...earlier.querySelectorAll('[data-notification]')].map((e) => e.getAttribute('data-notification'))).toEqual(['n-warning']);
    expect(root.querySelector('#notifications-today')!.textContent!.trim()).toBe('اليوم');
    expect(root.querySelector('#notifications-earlier')!.textContent!.trim()).toBe('سابقًا');

    // "X and N others", the actor in bold; the article in its own direction; the comment excerpt.
    const comments = row('n-comments');
    expect(comments.querySelector('[data-notification-text]')!.textContent).toBe('علّق Ahmed Samir و9 آخرون على مقالك');
    expect(comments.querySelector('[data-notification-text] strong bdi')!.textContent).toBe('Ahmed Samir');
    expect(comments.querySelector('[data-notification-article]')!.getAttribute('lang')).toBe('en');
    expect(comments.querySelector('[data-notification-article] rd-bdi-text')!.getAttribute('dir')).toBe('ltr');
    expect(comments.querySelector('[data-notification-comment]')!.textContent!.trim()).toBe('Great read!');
    expect(comments.querySelector('[data-notification-comment]')!.getAttribute('dir')).toBe('ltr');
    expect(comments.getAttribute('href')).toBe('/en/a/clean-code#comment-c9');
    expect(comments.hasAttribute('data-unread')).toBe(true);
    expect(comments.className).toContain('bg-primary-container');

    const reply = row('n-reply');
    expect(reply.querySelector('[data-notification-text]')!.textContent).toBe('ردّ مستخدم محذوف على تعليقك');
    expect(reply.querySelector('[data-generic-avatar]')).not.toBeNull();
    expect(reply.querySelector('[data-notification-article]')!.getAttribute('dir')).toBe('rtl');
    expect(reply.querySelector('[data-notification-comment]')!.getAttribute('dir')).toBe('rtl');
    expect(reply.getAttribute('href')).toBe('/ar/a/transformers#comment-c2');
    expect(reply.hasAttribute('data-unread')).toBe(false);
  });

  it('tapping a row marks it read and opens its link; a moderation warning opens its dialog', async () => {
    const { row, stable } = await render();
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigateByUrl').mockResolvedValue(true);

    row('n-comments').click();
    await stable();
    expect(badge.markRead).toHaveBeenCalledWith('n-comments');
    expect(navigate).toHaveBeenCalledWith('/en/a/clean-code#comment-c9');
    expect(row('n-comments').hasAttribute('data-unread')).toBe(false);

    // Already read: nothing to send again.
    row('n-reply').click();
    expect(badge.markRead).toHaveBeenCalledTimes(1);

    const warning = row('n-warning');
    expect(warning.tagName).toBe('BUTTON');
    warning.click();
    await stable();
    expect(badge.markRead).toHaveBeenLastCalledWith('n-warning');
    expect(notices.reload).toHaveBeenCalledTimes(1);
  });

  it('a ctrl/⌘ click leaves the new tab to the browser, but still marks it read', async () => {
    const { row } = await render();
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigateByUrl').mockResolvedValue(true);
    const click = new MouseEvent('click', { bubbles: true, cancelable: true, ctrlKey: true });
    const stopJsdomNavigation = (event: Event) => event.preventDefault(); // jsdom can't open a new tab
    document.addEventListener('click', stopJsdomNavigation);
    row('n-comments').dispatchEvent(click);
    document.removeEventListener('click', stopJsdomNavigation);
    expect(badge.markRead).toHaveBeenCalledWith('n-comments');
    expect(navigate).not.toHaveBeenCalled();
  });

  it('"Mark all as read" marks every row at once; a failure puts them back and says why', async () => {
    const { root, stable, row } = await render(page([...FIXTURES, testNotification({ id: 'n-more', updatedAt: '2026-11-01T09:00:00Z' })]));
    const button = root.querySelector<HTMLButtonElement>('[data-mark-all-read]')!;
    expect(button.disabled).toBe(false);

    button.click();
    await stable();
    expect(root.querySelectorAll('[data-unread]')).toHaveLength(0);
    http.expectOne({ method: 'POST', url: `${TEST_API}/me/notifications/read-all` }).flush(null, { status: 500, statusText: 'Server Error' });
    await stable();
    expect(row('n-comments').hasAttribute('data-unread')).toBe(true);
    expect(row('n-more').hasAttribute('data-unread')).toBe(true);
    expect(TestBed.inject(ToastService).toasts()).toEqual([expect.objectContaining({ kind: 'error' })]);

    root.querySelector<HTMLButtonElement>('[data-mark-all-read]')!.click();
    http.expectOne(`${TEST_API}/me/notifications/read-all`).flush(null, { status: 204, statusText: 'No Content' });
    await stable();
    expect(root.querySelectorAll('[data-unread]')).toHaveLength(0);
    expect(root.querySelector<HTMLButtonElement>('[data-mark-all-read]')!.disabled).toBe(true);
  });

  it('loads the next pages with the cursor near the end, skipping rows it already shows', async () => {
    const { root, stable, store } = await render(page(FIXTURES, '20'));
    expect(root.querySelector('[data-notifications-end]')).toBeNull();

    void store.loadMore();
    const more = http.expectOne((r) => r.url === LIST);
    expect(more.request.params.get('cursor')).toBe('20');
    more.flush(page([FIXTURES[2], testNotification({ id: 'n-old', updatedAt: '2026-10-20T09:00:00Z' })]));
    await stable();
    expect(root.querySelectorAll('[data-notification]')).toHaveLength(4);
    expect(root.querySelector('[data-notifications-end]')!.textContent).toContain('هذه كل الإشعارات');
  });

  it('a failed next page offers a retry', async () => {
    const { root, stable, store } = await render(page(FIXTURES, '20'));
    void store.loadMore();
    http.expectOne((r) => r.url === LIST).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    await stable();
    root.querySelector<HTMLButtonElement>('[data-load-more-retry]')!.click();
    http.expectOne((r) => r.url === LIST && r.params.get('cursor') === '20').flush(page([]));
    await stable();
    expect(root.querySelector('[data-load-more-retry]')).toBeNull();
  });

  it('shows the empty state, and an error state with a retry', async () => {
    const empty = await render(page([]));
    expect(empty.root.querySelector('[data-notifications-empty]')!.textContent).toContain('لا توجد إشعارات بعد');
    expect(empty.root.querySelector('[data-mark-all-read]')).toBeNull();

    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ providers: [{ provide: NotificationBadge, useValue: badge }, { provide: ModerationNotices, useValue: notices }] }));
    const fixture = TestBed.createComponent(NotificationsPage);
    fixture.detectChanges();
    http.expectOne((r) => r.url === LIST).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    await flushMicrotasks();
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    expect(root.querySelector('rd-error-state')!.textContent).toContain('تعذّر تحميل الإشعارات');
    root.querySelector<HTMLButtonElement>('rd-error-state button')!.click();
    http.expectOne((r) => r.url === LIST).flush(page(FIXTURES));
    await flushMicrotasks();
    fixture.detectChanges();
    expect(root.querySelectorAll('[data-notification]')).toHaveLength(3);
  });

  it('new notifications while it is open: a button shows them and marks them seen', async () => {
    const { root, stable } = await render();
    badge.count.set(2);
    await stable();
    root.querySelector<HTMLButtonElement>('[data-new-notifications]')!.click();
    expect(badge.markSeen).toHaveBeenCalledTimes(2);
    http.expectOne((r) => r.url === LIST).flush(page([testNotification({ id: 'n-new', updatedAt: '2026-11-04T09:59:00Z' }), ...FIXTURES]));
    badge.count.set(0);
    await stable();
    expect(root.querySelector('[data-new-notifications]')).toBeNull();
    expect(root.querySelectorAll('[data-notification]')).toHaveLength(4);
  });
});
