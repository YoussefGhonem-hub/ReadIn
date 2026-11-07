import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { ADMIN_SUMMARY_INTERVAL_MS, AdminSummaryStore } from './admin-summary.store';

const URL = `${TEST_API}/admin/summary`;
const SUMMARY = { openReports: 3, openTickets: 2, pendingVerifications: 1, total: 6 };

describe('AdminSummaryStore (F23)', () => {
  let http: HttpTestingController;

  afterEach(() => {
    http.verify();
    vi.useRealTimers();
    Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => 'visible' });
  });

  function setup(permissions: string[]) {
    TestBed.resetTestingModule();
    const testing = setupSocialTesting();
    http = testing.http;
    testing.session.setMe(testMe({ permissions }));
    const store = TestBed.inject(AdminSummaryStore);
    TestBed.tick();
    return { ...testing, store };
  }

  it('members never ask for it: no request, no badge', () => {
    const { store } = setup(['articles.read', 'moderation.manage']);
    http.expectNone(URL);
    expect(store.canAccess()).toBe(false);
    expect(store.total()).toBe(0);
  });

  it('loads for admin.access as the session arrives; a failure keeps the last numbers', async () => {
    const { store } = setup(['articles.read', 'admin.access']);
    http.expectOne(URL).flush(SUMMARY);
    await flushMicrotasks();
    expect(store.total()).toBe(6);
    expect(store.summary()?.openTickets).toBe(2);

    const again = store.refresh();
    http.expectOne(URL).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await again;
    expect(store.total()).toBe(6);
  });

  it('refreshes every 60 seconds while the tab is visible, and when it becomes visible again', async () => {
    vi.useFakeTimers();
    setup(['admin.access']);
    http.expectOne(URL).flush(SUMMARY);

    vi.advanceTimersByTime(ADMIN_SUMMARY_INTERVAL_MS);
    http.expectOne(URL).flush({ ...SUMMARY, total: 7 });

    // Hidden: the timer skips it.
    Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => 'hidden' });
    vi.advanceTimersByTime(ADMIN_SUMMARY_INTERVAL_MS);
    http.expectNone(URL);

    // Visible again: at once.
    Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => 'visible' });
    document.dispatchEvent(new Event('visibilitychange'));
    http.expectOne(URL).flush(SUMMARY);
  });

  it('signing out stops it and clears the badge', async () => {
    const { store, session } = setup(['admin.access']);
    http.expectOne(URL).flush(SUMMARY);
    await flushMicrotasks();
    session.setGuest();
    TestBed.tick();
    expect(store.summary()).toBeNull();
    expect(store.total()).toBe(0);
  });
});
