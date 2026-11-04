import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleModerationDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { ArticleActionBar } from './article-action-bar';
import { MenuArticle } from './article-menu';

const MODERATOR = ['articles.read', 'reports.create', 'moderation.manage', 'users.suspend'];

async function render(article: MenuArticle = testCard(), options: { guest?: boolean; permissions?: string[]; myId?: string } = {}) {
  const { http, session, toasts } = setupSocialTesting({ guest: options.guest });
  if (!options.guest) session.setMe(testMe({ id: options.myId ?? 'user-1', permissions: options.permissions ?? ['articles.read', 'reports.create'] }));
  const fixture = TestBed.createComponent(ArticleActionBar);
  fixture.componentRef.setInput('article', article);
  fixture.componentRef.setInput('url', 'https://readin.test/en/a/clean-architecture');
  const changes: (ArticleModerationDto | null)[] = [];
  fixture.componentInstance.moderationChange.subscribe((value) => changes.push(value));
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  /** Opens the "⋯" menu (a CDK overlay on the document) and lists its actions. */
  const openMenu = async () => {
    $('[data-article-menu]')!.click();
    await stable();
    return [...document.querySelectorAll('[data-article-menu-panel] [data-menu-action]')].map((el) => el.getAttribute('data-menu-action'));
  };
  const pick = async (action: string) => {
    (document.querySelector(`[data-article-menu-panel] [data-menu-action="${action}"]`) as HTMLElement).click();
    await stable();
  };
  return { fixture, root, http, toasts, stable, $, openMenu, pick, changes };
}

describe('Reader "⋯" menu (F22, F28 later)', () => {
  let http: HttpTestingController;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    http.verify();
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
  });

  it("someone else's article: Report article, in the error color, opens the report sheet for it", async () => {
    const t = await render();
    http = t.http;
    expect(t.$('[data-article-menu]')!.getAttribute('aria-label')).toBe('خيارات المقال');
    expect(await t.openMenu()).toEqual(['report']);
    const report = document.querySelector('[data-menu-action="report"]')!;
    expect(report.textContent!.trim()).toBe('الإبلاغ عن المقال');
    expect(report.classList).toContain('text-error');

    await t.pick('report');
    expect(t.$('[data-report-sheet]')!.getAttribute('data-report-target')).toBe('article');
    t.$<HTMLInputElement>('[data-reason="spam"]')!.click();
    await t.stable();
    t.$('[data-report-submit]')!.click();
    const req = t.http.expectOne(`${TEST_API}/reports`);
    expect(req.request.body).toEqual({ targetType: 'article', targetId: 'a1', reason: 'spam' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.$('[data-report-sheet]')).toBeNull();
  });

  it('your own article: no Report, so no menu at all for a member', async () => {
    const t = await render(testCard(), { myId: 'writer-1' });
    http = t.http;
    expect(t.$('[data-article-menu]')).toBeNull();
  });

  it('guests see Report and get the sign-in prompt', async () => {
    const t = await render(testCard(), { guest: true });
    http = t.http;
    expect(await t.openMenu()).toEqual(['report']);
    await t.pick('report');
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
    expect(t.$('[data-report-sheet]')).toBeNull();
  });

  it('moderators also hide, with a note dialog; the reader learns the article is hidden', async () => {
    const t = await render(testCard(), { permissions: MODERATOR });
    http = t.http;
    expect(await t.openMenu()).toEqual(['hide', 'report']);
    expect(document.querySelector('[data-menu-action="hide"]')!.textContent!.trim()).toBe('إخفاء المقال');

    await t.pick('hide');
    const sheet = t.$('[data-moderation-sheet]')!;
    expect(sheet.getAttribute('data-moderation-action')).toBe('hide');
    expect(t.$('#moderation-sheet-title')!.textContent!.trim()).toBe('تخفي المقال ده؟');
    expect(t.$('label[for="moderation-note"]')!.textContent!.trim()).toBe('ملاحظة (اختياري)');
    const confirm = t.$<HTMLButtonElement>('[data-moderation-confirm]')!;
    expect(confirm.disabled).toBe(false); // the note is optional for hide
    expect(confirm.classList).toContain('bg-error');

    const note = t.$<HTMLTextAreaElement>('[data-moderation-note]')!;
    note.value = 'Copied from another site.';
    note.dispatchEvent(new Event('input'));
    await t.stable();
    confirm.click();
    const req = t.http.expectOne(`${TEST_API}/moderation/actions`);
    expect(req.request.body).toEqual({ action: 'hide', targetType: 'article', targetId: 'a1', note: 'Copied from another site.' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();

    expect(t.$('[data-moderation-sheet]')).toBeNull();
    expect(t.changes).toHaveLength(1);
    expect(t.changes[0]!.note).toBe('Copied from another site.');
    expect(Number.isNaN(Date.parse(t.changes[0]!.hiddenAt))).toBe(false);
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['اتخفى']);
  });

  it('a hidden article offers Unhide, at once with a toast', async () => {
    const t = await render({ ...testCard(), moderation: { hiddenAt: '2026-11-03T09:00:00Z', note: null } }, { permissions: MODERATOR });
    http = t.http;
    expect(await t.openMenu()).toEqual(['unhide', 'report']);
    await t.pick('unhide');
    const req = t.http.expectOne(`${TEST_API}/moderation/actions`);
    expect(req.request.body).toEqual({ action: 'unhide', targetType: 'article', targetId: 'a1' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.changes).toEqual([null]);
    expect(t.toasts.toasts().map((toast) => toast.message)).toEqual(['رجع ظاهر']);
  });

  it('a failed hide stays in the dialog with the reason', async () => {
    const t = await render(testCard(), { permissions: MODERATOR });
    http = t.http;
    await t.openMenu();
    await t.pick('hide');
    t.$('[data-moderation-confirm]')!.click();
    t.http.expectOne(`${TEST_API}/moderation/actions`).flush(problem(404, 'article.not_found'), { status: 404, statusText: 'Not Found' });
    await t.stable();
    expect(t.$('[data-moderation-error]')!.textContent!.trim()).toBe('المقال ده مش موجود');
    expect(t.changes).toEqual([]);
  });

  it('a moderator on their own article can hide it but not report it', async () => {
    const t = await render(testCard(), { permissions: MODERATOR, myId: 'writer-1' });
    http = t.http;
    expect(await t.openMenu()).toEqual(['hide']);
  });
});
