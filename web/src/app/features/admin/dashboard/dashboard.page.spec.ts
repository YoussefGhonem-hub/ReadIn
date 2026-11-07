import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { AdminDashboardDto } from '../../../core/api/models';
import { changeOf, formatChange, AdminDashboardPage } from './dashboard.page';

const value = (v: number, previous: number) => ({ value: v, previous });

export function testDashboard(patch: Partial<AdminDashboardDto> = {}): AdminDashboardDto {
  return {
    period: 'today',
    timeZone: 'Africa/Cairo',
    from: '2026-11-06T22:00:00Z',
    to: '2026-11-07T12:00:00Z',
    fromDate: '2026-11-07',
    toDate: '2026-11-07',
    generatedAt: '2026-11-07T12:00:00Z',
    cards: {
      articlesPublished: value(12, 10),
      newUsers: { ...value(5, 8), phone: 3, google: 1, apple: 1 },
      activeReaders: value(40, 40),
      reads: value(120, 100),
      comments: value(9, 0),
      reactions: value(30, 20),
      reposts: value(2, 4),
      openReports: 3,
      openTickets: null,
      pendingVerifications: 1,
      suspendedNow: 2,
    },
    charts: Array.from({ length: 30 }, (_, i) => ({ date: `2026-10-${String(i + 1).padStart(2, '0')}`, newUsers: i % 3, activeReaders: i, articlesPublished: 1 })),
    topArticles: [
      {
        id: 'a1',
        slug: 'clean-architecture',
        title: 'Clean Architecture',
        language: 'en',
        author: { id: 'w1', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true },
        field: { id: 'f1', slug: 'software', name: 'Software', nameAr: 'البرمجيات', nameEn: 'Software' },
        publishedAt: '2026-11-01T08:00:00Z',
        reads: 14,
      },
    ],
    topWriters: [{ writer: { id: 'w1', displayName: 'Karim Hassan', username: 'karim', avatarUrl: null, isVerified: true }, reads: 30, articles: 3 }],
    missedSearches: [{ query: 'kubernetes', language: 'en', count: 4 }],
    streakRetention: { cohort: 50, kept: 20, rate: 0.4 },
    contentPipeline: { folders: 300, seeded: 300, published: 298, lastSeedRunAt: '2026-11-06T10:00:00Z' },
    ...patch,
  };
}

describe('AdminDashboardPage (F23)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
  });

  afterEach(() => http.verify());

  async function render(period?: string) {
    const fixture = TestBed.createComponent(AdminDashboardPage);
    if (period) fixture.componentRef.setInput('period', period);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
    };
    return { fixture, root, stable, $: (s: string) => root.querySelector<HTMLElement>(s), $$: (s: string) => [...root.querySelectorAll<HTMLElement>(s)] };
  }

  it('computes the change from the previous period', () => {
    expect(changeOf(12, 10)).toEqual({ delta: 2, percent: 20, direction: 'up' });
    expect(changeOf(5, 8)).toEqual({ delta: -3, percent: -38, direction: 'down' });
    expect(changeOf(9, 0)).toEqual({ delta: 9, percent: null, direction: 'up' });
    expect(formatChange(changeOf(12, 10), 'en')).toBe('+2 (+20%)');
    expect(formatChange(changeOf(5, 8), 'en')).toBe('-3 (-38%)');
    // Arabic keeps Western digits; its signs carry direction marks, so the text sits in an LTR <bdi>.
    expect(formatChange(changeOf(5, 8), 'ar').replace(/\u200e/g, '')).toBe('-3 (-38%)');
    expect(formatChange(changeOf(9, 0), 'en')).toBe('+9');
    expect(formatChange(changeOf(4, 4), 'en')).toBe('0');
  });

  it("loads today's numbers: cards with their change, the queues the session sees, charts and lists", async () => {
    const t = await render();
    expect(t.$('[data-dashboard-loading]')).not.toBeNull();
    http.expectOne(`${TEST_API}/admin/dashboard?period=today`).flush(testDashboard());
    await t.stable();

    expect(t.$('[data-card="articlesPublished"] [data-card-value]')!.textContent!.trim()).toBe('12');
    expect(t.$('[data-card="articlesPublished"] [data-change]')!.getAttribute('data-change')).toBe('up');
    expect(t.$('[data-card="newUsers"] [data-change]')!.getAttribute('data-change')).toBe('down');
    expect(t.$('[data-card="activeReaders"] [data-change]')!.getAttribute('data-change')).toBe('flat');
    expect(t.$('[data-signup-split]')!.textContent).toContain('Google 1');
    // "Articles published" opens Content for the period.
    expect(t.$('[data-card="articlesPublished"] a')!.getAttribute('href')).toBe('/admin/content?from=2026-11-07&to=2026-11-07');
    expect(t.$('[data-card="suspendedNow"]')!.getAttribute('href')).toBe('/admin/users?status=suspended');
    // Open tickets is null (no support.manage): no card.
    expect(t.$$('[data-queue]').map((q) => q.getAttribute('data-queue'))).toEqual(['openReports', 'pendingVerifications']);
    expect(t.$('[data-queue="openReports"]')!.getAttribute('href')).toBe('/admin/reports');

    expect(t.$$('[data-chart]').length).toBe(3);
    expect(t.$$('[data-chart="newUsers"] [data-chart-bar]').length).toBe(30);
    expect(t.$('[data-top-articles]')!.textContent).toContain('Clean Architecture');
    expect(t.$('[data-top-writers]')!.textContent).toContain('@karim');
    expect(t.$('[data-missed-searches]')!.textContent).toContain('kubernetes');
    expect(t.$('[data-retention-rate]')!.textContent!.replace(/\u200e/g, '').trim()).toBe('40%');
    expect(t.$('[data-pipeline]')!.textContent).toContain('298');
  });

  it('the period switch keeps the period in the URL; another period loads its numbers', async () => {
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    const t = await render('7d');
    http.expectOne(`${TEST_API}/admin/dashboard?period=7d`).flush(testDashboard({ period: '7d' }));
    await t.stable();
    const radios = t.$$('[role="radio"]');
    expect(radios.map((r) => r.getAttribute('aria-checked'))).toEqual(['false', 'false', 'true', 'false']);
    radios[3].click();
    expect(navigate).toHaveBeenCalledWith(['/admin'], { queryParams: { period: '30d' }, replaceUrl: true });
    radios[0].click();
    expect(navigate).toHaveBeenLastCalledWith(['/admin'], { queryParams: { period: null }, replaceUrl: true });
  });

  it('an unknown period means today; a failure offers a retry', async () => {
    const t = await render('week');
    http.expectOne(`${TEST_API}/admin/dashboard?period=today`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await t.stable();
    const retry = t.root.querySelector<HTMLButtonElement>('rd-error-state button')!;
    retry.click();
    http.expectOne(`${TEST_API}/admin/dashboard?period=today`).flush(testDashboard({ streakRetention: { cohort: 0, kept: 0, rate: null } }));
    await t.stable();
    expect(t.$('[data-retention-empty]')).not.toBeNull();
  });
});
