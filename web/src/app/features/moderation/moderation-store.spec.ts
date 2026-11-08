import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, setupSocialTesting } from '../../../testing/social-testing';
import { ModerationCaseDto, ModerationQueueItemDto, ModerationReportDto, ModerationTargetType } from '../../core/api/models';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { ModerationCasePage } from './moderation-case.page';
import { ModerationQueuePage } from './moderation-queue.page';

const MODERATOR = ['articles.read', 'reports.create', 'moderation.manage', 'users.suspend'];
const QUEUE = `${TEST_API}/moderation/reports`;
const SUMMARY = `${TEST_API}/moderation/summary`;
const ACTIONS = `${TEST_API}/moderation/actions`;
const AUTHOR = { id: 'writer-2', displayName: 'Omar Fathy', username: 'omar_dev', avatarUrl: null, isVerified: false };

function item(targetType: ModerationTargetType, targetId: string, patch: Partial<ModerationQueueItemDto> = {}): ModerationQueueItemDto {
  const target: ModerationQueueItemDto['target'] =
    targetType === 'repost'
      ? { state: 'visible', author: AUTHOR, body: 'Read this, it changed my mind', articleId: 'a1', articleSlug: 'sleep-and-memory', articleTitle: 'How sleep turns reading into memory' }
      : { state: 'visible', author: AUTHOR, body: 'Buy cheap courses 👉 link in bio', articleId: 'a1', articleSlug: 'sleep-and-memory', articleTitle: 'How sleep turns reading into memory' };
  return {
    targetType,
    targetId,
    status: 'open',
    reportCount: 1,
    reasons: { spam: 1 },
    firstReportedAt: '2026-11-02T18:00:00Z',
    lastReportedAt: '2026-11-03T07:40:00Z',
    closedAt: null,
    target,
    ...patch,
  };
}

function reportOf(id: string, patch: Partial<ModerationReportDto> = {}): ModerationReportDto {
  return {
    id,
    reporter: { id: `u-${id}`, displayName: `Reader ${id}`, username: `reader_${id}`, avatarUrl: null, isVerified: false, bio: null, isFollowing: false, followsYou: false },
    reason: 'spam',
    details: null,
    status: 'open',
    createdAt: '2026-11-03T07:40:00Z',
    closedAt: null,
    closedBy: null,
    ...patch,
  };
}

function answerSummary(http: HttpTestingController): void {
  for (const req of http.match(SUMMARY)) req.flush({ open: { article: 1, comment: 1, user: 1, total: 3 } });
}

describe('Moderation: the App Store additions (F22, F37)', () => {
  let http: HttpTestingController;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    answerSummary(http);
    http.verify();
  });

  function setup() {
    const t = setupSocialTesting();
    t.session.setMe(testMe({ permissions: MODERATOR }));
    http = t.http;
    return t;
  }

  async function stableOf(fixture: { detectChanges(): void; whenStable(): Promise<unknown> }) {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  }

  describe('queue', () => {
    async function render(items: ModerationQueueItemDto[]) {
      setup();
      const fixture = TestBed.createComponent(ModerationQueuePage);
      fixture.detectChanges();
      await fixture.whenStable();
      answerSummary(http);
      http.expectOne((r) => r.url === QUEUE).flush({ items, nextCursor: null });
      await stableOf(fixture);
      const root = fixture.nativeElement as HTMLElement;
      return { root, $$: (s: string) => [...root.querySelectorAll<HTMLElement>(s)] };
    }

    it("an open case shows how long it has waited; from 12 hours it is Urgent (every report is handled within 24)", async () => {
      const t = await render([
        item('comment', 'c1', { ageHours: 0, urgent: false }),
        item('comment', 'c2', { ageHours: 5, urgent: false }),
        item('comment', 'c3', { ageHours: 13, urgent: true }),
        item('comment', 'c4'),
      ]);
      const cards = t.$$('[data-case]');
      const age = (i: number) => cards[i].querySelector('[data-case-age]')?.textContent!.trim() ?? null;
      expect(age(0)).toBe('مفتوح منذ أقل من ساعة');
      expect(age(1)).toBe('مفتوح منذ 5 ساعات');
      expect(age(2)).toBe('مفتوح منذ 13 ساعة');
      // An API without the field shows no age.
      expect(age(3)).toBeNull();
      expect(cards.map((c) => !!c.querySelector('[data-case-urgent]'))).toEqual([false, false, true, false]);
      expect(cards[2].querySelector('[data-case-urgent]')!.textContent!.trim()).toBe('عاجل');
      expect(cards[2].querySelector('[data-case-age]')!.className).toContain('text-error');
    });

    it('a closed case shows no age', async () => {
      const t = await render([item('comment', 'c1', { status: 'resolved', closedAt: '2026-11-03T09:00:00Z', ageHours: 30, urgent: true })]);
      expect(t.$$('[data-case-age]')).toHaveLength(0);
      expect(t.$$('[data-case-urgent]')).toHaveLength(0);
    });

    it('a repost case shows its caption and the article it reposted, and opens its own case', async () => {
      const t = await render([item('repost', 'r1')]);
      const [card] = t.$$('[data-case]');
      expect(card.getAttribute('data-case')).toBe('repost:r1');
      expect(card.getAttribute('href')).toBe('/admin/reports/repost/r1');
      expect(card.querySelector('[data-target-caption]')!.textContent).toContain('Read this, it changed my mind');
      expect(card.textContent).toContain('أعاد نشر ⁨How sleep turns reading into memory⁩');
      expect(t.$$('[data-type-chip]').map((c) => c.getAttribute('data-type-chip'))).toEqual(['all', 'article', 'comment', 'user', 'repost']);
    });
  });

  describe('case', () => {
    async function render(type: ModerationTargetType, id: string, data: ModerationCaseDto) {
      setup();
      answerSummary(http);
      const fixture = TestBed.createComponent(ModerationCasePage);
      fixture.componentRef.setInput('type', type);
      fixture.componentRef.setInput('id', id);
      fixture.detectChanges();
      await fixture.whenStable();
      answerSummary(http);
      http.expectOne(`${TEST_API}/moderation/reports/${type}/${id}`).flush(data);
      const stable = () => stableOf(fixture);
      await stable();
      const root = fixture.nativeElement as HTMLElement;
      const $ = (s: string) => root.querySelector<HTMLElement>(s);
      const $$ = (s: string) => [...root.querySelectorAll<HTMLElement>(s)];
      return { root, stable, $, $$, actions: () => $$('[data-case-action]').map((a) => a.getAttribute('data-case-action')) };
    }

    it('the header shows the age and Urgent', async () => {
      const t = await render('comment', 'c1', { item: item('comment', 'c1', { ageHours: 20, urgent: true }), reports: [reportOf('r1')], history: [] });
      expect(t.$('[data-case-age]')!.textContent!.trim()).toBe('مفتوح منذ 20 ساعة');
      expect(t.$('[data-case-urgent]')!.textContent!.trim()).toBe('عاجل');
    });

    it('a report the content filter filed says so and lists the terms it matched', async () => {
      const system = reportOf('r2', { reporter: null, isSystem: true, reason: 'other', matchedTerms: ['spamword', 'كلمة'] });
      const t = await render('comment', 'c1', { item: item('comment', 'c1'), reports: [reportOf('r1'), system], history: [] });
      const reports = t.$$('[data-report]');
      expect(reports[0].querySelector('[data-report-system]')).toBeNull();
      expect(reports[0].querySelector('[data-report-terms]')).toBeNull();
      expect(reports[1].querySelector('[data-report-system]')!.textContent!.trim()).toBe('فلتر المحتوى');
      const terms = reports[1].querySelector('[data-report-terms]')!;
      expect(terms.textContent).toContain('الكلمات المرصودة:');
      expect([...terms.querySelectorAll('.rd-tag')].map((tag) => [tag.textContent!.trim(), tag.getAttribute('dir')])).toEqual([
        ['spamword', 'auto'],
        ['كلمة', 'auto'],
      ]);
    });

    it('a repost: delete it (asks first) or dismiss the reports; it links to the reposted article', async () => {
      const t = await render('repost', 'r1', { item: item('repost', 'r1'), reports: [reportOf('p1')], history: [] });
      expect(t.$('h1')!.textContent!.trim()).toBe('بلاغ عن إعادة نشر');
      expect(t.$('[data-case-link]')!.getAttribute('href')).toBe('/ar/a/sleep-and-memory');
      expect(t.$('[data-case-link]')!.textContent).toContain('فتح المقال المعاد نشره');
      expect(t.$('[data-target-caption]')!.textContent).toContain('Read this, it changed my mind');
      expect(t.actions()).toEqual(['delete', 'dismiss']);
      expect(t.$('[data-case-action="delete"]')!.textContent!.trim()).toBe('حذف إعادة النشر');

      t.$('[data-case-action="delete"]')!.click();
      await t.stable();
      const sheet = t.$('[data-moderation-sheet]')!;
      expect(sheet.getAttribute('data-moderation-action')).toBe('delete');
      expect(sheet.textContent).toContain('هل تريد حذف إعادة النشر هذه؟');
      expect(sheet.textContent).toContain('ستُزال كأن صاحبها ألغاها');
      expect(t.$('[data-moderation-confirm]')!.textContent!.trim()).toBe('حذف إعادة النشر');
      t.$('[data-moderation-confirm]')!.click();
      const req = http.expectOne(ACTIONS);
      expect(req.request.body).toEqual({ action: 'delete', targetType: 'repost', targetId: 'r1' });
      req.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      expect(TestBed.inject(ToastService).toasts().map((toast) => toast.message)).toEqual(['تم حذف إعادة النشر']);

      const deleted = item('repost', 'r1', { status: 'resolved', closedAt: '2026-11-03T09:00:00Z', target: { ...item('repost', 'r1').target, state: 'deleted' } });
      http.expectOne(`${TEST_API}/moderation/reports/repost/r1`).flush({ item: deleted, reports: [reportOf('p1', { status: 'resolved' })], history: [] });
      answerSummary(http);
      await t.stable();
      expect(t.actions()).toEqual([]);
    });
  });
});
