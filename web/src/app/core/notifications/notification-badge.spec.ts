import { PLATFORM_ID, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { TEST_API, testMe } from '../../../testing/auth-testing';
import { translocoTesting } from '../../../testing/transloco-testing';
import { API_BASE_URL } from '../api/api.config';
import { SessionStore } from '../auth/session.store';
import { RealtimeService } from '../realtime/realtime.service';
import { NotificationBadge, UNREAD_POLL_MS, notificationsLabel } from './notification-badge';

const COUNT = `${TEST_API}/me/notifications/unread-count`;
const flush = async () => {
  for (let i = 0; i < 6; i++) await Promise.resolve();
};

function setup(platform = 'browser') {
  const realtime = {
    unreadLive: signal(false),
    unreadNotifications: signal(0),
    clearUnreadNotifications: vi.fn(() => realtime.unreadNotifications.set(0)),
  };
  TestBed.configureTestingModule({
    imports: [translocoTesting()],
    providers: [
      provideHttpClient(),
      provideHttpClientTesting(),
      { provide: API_BASE_URL, useValue: TEST_API },
      { provide: PLATFORM_ID, useValue: platform },
      { provide: RealtimeService, useValue: realtime },
    ],
  });
  return {
    badge: TestBed.inject(NotificationBadge),
    session: TestBed.inject(SessionStore),
    http: TestBed.inject(HttpTestingController),
    realtime,
  };
}

describe('NotificationBadge (F17)', () => {
  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => vi.useRealTimers());

  it('is 0 for guests and asks nothing', () => {
    const { badge, session, http } = setup();
    session.setGuest();
    TestBed.tick();
    expect(badge.count()).toBe(0);
    http.expectNone(COUNT);
  });

  it('without the live value, counts through REST on sign-in, every minute while visible and when the tab comes back', async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] });
    const { badge, session, http } = setup();
    session.setMe(testMe());
    TestBed.tick();
    http.expectOne(COUNT).flush({ unread: 5 });
    await flush();
    expect(badge.count()).toBe(5);

    vi.advanceTimersByTime(UNREAD_POLL_MS);
    await flush();
    http.expectOne(COUNT).flush({ unread: 6 });
    await flush();
    expect(badge.count()).toBe(6);

    document.dispatchEvent(new Event('visibilitychange'));
    await flush();
    http.expectOne(COUNT).flush({ unread: 2 });
    await flush();
    expect(badge.count()).toBe(2);
    http.verify();
  });

  it('follows the live value once it arrives, and stops asking', async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] });
    const { badge, session, http, realtime } = setup();
    session.setMe(testMe());
    TestBed.tick();
    http.expectOne(COUNT).flush({ unread: 1 });
    await flush();

    realtime.unreadNotifications.set(4);
    realtime.unreadLive.set(true);
    TestBed.tick();
    expect(badge.count()).toBe(4);
    vi.advanceTimersByTime(UNREAD_POLL_MS * 3);
    await badge.refresh();
    http.expectNone(COUNT);
  });

  it('opening the center clears it at once; a count asked for before that cannot bring it back', async () => {
    const { badge, session, http, realtime } = setup();
    session.setMe(testMe());
    TestBed.tick();
    const stale = http.expectOne(COUNT);

    const seen = badge.markSeen();
    expect(badge.count()).toBe(0);
    expect(realtime.clearUnreadNotifications).toHaveBeenCalled();
    stale.flush({ unread: 3 }); // answered after the center opened
    http.expectOne({ method: 'POST', url: `${TEST_API}/me/notifications/seen` }).flush(null, { status: 204, statusText: 'No Content' });
    await seen;
    await flush();
    expect(badge.count()).toBe(0);

    // A refresh waits for "seen" and then shows what the API says.
    void badge.refresh();
    await flush();
    http.expectOne(COUNT).flush({ unread: 1 });
    await flush();
    expect(badge.count()).toBe(1);
  });

  it('marks one read (a gone one is fine), then refreshes the count', async () => {
    const { badge, session, http } = setup();
    session.setMe(testMe());
    TestBed.tick();
    http.expectOne(COUNT).flush({ unread: 2 });
    await flush();

    const read = badge.markRead('n 1');
    http.expectOne({ method: 'POST', url: `${TEST_API}/me/notifications/n%201/read` }).flush(
      { code: 'notification.not_found' },
      { status: 404, statusText: 'Not Found' },
    );
    await read;
    await flush();
    http.expectOne(COUNT).flush({ unread: 1 });
    await flush();
    expect(badge.count()).toBe(1);
  });

  it('starts over for another account, and never counts for one with setup steps left', async () => {
    const { badge, session, http } = setup();
    session.setMe(testMe());
    TestBed.tick();
    http.expectOne(COUNT).flush({ unread: 7 });
    await flush();

    session.setMe(testMe({ id: 'user-2', mustSetRecoveryPin: true, hasRecoveryPin: false }));
    TestBed.tick();
    expect(badge.count()).toBe(0);
    http.expectNone(COUNT);
    await badge.markSeen();
    http.expectNone(`${TEST_API}/me/notifications/seen`);
  });

  it('never runs during SSR', () => {
    const { badge, session, http } = setup('server');
    session.setMe(testMe());
    TestBed.tick();
    http.expectNone(COUNT);
    expect(badge.count()).toBe(0);
  });

  it('labels the bell with the count for screen readers (ar plural forms, en)', () => {
    const { session } = setup();
    session.setGuest();
    const transloco = TestBed.inject(TranslocoService);
    expect(notificationsLabel(transloco, 'ar', 0)).toBe('الإشعارات');
    expect(notificationsLabel(transloco, 'ar', 2)).toBe('الإشعارات، إشعارين جداد');
    expect(notificationsLabel(transloco, 'ar', 5)).toBe('الإشعارات، 5 إشعارات جديدة');
    expect(notificationsLabel(transloco, 'en', 1)).toBe('Notifications, 1 new');
    expect(notificationsLabel(transloco, 'en', 12)).toBe('Notifications, 12 new');
  });
});
