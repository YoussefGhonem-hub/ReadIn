import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { ActivatedRouteSnapshot, Router, RouterStateSnapshot, UrlTree } from '@angular/router';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { routes } from '../../app.routes';
import {
  ModerationActionDto,
  ModerationCaseDto,
  ModerationQueueItemDto,
  ModerationReportDto,
  ModerationTargetType,
  UserSummaryDto,
} from '../../core/api/models';
import { AuthService } from '../../core/auth/auth.service';
import { SessionStore } from '../../core/auth/session.store';
import { ModerationCasePage } from './moderation-case.page';
import { ModerationLogPage } from './moderation-log.page';
import { ModerationQueuePage } from './moderation-queue.page';
import moderationRoutes from './moderation.routes';

const MODERATOR = ['articles.read', 'reports.create', 'moderation.manage', 'users.suspend'];
const QUEUE = `${TEST_API}/moderation/reports`;
const SUMMARY = `${TEST_API}/moderation/summary`;
const ACTIONS = `${TEST_API}/moderation/actions`;
const AUTHOR = { id: 'writer-2', displayName: 'Omar Fathy', username: 'omar_dev', avatarUrl: null, isVerified: false };

function person(id: string, displayName: string): UserSummaryDto {
  return { id, displayName, username: displayName.toLowerCase().replace(/\s+/g, '_'), avatarUrl: null, isVerified: false, bio: null, isFollowing: false, followsYou: false };
}

function item(targetType: ModerationTargetType, targetId: string, patch: Partial<ModerationQueueItemDto> = {}): ModerationQueueItemDto {
  const target: ModerationQueueItemDto['target'] =
    targetType === 'article'
      ? { state: 'visible', author: AUTHOR, title: 'How sleep turns reading into memory', slug: 'sleep-and-memory', language: 'en' }
      : targetType === 'comment'
        ? { state: 'visible', author: AUTHOR, body: 'Buy cheap courses 👉 link in bio', articleId: 'a1', articleSlug: 'sleep-and-memory', articleTitle: 'How sleep turns reading into memory' }
        : { state: 'active', author: AUTHOR, suspendedUntil: null, warningCount: 2 };
  return {
    targetType,
    targetId,
    status: 'open',
    reportCount: 3,
    reasons: { misinformation: 2, other: 1 },
    firstReportedAt: '2026-11-02T18:00:00Z',
    lastReportedAt: '2026-11-03T07:40:00Z',
    closedAt: null,
    target,
    ...patch,
  };
}

function reportOf(id: string, patch: Partial<ModerationReportDto> = {}): ModerationReportDto {
  return { id, reporter: person(`u-${id}`, `Reader ${id}`), reason: 'misinformation', details: null, status: 'open', createdAt: '2026-11-03T07:40:00Z', closedAt: null, closedBy: null, ...patch };
}

function logOf(id: string, patch: Partial<ModerationActionDto> = {}): ModerationActionDto {
  return {
    id,
    action: 'comment.hide',
    targetType: 'comment',
    targetId: 'c1',
    targetLabel: 'Buy cheap courses',
    targetUser: person('writer-2', 'Omar Fathy'),
    moderator: person('mod-1', 'Nour Fawzy'),
    note: 'Spam.',
    suspendedUntil: null,
    reportsClosed: 2,
    createdAt: '2026-11-02T10:00:00Z',
    ...patch,
  };
}

function caseOf(queueItem: ModerationQueueItemDto, patch: Partial<ModerationCaseDto> = {}): ModerationCaseDto {
  return { item: queueItem, reports: [reportOf('r1', { details: 'The study says the opposite.' }), reportOf('r2', { reason: 'other' })], history: [], ...patch };
}

function setup(permissions = MODERATOR) {
  const t = setupSocialTesting();
  t.session.setMe(testMe({ permissions }));
  return t;
}

/** The summary store loads for moderators (nav badge); tests answer it where it is asked. */
function answerSummary(http: HttpTestingController, total = 3): void {
  for (const req of http.match(SUMMARY)) req.flush({ open: { article: 1, comment: 1, user: 1, total } });
}

describe('Moderation (F22)', () => {
  let http: HttpTestingController;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    answerSummary(http);
    http.verify();
  });

  describe('queue', () => {
    async function render(inputs: { status?: string; type?: string } = {}) {
      ({ http } = setup());
      const fixture = TestBed.createComponent(ModerationQueuePage);
      if (inputs.status) fixture.componentRef.setInput('status', inputs.status);
      if (inputs.type) fixture.componentRef.setInput('type', inputs.type);
      fixture.detectChanges();
      await fixture.whenStable();
      answerSummary(http);
      const root = fixture.nativeElement as HTMLElement;
      const stable = async () => {
        await flushMicrotasks();
        fixture.detectChanges();
        await fixture.whenStable();
      };
      const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
      const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
      const expectQueue = (params: Record<string, string>): TestRequest => {
        const req = http.expectOne((r) => r.url === QUEUE);
        expect(Object.fromEntries(req.request.params.keys().map((k) => [k, req.request.params.get(k)]))).toEqual(params);
        return req;
      };
      return { fixture, root, stable, $, $$, expectQueue };
    }

    it('starts on Open / All: one card per target with its preview, reasons, report count and last report', async () => {
      const t = await render();
      expect(t.$('[data-case]')).toBeNull();
      expect(t.$('[data-queue-loading]')).not.toBeNull();
      t.expectQueue({ status: 'open', limit: '20' }).flush({
        items: [item('article', 'a1'), item('comment', 'c1', { reportCount: 2, reasons: { spam: 2 } }), item('user', 'u9', { reportCount: 1, reasons: { harassment: 1 } })],
        nextCursor: null,
      });
      await t.stable();

      expect(t.$('[data-moderation-tab="open"]')!.getAttribute('aria-current')).toBe('page');
      expect(t.$$('[data-moderation-tab]').map((tab) => tab.textContent!.trim())).toEqual(['مفتوحة', 'اتحلّت', 'اترفضت', 'السجل']);
      expect(t.$$('[data-type-chip]').map((chip) => chip.textContent!.replace(/\s+/g, ' ').trim())).toEqual(['الكل 3', 'مقالات 1', 'تعليقات 1', 'مستخدمين 1']);
      expect(t.$('[data-type-chip="all"]')!.getAttribute('aria-pressed')).toBe('true');

      const cards = t.$$('[data-case]');
      expect(cards.map((c) => c.getAttribute('data-case'))).toEqual(['article:a1', 'comment:c1', 'user:u9']);
      expect(cards[0].getAttribute('href')).toBe('/moderation/article/a1');
      expect(cards[0].querySelector('[data-target-title]')!.textContent).toContain('How sleep turns reading into memory');
      expect(cards[0].querySelector('[data-report-count]')!.textContent!.trim()).toBe('3 بلاغات');
      expect([...cards[0].querySelectorAll('[data-reason-count]')].map((r) => r.textContent!.replace(/\s+/g, ' ').trim())).toEqual(['معلومات غلط 2', 'حاجة تانية 1']);
      expect(cards[0].textContent).toContain('آخر بلاغ');
      expect(cards[1].querySelector('[data-target-body]')!.textContent).toContain('Buy cheap courses');
      expect(cards[1].querySelector('[data-report-count]')!.textContent!.trim()).toBe('بلاغين');
      expect(cards[2].querySelector('[data-target-user]')!.textContent).toContain('Omar Fathy');
      expect(cards[2].textContent).toContain('تحذيرين');
    });

    it('a status tab and a type load their list; the closed time shows on closed lists', async () => {
      const t = await render({ status: 'resolved', type: 'comment' });
      t.expectQueue({ status: 'resolved', type: 'comment', limit: '20' }).flush({
        items: [item('comment', 'c1', { status: 'resolved', closedAt: '2026-11-02T09:00:00Z', target: { ...item('comment', 'c1').target, state: 'hidden' } })],
        nextCursor: null,
      });
      await t.stable();
      expect(t.$('[data-moderation-tab="resolved"]')!.getAttribute('aria-current')).toBe('page');
      expect(t.$('[data-type-chip="comment"]')!.getAttribute('aria-pressed')).toBe('true');
      // Counts are for open reports only.
      expect(t.$('[data-type-chip="comment"]')!.textContent!.trim()).toBe('تعليقات');
      expect(t.$('[data-case] [data-target-state="hidden"]')!.textContent!.trim()).toBe('متخفي');
      expect(t.$('[data-case]')!.textContent).toContain('اتقفل');

      // Switching tabs keeps the type filter.
      expect(t.$('[data-moderation-tab="dismissed"]')!.getAttribute('href')).toBe('/moderation?status=dismissed&type=comment');
      expect(t.$('[data-moderation-tab="open"]')!.getAttribute('href')).toBe('/moderation?type=comment');
      expect(t.$('[data-moderation-tab="log"]')!.getAttribute('href')).toBe('/moderation/log');

      t.fixture.componentRef.setInput('status', 'dismissed');
      t.fixture.componentRef.setInput('type', 'bogus');
      await t.stable();
      t.expectQueue({ status: 'dismissed', limit: '20' }).flush({ items: [], nextCursor: null });
      await t.stable();
      expect(t.$('[data-queue-empty]')!.textContent).toContain('مفيش بلاغات اترفضت');
    });

    it('the type chips change the URL (deep-linkable)', async () => {
      const t = await render();
      t.expectQueue({ status: 'open', limit: '20' }).flush({ items: [], nextCursor: null });
      await t.stable();
      expect(t.$('[data-queue-empty]')!.textContent).toContain('مفيش بلاغات مفتوحة');
      const navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
      t.$('[data-type-chip="user"]')!.click();
      expect(navigate).toHaveBeenCalledWith(['/moderation'], { queryParams: { status: null, type: 'user' }, replaceUrl: true });
    });

    it('loads more with the cursor, without duplicates; a failed page can be retried', async () => {
      const t = await render();
      t.expectQueue({ status: 'open', limit: '20' }).flush({ items: [item('article', 'a1'), item('article', 'a2')], nextCursor: 'next-1' });
      await t.stable();
      const more = t.$<HTMLButtonElement>('[data-queue-more]')!;
      expect(more.textContent!.trim()).toBe('اعرض أكتر');

      more.click();
      t.expectQueue({ status: 'open', cursor: 'next-1', limit: '20' }).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
      await t.stable();
      expect(t.$('[data-queue-more]')!.textContent!.trim()).toBe('حاول تاني');

      t.$('[data-queue-more]')!.click();
      t.expectQueue({ status: 'open', cursor: 'next-1', limit: '20' }).flush({ items: [item('article', 'a2'), item('user', 'u3')], nextCursor: null });
      await t.stable();
      expect(t.$$('[data-case]').map((c) => c.getAttribute('data-case'))).toEqual(['article:a1', 'article:a2', 'user:u3']);
      expect(t.$('[data-queue-more]')).toBeNull();
    });

    it('shows the error state and retries', async () => {
      const t = await render();
      t.expectQueue({ status: 'open', limit: '20' }).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
      await t.stable();
      expect(t.root.querySelector('rd-error-state')!.textContent).toContain('معرفناش نحمّل البلاغات.');
      (t.root.querySelector('rd-error-state button') as HTMLElement).click();
      t.expectQueue({ status: 'open', limit: '20' }).flush({ items: [item('user', 'u1')], nextCursor: null });
      await t.stable();
      expect(t.$$('[data-case]')).toHaveLength(1);
    });
  });

  describe('case', () => {
    async function render(type: string, id: string, data: ModerationCaseDto | { status: number; code: string } | null, permissions = MODERATOR) {
      ({ http } = setup(permissions));
      answerSummary(http);
      const fixture = TestBed.createComponent(ModerationCasePage);
      fixture.componentRef.setInput('type', type);
      fixture.componentRef.setInput('id', id);
      fixture.detectChanges();
      await fixture.whenStable();
      answerSummary(http);
      const root = fixture.nativeElement as HTMLElement;
      const stable = async () => {
        await flushMicrotasks();
        fixture.detectChanges();
        await fixture.whenStable();
      };
      if (data) {
        const req = http.expectOne(`${TEST_API}/moderation/reports/${type}/${id}`);
        if ('status' in data) req.flush(problem(data.status, data.code), { status: data.status, statusText: 'Error' });
        else req.flush(data);
        await stable();
      }
      const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
      const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
      const actions = () => $$('[data-case-action]').map((a) => a.getAttribute('data-case-action'));
      return { fixture, root, stable, $, $$, actions };
    }

    it('an article case: preview with its link, reasons, reports, empty history and the actions', async () => {
      const t = await render('article', 'a1', caseOf(item('article', 'a1')));
      expect(t.$('h1')!.textContent!.trim()).toBe('بلاغ عن مقال');
      expect(t.$('[data-case-status]')!.textContent!.trim()).toBe('مفتوح');
      expect(t.$('[data-case-link]')!.getAttribute('href')).toBe('/en/a/sleep-and-memory');
      expect(t.$('[data-case-link]')!.textContent).toContain('افتح المقال');
      expect(t.$('[data-case-back]')!.getAttribute('href')).toBe('/moderation');

      const reports = t.$$('[data-report]');
      expect(reports).toHaveLength(2);
      expect(reports[0].textContent).toContain('Reader r1');
      expect(reports[0].querySelector('[data-report-reason]')!.textContent!.trim()).toBe('معلومات غلط');
      expect(reports[0].querySelector('[data-report-details]')!.textContent).toContain('The study says the opposite.');
      expect(t.$('[data-case-no-history]')!.textContent!.trim()).toBe('مفيش إجراءات لسه.');

      expect(t.actions()).toEqual(['hide', 'warnAuthor', 'suspendAuthor', 'dismiss']);
      expect(t.$$('[data-case-action]').map((a) => a.textContent!.trim())).toEqual(['إخفاء المقال', 'تحذير الكاتب', 'إيقاف حساب الكاتب', 'رفض البلاغات']);
    });

    it('hide asks first, sends the note, then reloads the case and the badge', async () => {
      const t = await render('article', 'a1', caseOf(item('article', 'a1')));
      t.$('[data-case-action="hide"]')!.click();
      await t.stable();
      expect(t.$('[data-moderation-sheet]')!.getAttribute('data-moderation-action')).toBe('hide');
      expect(t.$('[data-moderation-sheet]')!.closest('[role]')!.getAttribute('role')).toBe('alertdialog');
      const note = t.$<HTMLTextAreaElement>('[data-moderation-note]')!;
      note.value = 'Misleading health claims.';
      note.dispatchEvent(new Event('input'));
      await t.stable();
      t.$('[data-moderation-confirm]')!.click();
      const req = http.expectOne(ACTIONS);
      expect(req.request.body).toEqual({ action: 'hide', targetType: 'article', targetId: 'a1', note: 'Misleading health claims.' });
      req.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();

      const hidden = item('article', 'a1', { status: 'resolved', closedAt: '2026-11-03T09:00:00Z', target: { ...item('article', 'a1').target, state: 'hidden' } });
      http.expectOne(`${TEST_API}/moderation/reports/article/a1`).flush(
        caseOf(hidden, { history: [logOf('h1', { action: 'article.hide', targetType: 'article', targetId: 'a1', targetLabel: 'How sleep turns reading into memory', note: 'Misleading health claims.' })] }),
      );
      answerSummary(http, 2);
      await t.stable();
      expect(t.$('[data-case-status]')!.textContent!.trim()).toBe('اتحل');
      expect(t.actions()).toEqual(['unhide', 'warnAuthor', 'suspendAuthor']);
      const history = t.$$('[data-case-history] [data-log-entry]');
      expect(history).toHaveLength(1);
      expect(history[0].textContent).toContain('Nour Fawzy');
      expect(history[0].textContent).toContain('خفى مقال');
      expect(history[0].querySelector('[data-log-note]')!.textContent).toContain('Misleading health claims.');
      // On its own case the target isn't a link.
      expect(history[0].querySelector('[data-log-target]')).toBeNull();
    });

    it('warning the author from a comment resolves the comment\'s reports too; a note is required', async () => {
      const t = await render('comment', 'c1', caseOf(item('comment', 'c1')));
      expect(t.actions()).toEqual(['hide', 'delete', 'warnAuthor', 'suspendAuthor', 'dismiss']);
      expect(t.$('[data-case-link]')!.getAttribute('href')).toBe('/ar/a/sleep-and-memory');
      t.$('[data-case-action="warnAuthor"]')!.click();
      await t.stable();
      expect(t.$('#moderation-sheet-title')!.textContent!.trim()).toBe('تحذير ⁨Omar Fathy⁩');
      expect(t.$<HTMLButtonElement>('[data-moderation-confirm]')!.disabled).toBe(true);
      const note = t.$<HTMLTextAreaElement>('[data-moderation-note]')!;
      note.value = 'No ads in comments.';
      note.dispatchEvent(new Event('input'));
      await t.stable();
      t.$('[data-moderation-confirm]')!.click();
      const req = http.expectOne(ACTIONS);
      expect(req.request.body).toEqual({
        action: 'warn',
        targetType: 'user',
        targetId: 'writer-2',
        note: 'No ads in comments.',
        resolveReportsOf: { targetType: 'comment', targetId: 'c1' },
      });
      req.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      http.expectOne(`${TEST_API}/moderation/reports/comment/c1`).flush(caseOf(item('comment', 'c1', { status: 'resolved', closedAt: '2026-11-03T09:00:00Z' })));
      answerSummary(http);
      await t.stable();
      expect(t.actions()).toEqual(['hide', 'delete', 'warnAuthor', 'suspendAuthor']);
    });

    it('a user case: warn, suspend or unsuspend (with users.suspend), dismiss', async () => {
      const t = await render('user', 'u9', caseOf(item('user', 'u9')));
      expect(t.actions()).toEqual(['warn', 'suspend', 'dismiss']);
      expect(t.$('[data-case-link]')!.getAttribute('href')).toBe('/@omar_dev');

      t.$('[data-case-action="dismiss"]')!.click();
      await t.stable();
      expect(t.$('#moderation-sheet-title')!.textContent!.trim()).toBe('ترفض البلاغات دي؟');
      t.$('[data-moderation-confirm]')!.click();
      const req = http.expectOne(ACTIONS);
      expect(req.request.body).toEqual({ action: 'dismiss', targetType: 'user', targetId: 'u9' });
      req.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      const suspended = item('user', 'u9', { status: 'dismissed', closedAt: '2026-11-03T09:00:00Z', target: { state: 'suspended', author: AUTHOR, suspendedUntil: '2026-11-10T09:00:00Z', warningCount: 2 } });
      http.expectOne(`${TEST_API}/moderation/reports/user/u9`).flush(caseOf(suspended));
      answerSummary(http);
      await t.stable();
      expect(t.actions()).toEqual(['warn', 'unsuspend']);
      expect(t.$('[data-case-target]')!.textContent).toContain('موقوف لحد');
    });

    it('without users.suspend there is no suspend or unsuspend', async () => {
      const t = await render('user', 'u9', caseOf(item('user', 'u9')), ['articles.read', 'moderation.manage']);
      expect(t.actions()).toEqual(['warn', 'dismiss']);
    });

    it('a user case lists their writer categories; "Clear name" sends clear_category with the category (F31)', async () => {
      const categories = [
        { id: 'cat-1', slug: 'rude', name: 'مقالات للأغبيا بس', articleCount: 0, sortOrder: 1 },
        { id: 'cat-2', slug: 'notes', name: 'Notes', articleCount: 3, sortOrder: 2 },
      ];
      const t = await render('user', 'u9', caseOf(item('user', 'u9'), { categories }));
      const rows = t.$$('[data-case-category]');
      expect(rows).toHaveLength(2);
      expect(rows[0].querySelector('[data-case-category-name]')!.getAttribute('dir')).toBe('auto');
      expect(rows[0].querySelector('a')!.getAttribute('href')).toBe('/@omar_dev/c/rude');
      expect(rows[0].textContent).toContain('لسه مفيش مقالات');
      expect(rows[1].textContent).toContain('3 مقالات');
      // Not one of the case's own actions.
      expect(t.actions()).toEqual(['warn', 'suspend', 'dismiss']);

      rows[0].querySelector<HTMLElement>('[data-case-clear-category]')!.click();
      await t.stable();
      expect(t.$('[data-moderation-sheet]')!.getAttribute('data-moderation-action')).toBe('clear_category');
      expect(t.$('#moderation-sheet-title')!.textContent!.trim()).toBe('تمسح اسم القسم «\u2068مقالات للأغبيا بس\u2069»؟');
      t.$('[data-moderation-confirm]')!.click();
      const req = http.expectOne(ACTIONS);
      expect(req.request.body).toEqual({ action: 'clear_category', targetType: 'user', targetId: 'u9', categoryId: 'cat-1' });
      req.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      const cleared = item('user', 'u9', { status: 'resolved', closedAt: '2026-11-03T09:00:00Z' });
      http.expectOne(`${TEST_API}/moderation/reports/user/u9`).flush(
        caseOf(cleared, {
          categories: [{ ...categories[0], name: 'قسم 1', slug: 'قسم-1' }, categories[1]],
          history: [logOf('h1', { action: 'user.clear_category', targetType: 'user', targetId: 'u9', targetLabel: 'مقالات للأغبيا بس', note: null })],
        }),
      );
      answerSummary(http);
      await t.stable();
      expect(t.$$('[data-case-category-name]').map((n) => n.textContent!.trim())).toEqual(['قسم 1', 'Notes']);
      expect(t.$('[data-case-history]')!.textContent).toContain('مسح اسم قسم');
      expect(t.$('[data-case-history] [data-log-entry]')!.getAttribute('data-log-action')).toBe('user.clear_category');
    });

    it('a user case shows their title and links (F14); "امسح الروابط" and "امسح المسمى" confirm, then send clear_links / clear_headline', async () => {
      const user = { ...AUTHOR, headline: 'أحسن مدرب في مصر | اشتري الكورس' };
      const links = [
        { platform: 'instagram' as const, url: 'https://instagram.com/cheap.courses', label: null },
        { platform: 'other' as const, url: 'https://spam.example/buy', label: 'اشتري' },
      ];
      const userItem = item('user', 'u9', { target: { state: 'active', author: user, suspendedUntil: null, warningCount: 0, links } });
      const t = await render('user', 'u9', caseOf(userItem, { categories: [] }));
      const section = t.$('[data-case-profile]')!;
      expect(section.querySelector('#case-profile-title')!.textContent).toContain('المسمى والروابط');
      expect(section.querySelector('[data-case-headline]')!.textContent!.trim()).toBe('أحسن مدرب في مصر | اشتري الكورس');
      expect(section.querySelector('[data-case-headline]')!.getAttribute('dir')).toBe('rtl');
      const rows = [...section.querySelectorAll('[data-case-link]')];
      expect(rows.map((r) => r.getAttribute('data-case-link'))).toEqual(['instagram', 'other']);
      expect(rows[0].textContent).toContain('Instagram');
      expect(rows[1].textContent).toContain('اشتري');
      // The whole address, LTR, never followed by crawlers.
      const url = rows[0].querySelector<HTMLAnchorElement>('[data-case-link-url]')!;
      expect(url.textContent!.trim()).toBe('https://instagram.com/cheap.courses');
      expect(url.getAttribute('dir')).toBe('ltr');
      expect(url.rel).toContain('nofollow');

      // Clear title: a confirmation with an optional note.
      section.querySelector<HTMLElement>('[data-case-clear-headline]')!.click();
      await t.stable();
      expect(t.$('[data-moderation-sheet]')!.getAttribute('data-moderation-action')).toBe('clear_headline');
      expect(t.$('#moderation-sheet-title')!.textContent).toContain('تمسح مسمى');
      expect(t.$('#moderation-sheet-body')!.textContent).toContain('مش هيوصله إشعار');
      expect(t.$<HTMLButtonElement>('[data-moderation-confirm]')!.disabled).toBe(false); // the note is optional
      t.$('[data-moderation-confirm]')!.click();
      let req = http.expectOne(ACTIONS);
      expect(req.request.body).toEqual({ action: 'clear_headline', targetType: 'user', targetId: 'u9' });
      req.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      const cleared = item('user', 'u9', {
        status: 'resolved',
        closedAt: '2026-11-03T09:00:00Z',
        target: { state: 'active', author: { ...user, headline: null }, suspendedUntil: null, warningCount: 0, links },
      });
      http.expectOne(`${TEST_API}/moderation/reports/user/u9`).flush(
        caseOf(cleared, { categories: [], history: [logOf('h1', { action: 'user.clear_headline', targetType: 'user', targetId: 'u9', targetLabel: user.headline, note: null })] }),
      );
      answerSummary(http);
      await t.stable();
      expect(t.$('[data-case-no-headline]')!.textContent!.trim()).toBe('مفيش مسمى.');
      expect(t.$('[data-case-clear-headline]')).toBeNull();
      expect(t.$('[data-case-history]')!.textContent).toContain('مسح مسمى مستخدم');

      // Clear links, with a note.
      t.$('[data-case-clear-links]')!.click();
      await t.stable();
      expect(t.$('[data-moderation-sheet]')!.getAttribute('data-moderation-action')).toBe('clear_links');
      expect(t.$('#moderation-sheet-title')!.textContent).toContain('تمسح كل روابط');
      const note = t.$<HTMLTextAreaElement>('[data-moderation-note]')!;
      note.value = 'روابط سبام';
      note.dispatchEvent(new Event('input'));
      await t.stable();
      t.$('[data-moderation-confirm]')!.click();
      req = http.expectOne(ACTIONS);
      expect(req.request.body).toEqual({ action: 'clear_links', targetType: 'user', targetId: 'u9', note: 'روابط سبام' });
      req.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      http.expectOne(`${TEST_API}/moderation/reports/user/u9`).flush(
        caseOf(item('user', 'u9', { status: 'resolved', target: { state: 'active', author: { ...user, headline: null }, suspendedUntil: null, warningCount: 0, links: [] } }), {
          categories: [],
          history: [logOf('h2', { action: 'user.clear_links', targetType: 'user', targetId: 'u9', targetLabel: links.map((l) => l.url).join(' '), note: 'روابط سبام' })],
        }),
      );
      answerSummary(http);
      await t.stable();
      expect(t.$('[data-case-no-links]')!.textContent!.trim()).toBe('مفيش روابط.');
      expect(t.$('[data-case-clear-links]')).toBeNull();
      expect(t.$('[data-case-history] [data-log-entry]')!.getAttribute('data-log-action')).toBe('user.clear_links');
      expect(t.$('[data-case-history]')!.textContent).toContain('مسح روابط مستخدم');
    });

    it('a user without a title or links (or an API older than F14): nothing to clear', async () => {
      const t = await render('user', 'u9', caseOf(item('user', 'u9'), { categories: [] }));
      expect(t.$('[data-case-no-headline]')).not.toBeNull();
      expect(t.$('[data-case-no-links]')).not.toBeNull();
      expect(t.$('[data-case-clear-headline]')).toBeNull();
      expect(t.$('[data-case-clear-links]')).toBeNull();
    });

    it('article and comment cases have no title and links section', async () => {
      const t = await render('article', 'a1', caseOf(item('article', 'a1'), { categories: [] }));
      expect(t.$('[data-case-profile]')).toBeNull();
    });

    it('a user without categories: the section says so (as on mobile)', async () => {
      const t = await render('user', 'u9', caseOf(item('user', 'u9'), { categories: [] }));
      expect(t.$('#case-categories-title')!.textContent).toContain('أقسام الكاتب');
      expect(t.$('[data-case-no-categories]')!.textContent!.trim()).toBe('مفيش أقسام.');
      expect(t.$$('[data-case-category]')).toHaveLength(0);
    });

    it('article and comment cases have no categories section', async () => {
      const t = await render('article', 'a1', caseOf(item('article', 'a1'), { categories: [] }));
      expect(t.$('[data-case-categories]')).toBeNull();
    });

    it('a deleted comment by a deleted account can only be dismissed', async () => {
      const gone = item('comment', 'c2', { target: { state: 'deleted', author: null, body: 'old text', articleSlug: 'x', articleTitle: 'X' } });
      const t = await render('comment', 'c2', caseOf(gone));
      expect(t.actions()).toEqual(['dismiss']);
      expect(t.$('[data-case-link]')).toBeNull();
      expect(t.$('[data-case-target]')!.textContent).toContain('مستخدم محذوف');
    });

    it('not found: a 404 or an unknown type (without asking the API)', async () => {
      const missing = await render('article', 'gone', { status: 404, code: 'report.target_not_found' });
      expect(missing.$('[data-case-not-found]')!.textContent).toContain('البلاغ ده مش موجود');
      http.verify();

      TestBed.resetTestingModule();
      const bogus = await render('bogus', 'x', null);
      await bogus.stable();
      expect(bogus.$('[data-case-not-found]')).not.toBeNull();
    });

    it('a load error can be retried', async () => {
      const t = await render('article', 'a1', { status: 500, code: 'server.error' });
      expect(t.root.querySelector('rd-error-state')!.textContent).toContain('معرفناش نحمّل البلاغ ده.');
      (t.root.querySelector('rd-error-state button') as HTMLElement).click();
      http.expectOne(`${TEST_API}/moderation/reports/article/a1`).flush(caseOf(item('article', 'a1')));
      await t.stable();
      expect(t.$('[data-case-target]')).not.toBeNull();
    });
  });

  describe('log', () => {
    it('lists every action newest first, with who, what, the note, the suspension and the reports it closed', async () => {
      ({ http } = setup());
      answerSummary(http);
      const fixture = TestBed.createComponent(ModerationLogPage);
      fixture.detectChanges();
      await fixture.whenStable();
      const root = fixture.nativeElement as HTMLElement;
      const stable = async () => {
        await flushMicrotasks();
        fixture.detectChanges();
        await fixture.whenStable();
      };
      expect(root.querySelector('[data-moderation-tab="log"]')!.getAttribute('aria-current')).toBe('page');
      const first = http.expectOne((r) => r.url === ACTIONS && r.method === 'GET');
      expect(first.request.params.get('limit')).toBe('30');
      first.flush({
        items: [
          logOf('l1', { action: 'user.suspend', targetType: 'user', targetId: 'u9', targetLabel: '@omar_dev', suspendedUntil: '2026-11-10T09:00:00Z', reportsClosed: 1 }),
          logOf('l2', { action: 'user.suspend', targetType: 'user', targetId: 'u8', targetLabel: '@spammer', moderator: null, note: null, reportsClosed: 0 }),
        ],
        nextCursor: 'c2',
      });
      await stable();
      const entries = [...root.querySelectorAll('[data-log-entry]')];
      expect(entries).toHaveLength(2);
      expect(entries[0].textContent).toContain('Nour Fawzy');
      expect(entries[0].textContent).toContain('وقف حساب');
      expect(entries[0].textContent).toContain('لحد');
      expect(entries[0].textContent).toContain('قفل بلاغ واحد');
      expect(entries[0].querySelector('[data-log-target]')!.getAttribute('href')).toBe('/moderation/user/u9');
      expect(entries[1].textContent).toContain('مشرف محذوف');
      expect(entries[1].textContent).toContain('نهائي');
      expect(entries[1].querySelector('[data-log-note]')).toBeNull();

      (root.querySelector('[data-log-more]') as HTMLElement).click();
      const next = http.expectOne((r) => r.url === ACTIONS && r.method === 'GET');
      expect(next.request.params.get('cursor')).toBe('c2');
      next.flush({ items: [logOf('l3')], nextCursor: null });
      await stable();
      expect(root.querySelectorAll('[data-log-entry]')).toHaveLength(3);
      expect(root.querySelector('[data-log-more]')).toBeNull();
    });

    it('has an empty state', async () => {
      ({ http } = setup());
      answerSummary(http);
      const fixture = TestBed.createComponent(ModerationLogPage);
      fixture.detectChanges();
      await fixture.whenStable();
      http.expectOne((r) => r.url === ACTIONS).flush({ items: [], nextCursor: null });
      await flushMicrotasks();
      fixture.detectChanges();
      expect((fixture.nativeElement as HTMLElement).querySelector('[data-log-empty]')!.textContent).toContain('السجل فاضي');
    });
  });

  describe('route', () => {
    function moderationRoute() {
      const shell = routes.find((r) => r.path === '' && r.children)!;
      return shell.children!.find((r) => r.path === 'moderation')!;
    }

    async function guard(me: ReturnType<typeof testMe> | null): Promise<string | true> {
      TestBed.resetTestingModule();
      let session: SessionStore;
      ({ http, session } = setupSocialTesting({ guest: !me, providers: [{ provide: AuthService, useValue: { whenReady: async () => me } }] }));
      if (me) session.setMe(me);
      const canActivate = moderationRoute().canActivate![0] as (route: ActivatedRouteSnapshot, state: RouterStateSnapshot) => Promise<boolean | UrlTree>;
      const result = await TestBed.runInInjectionContext(() => canActivate({} as ActivatedRouteSnapshot, { url: '/moderation' } as RouterStateSnapshot));
      return result === true ? true : TestBed.inject(Router).serializeUrl(result as UrlTree);
    }

    it('needs moderation.manage: members go home, guests to sign in; the queue, log and cases are lazy', async () => {
      expect(await guard(testMe({ permissions: MODERATOR }))).toBe(true);
      expect(await guard(testMe({ permissions: ['articles.read'] }))).toBe('/');
      expect(await guard(null)).toBe('/auth/sign-in?returnUrl=%2Fmoderation');
      expect(moderationRoute().loadChildren).toBeDefined();
      expect(moderationRoutes.map((r) => r.path)).toEqual(['', 'log', ':type/:id']);
    });
  });
});
