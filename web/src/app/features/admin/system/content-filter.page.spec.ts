import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { renderAdmin } from '../../../../testing/admin-testing';
import { testMe } from '../../../../testing/auth-testing';
import { TEST_API, problem, setupSocialTesting } from '../../../../testing/social-testing';
import { AdminDashboardDto, AdminSummaryDto, ContentFilterDto, ContentFilterTermDto } from '../../../core/api/models';
import { AdminSummaryStore } from '../../../core/admin/admin-summary.store';
import { ToastService } from '../../../shared/ui/toast/toast.service';
import { AdminLayout } from '../admin-layout';
import adminRoutes from '../admin.routes';
import { AdminDashboardPage } from '../dashboard/dashboard.page';
import { AdminContentFilterPage, MAX_TERMS, TERM_MAX, termProblem } from './content-filter.page';
import { AdminSystemPage } from './system.page';

const URL = `${TEST_API}/admin/content-filter`;

/** A small dashboard (the dashboard spec has the full one; importing a spec would run its tests here too). */
function dashboard(openReportsOver24h: number): AdminDashboardDto {
  const value = (v: number) => ({ value: v, previous: v });
  return {
    period: 'today',
    timeZone: 'Africa/Cairo',
    from: '2026-11-06T22:00:00Z',
    to: '2026-11-07T12:00:00Z',
    fromDate: '2026-11-07',
    toDate: '2026-11-07',
    generatedAt: '2026-11-07T12:00:00Z',
    cards: {
      articlesPublished: value(1),
      newUsers: { ...value(1), phone: 1, google: 0, apple: 0 },
      activeReaders: value(1),
      reads: value(1),
      comments: value(1),
      reactions: value(1),
      reposts: value(1),
      openReports: 3,
      openReportsOver24h,
      openTickets: null,
      pendingVerifications: 1,
      suspendedNow: 0,
    },
    charts: [],
    topArticles: [],
    topWriters: [],
    missedSearches: [],
    streakRetention: { cohort: 0, kept: 0, rate: null },
    contentPipeline: { folders: 0, seeded: 0, published: 0, lastSeedRunAt: null },
  };
}

function term(id: string, value: string, patch: Partial<ContentFilterTermDto> = {}): ContentFilterTermDto {
  return { id, term: value, language: 'ar', level: 'block', source: 'file', isEnabled: true, updatedAt: '2026-11-08T08:00:00Z', ...patch };
}

function filter(terms: ContentFilterTermDto[]): ContentFilterDto {
  const enabled = terms.filter((t) => t.isEnabled);
  return { terms, counts: { block: enabled.filter((t) => t.level === 'block').length, flag: enabled.filter((t) => t.level === 'flag').length } };
}

const TERMS = [
  term('t1', 'كلمة١'),
  term('t2', 'كلمة٢', { level: 'flag' }),
  term('t3', 'badword', { language: 'en' }),
  term('t4', 'oldword', { language: 'ar', isEnabled: false }),
];

describe('Console → System → Content filter (F37)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    const testing = setupSocialTesting();
    http = testing.http;
    testing.session.setMe(testMe({ permissions: ['admin.access', 'system.settings'] }));
  });
  afterEach(() => http.verify());

  async function render(terms = TERMS) {
    const t = renderAdmin(AdminContentFilterPage);
    expect(t.$('[data-filter-loading]')).not.toBeNull();
    http.expectOne(URL).flush(filter(terms));
    await t.stable();
    const shown = () => t.$$('[data-filter-term]').map((li) => li.getAttribute('data-filter-term'));
    return { ...t, shown };
  }

  it('checks a new term like the API: 2 to 100 characters with a letter', () => {
    expect(termProblem('a')).toBe('length');
    expect(termProblem('  ab  ')).toBeNull();
    expect(termProblem('x'.repeat(TERM_MAX + 1))).toBe('length');
    expect(termProblem('123')).toBe('letter');
    expect(termProblem('كل')).toBeNull();
    expect(MAX_TERMS).toBe(5000);
  });

  it('is under System, for system.settings', () => {
    const shell = adminRoutes.find((r) => r.children)!;
    const route = shell.children!.find((r) => r.path === 'system/content-filter')!;
    expect(route.title).toBe('admin.filter.title');
    expect(route.canActivate).toHaveLength(1);
  });

  it('shows one list at a time by language and level, with counts; removed file terms can be restored', async () => {
    const t = await render();
    expect(t.$('[data-filter-language="ar"]')!.getAttribute('aria-pressed')).toBe('true');
    expect(t.$('[data-filter-level="block"]')!.getAttribute('aria-pressed')).toBe('true');
    expect(t.shown()).toEqual(['كلمة١']);
    expect(t.$('[data-filter-level="block"]')!.textContent!.replace(/\s+/g, ' ').trim()).toBe('حظر 1');
    expect(t.$('[data-filter-level="flag"]')!.textContent!.replace(/\s+/g, ' ').trim()).toBe('تنبيه 1');
    expect(t.$('[data-filter-term="كلمة١"]')!.textContent).toContain('من الملف');
    expect(t.$('[data-filter-disabled] summary')!.textContent!.trim()).toBe('كلمة واحدة محذوفة من الملفات');

    t.$('[data-filter-level="flag"]')!.click();
    await t.stable();
    expect(t.shown()).toEqual(['كلمة٢']);
    t.$('[data-filter-language="en"]')!.click();
    await t.stable();
    expect(t.shown()).toEqual([]);
    expect(t.$('[data-filter-empty]')).not.toBeNull();
    // Removed terms are per language.
    expect(t.$('[data-filter-disabled]')).toBeNull();
    expect(t.$('[data-filter-save]')).toHaveProperty('disabled', true);
  });

  it('adds, moves and removes terms, then saves the whole enabled list (PUT)', async () => {
    const t = await render();
    t.type('[data-filter-new-term]', ' جديدة ');
    t.$('[data-filter-add] button[type="submit"]')!.click();
    await t.stable();
    expect(t.shown()).toEqual(['جديدة', 'كلمة١']);
    expect(t.$('[data-filter-term="جديدة"]')!.textContent).toContain('أُضيفت هنا');
    expect(t.$('[data-filter-unsaved]')!.textContent!.trim()).toBe('لديك تغييرات لم تُحفظ.');

    // كلمة١ moves to Flag; the removed file term comes back.
    t.type('[data-filter-term="كلمة١"] [data-filter-row-level]', 'flag', 'change');
    t.$('[data-filter-restore="oldword"]')!.click();
    await t.stable();
    expect(t.shown()).toEqual(['oldword', 'جديدة']);
    t.$('[data-filter-term="جديدة"] [data-filter-remove]')!.click();
    await t.stable();
    expect(t.shown()).toEqual(['oldword']);

    t.$('[data-filter-save]')!.click();
    await t.stable();
    const put = http.expectOne(URL);
    expect(put.request.method).toBe('PUT');
    expect(put.request.body).toEqual({
      terms: [
        { term: 'oldword', language: 'ar', level: 'block' },
        { term: 'كلمة١', language: 'ar', level: 'flag' },
        { term: 'كلمة٢', language: 'ar', level: 'flag' },
        { term: 'badword', language: 'en', level: 'block' },
      ],
    });
    put.flush(filter([term('t4', 'oldword'), term('t1', 'كلمة١', { level: 'flag' }), term('t2', 'كلمة٢', { level: 'flag' }), term('t3', 'badword', { language: 'en' })]));
    await t.stable();
    expect(t.$('[data-filter-unsaved]')).toBeNull();
    expect(TestBed.inject(ToastService).toasts().map((toast) => toast.kind)).toEqual(['success']);
  });

  it('refuses a short, letterless or duplicate term in place, without a request', async () => {
    const t = await render();
    t.type('[data-filter-new-term]', 'a');
    t.$('[data-filter-add] button[type="submit"]')!.click();
    await t.stable();
    expect(t.$('[data-filter-add-error]')!.textContent!.trim()).toBe(`أدخل من 2 إلى ${TERM_MAX} حرف.`);
    t.type('[data-filter-new-term]', '12');
    t.$('[data-filter-add] button[type="submit"]')!.click();
    await t.stable();
    expect(t.$('[data-filter-add-error]')!.textContent!.trim()).toBe('يجب أن تضم الكلمة حرفًا واحدًا على الأقل.');
    // Already in this language's list, on the other level: says which.
    t.type('[data-filter-new-term]', 'كلمة٢');
    t.$('[data-filter-add] button[type="submit"]')!.click();
    await t.stable();
    expect(t.$('[data-filter-add-error]')!.textContent!.trim()).toBe('هذه الكلمة موجودة بالفعل في قائمة هذه اللغة (تنبيه).');
    expect(t.shown()).toEqual(['كلمة١']);
    expect(t.$('[data-filter-save]')).toHaveProperty('disabled', true);
  });

  it("a refused save shows the API's message and keeps the changes", async () => {
    const t = await render();
    t.$('[data-filter-term="كلمة١"] [data-filter-remove]')!.click();
    await t.stable();
    t.$('[data-filter-save]')!.click();
    await t.stable();
    http.expectOne(URL).flush(
      { ...problem(400, 'validation.failed'), errors: { 'terms[0].term': ['content_filter.term_invalid'] } },
      { status: 400, statusText: 'Bad Request' },
    );
    await t.stable();
    expect(t.$('[data-filter-error]')!.textContent!.trim()).toBe('أدخل كلمة صالحة من حرفين على الأقل.');
    expect(t.$('[data-filter-unsaved]')).not.toBeNull();
  });

  it('"Try a text" shows the level the saved lists give and the terms matched', async () => {
    const t = await render();
    expect(t.$('[data-filter-test-run]')).toHaveProperty('disabled', true);
    t.type('[data-filter-test-text]', '  this has badword in it ');
    t.$('[data-filter-test-run]')!.click();
    await t.stable();
    const post = http.expectOne(`${URL}/test`);
    expect(post.request.method).toBe('POST');
    expect(post.request.body).toEqual({ text: 'this has badword in it' });
    post.flush({ level: 'block', matches: ['badword'] });
    await t.stable();
    expect(t.$('[data-filter-result]')!.getAttribute('data-filter-result')).toBe('block');
    expect(t.$('[data-filter-result]')!.textContent!.trim()).toBe('مرفوض');
    expect(t.$('[data-filter-test]')!.textContent).toContain('badword');

    t.type('[data-filter-test-text]', 'fine');
    t.$('[data-filter-test-run]')!.click();
    http.expectOne(`${URL}/test`).flush({ level: 'none', matches: [] });
    await t.stable();
    expect(t.$('[data-filter-result]')!.textContent!.trim()).toBe('مسموح');
  });

  it('a load error offers a retry', async () => {
    const t = renderAdmin(AdminContentFilterPage);
    http.expectOne(URL).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
    await t.stable();
    t.$('rd-error-state button')!.click();
    http.expectOne(URL).flush(filter(TERMS));
    await t.stable();
    expect(t.$$('[data-filter-term]')).toHaveLength(1);
  });
});

describe('Console: reports past 24 hours (F22, store requirements)', () => {
  let http: HttpTestingController;

  function setup(providers: unknown[] = []) {
    TestBed.resetTestingModule();
    const testing = setupSocialTesting({ providers });
    http = testing.http;
    testing.session.setMe(testMe({ permissions: ['admin.access', 'moderation.manage', 'system.settings'] }));
  }
  afterEach(() => http.verify());

  it('the dashboard shows the open cases past 24 hours next to the open reports, in red when there are any', async () => {
    setup();
    const t = renderAdmin(AdminDashboardPage);
    http.expectOne(`${TEST_API}/admin/dashboard?period=today`).flush(dashboard(2));
    await t.stable();
    expect(t.$$('[data-queue]').map((q) => q.getAttribute('data-queue'))).toEqual(['openReports', 'openReportsOver24h', 'pendingVerifications']);
    const card = t.$('[data-queue="openReportsOver24h"]')!;
    expect(card.getAttribute('href')).toBe('/admin/reports');
    expect(card.textContent).toContain('بلاغات تجاوزت 24 ساعة');
    expect(card.querySelector('.bg-callout-danger')).not.toBeNull();
  });

  it('at 0 the card stays, without the alarm', async () => {
    setup();
    const t = renderAdmin(AdminDashboardPage);
    http.expectOne(`${TEST_API}/admin/dashboard?period=today`).flush(dashboard(0));
    await t.stable();
    expect(t.$('[data-queue="openReportsOver24h"] .bg-callout-danger')).toBeNull();
  });

  it('the console nav warns about them on every page', async () => {
    const summary = signal<AdminSummaryDto | null>({ openReports: 4, openTickets: null, pendingVerifications: null, total: 4, openReportsOver24h: 3 });
    const store = { summary, total: signal(4), canAccess: signal(true), refresh: vi.fn(async () => undefined) };
    setup([{ provide: AdminSummaryStore, useValue: store }]);
    const t = renderAdmin(AdminLayout);
    await t.stable();
    const link = t.$('[data-admin-overdue]')!;
    expect(link.getAttribute('href')).toBe('/admin/reports');
    expect(link.textContent!.trim()).toBe('3 بلاغات تنتظر أكثر من 24 ساعة');
    summary.set({ ...summary()!, openReportsOver24h: 0 });
    await t.stable();
    expect(t.$('[data-admin-overdue]')).toBeNull();
  });

  it('System links to the content filter', async () => {
    setup();
    const t = renderAdmin(AdminSystemPage);
    http.expectOne(`${TEST_API}/admin/system`).flush({
      api: { version: '1', startedAt: '2026-11-07T06:00:00Z', environment: 'Production' },
      updatePolicy: { ios: { minimumVersion: null, storeUrl: null }, android: { minimumVersion: null, storeUrl: null } },
      database: { reachable: true, latencyMs: 1 },
      firebase: { messagingConfigured: true, realtimeConfigured: true, realtimeReachable: true },
      jobs: [],
      push: { sent: 0, failed: 0, invalidTokens: 0, since: '2026-11-06T12:00:00Z' },
      storage: { uploadsBytes: 0, uploadsFiles: 0, privateBytes: 0, privateFiles: 0, measuredAt: '2026-11-07T11:50:00Z' },
    });
    await t.stable();
    const row = t.$('[data-system-filter]')!;
    expect(row.getAttribute('href')).toBe('/admin/system/content-filter');
    expect(row.textContent).toContain('فلتر المحتوى');
  });
});
