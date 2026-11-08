import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { ArticleActionBar } from './article-action-bar';
import { ArticleMenu, MenuArticle } from './article-menu';

/**
 * The reader's "⋯" → Download PDF for every member (F33, user decision 2026-11-06): someone else's article has the item
 * before Report and downloads the version on screen; guests see it and get the sign-in prompt, with no request; a
 * moderator gets no item on someone else's hidden article (the API answers 404), while its author keeps it; a post
 * card's menu still has none.
 */
const MODERATOR = ['articles.read', 'reports.create', 'moderation.manage', 'users.suspend'];
const HIDDEN = { hiddenAt: '2026-11-03T09:00:00Z', note: null };

async function render(article: MenuArticle = testCard(), options: { guest?: boolean; permissions?: string[]; myId?: string } = {}) {
  const { http, session, toasts } = setupSocialTesting({ guest: options.guest });
  if (!options.guest) session.setMe(testMe({ id: options.myId ?? 'user-1', permissions: options.permissions ?? ['articles.read', 'reports.create'] }));
  const fixture = TestBed.createComponent(ArticleActionBar);
  fixture.componentRef.setInput('article', article);
  fixture.componentRef.setInput('url', 'https://readin.test/en/a/clean-architecture');
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  const openMenu = async () => {
    root.querySelector<HTMLElement>('[data-article-menu]')!.click();
    await stable();
    return [...document.querySelectorAll('[data-article-menu-panel] [data-menu-action]')].map((el) => el.getAttribute('data-menu-action'));
  };
  const item = (action: string) => document.querySelector<HTMLElement>(`[data-article-menu-panel] [data-menu-action="${action}"]`);
  const pick = async (action: string) => {
    item(action)!.click();
    await stable();
  };
  return { http, toasts, stable, openMenu, item, pick };
}

describe('Reader "⋯" → Download PDF for every member (F33)', () => {
  let http: HttpTestingController;
  /** The file names the browser was asked to save. */
  let clicks: string[];

  beforeEach(() => {
    TestBed.resetTestingModule();
    clicks = [];
    URL.createObjectURL = vi.fn(() => 'blob:http://localhost/pdf-1');
    URL.revokeObjectURL = vi.fn();
    vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function (this: HTMLAnchorElement) {
      clicks.push(this.download);
    });
  });
  afterEach(() => {
    http.verify();
    vi.restoreAllMocks();
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
  });

  it("someone else's article: Download PDF right before Report, and it downloads the version on screen", async () => {
    const t = await render(testCard({ language: 'en' }));
    http = t.http;

    expect(await t.openMenu()).toEqual(['showLess', 'highlights', 'follow', 'muteAuthor', 'blockAuthor', 'muteTopics', 'downloadPdf', 'report']);
    expect(t.item('downloadPdf')!.textContent!.trim()).toBe(TestBed.inject(TranslocoService).translate('pdf.download'));
    expect(t.item('downloadPdf')!.classList).not.toContain('text-error');

    await t.pick('downloadPdf');
    const req = t.http.expectOne((r) => r.url === `${TEST_API}/articles/a1/pdf`);
    expect(req.request.method).toBe('GET');
    expect(req.request.params.get('lang')).toBe('en');
    req.flush(new Blob(['%PDF-1.4'], { type: 'application/pdf' }), {
      headers: { 'Content-Disposition': `attachment; filename="readin-article.pdf"; filename*=UTF-8''clean-architecture-en.pdf` },
    });
    await t.stable();
    expect(clicks).toEqual(['clean-architecture-en.pdf']);
    expect(t.toasts.toasts()).toEqual([]);
  });

  it("an Arabic version on screen asks for the Arabic file; a deleted writer's article has the item too", async () => {
    const t = await render(testCard({ id: 'a2', language: 'ar-EG', author: null }));
    http = t.http;

    expect(await t.openMenu()).toEqual(['showLess', 'highlights', 'muteTopics', 'downloadPdf', 'report']);
    await t.pick('downloadPdf');
    const req = t.http.expectOne((r) => r.url === `${TEST_API}/articles/a2/pdf`);
    expect(req.request.params.get('lang')).toBe('ar-EG');
    req.flush(new Blob(['%PDF-1.4'], { type: 'application/pdf' }), {
      headers: { 'Content-Disposition': `attachment; filename="readin-article.pdf"; filename*=UTF-8''clean-architecture-ar-EG.pdf` },
    });
    await t.stable();
    expect(clicks).toEqual(['clean-architecture-ar-EG.pdf']);
  });

  it('guests see Download PDF and get the sign-in prompt, with no request', async () => {
    const t = await render(testCard(), { guest: true });
    http = t.http;
    const prompt = TestBed.inject(AuthPromptService);

    expect(await t.openMenu()).toContain('downloadPdf');
    await t.pick('downloadPdf');

    expect(prompt.isOpen()).toBe(true);
    t.http.expectNone((r) => r.url.endsWith('/pdf'));
    expect(t.toasts.toasts()).toEqual([]);
  });

  it('a moderator reading a visible article has Download PDF before Report, then Hide after the divider', async () => {
    const t = await render(testCard(), { permissions: MODERATOR });
    http = t.http;
    expect(await t.openMenu()).toEqual(['showLess', 'highlights', 'follow', 'muteAuthor', 'blockAuthor', 'muteTopics', 'downloadPdf', 'report', 'hide']);
  });

  it("someone else's hidden article (a moderator reads it): no Download PDF, since the API answers 404", async () => {
    const t = await render({ ...testCard(), moderation: HIDDEN }, { permissions: MODERATOR });
    http = t.http;
    expect(await t.openMenu()).toEqual(['showLess', 'highlights', 'follow', 'muteAuthor', 'blockAuthor', 'muteTopics', 'report', 'unhide']);
  });

  it('your own hidden article keeps Download PDF: the server explains why it has no file (409)', async () => {
    const t = await render({ ...testCard(), moderation: HIDDEN }, { myId: 'writer-1' });
    http = t.http;
    expect(await t.openMenu()).toEqual(['highlights', 'muteTopics', 'downloadPdf']);

    await t.pick('downloadPdf');
    t.http
      .expectOne((r) => r.url === `${TEST_API}/articles/a1/pdf`)
      .flush(new Blob([JSON.stringify(problem(409, 'article.pdf_hidden'))], { type: 'application/problem+json' }), { status: 409, statusText: 'Conflict' });
    // The ProblemDetails blob is read asynchronously.
    await vi.waitFor(() => expect(t.toasts.toasts()).toHaveLength(1));
    const [toast] = t.toasts.toasts();
    expect(toast.kind).toBe('error');
    expect(toast.message).toBe(TestBed.inject(TranslocoService).translate('errors.article.pdf_hidden'));
    expect(toast.action).toBeNull(); // trying again can't help
    expect(clicks).toEqual([]);
  });

  it("a post card's menu still has no Download PDF on someone else's article", async () => {
    http = (await render(testCard())).http;
    const card = TestBed.createComponent(ArticleMenu);
    card.componentRef.setInput('article', testCard());
    card.detectChanges();
    (card.nativeElement as HTMLElement).querySelector<HTMLElement>('[data-article-menu]')!.click();
    card.detectChanges();
    await card.whenStable();
    const actions = [...document.querySelectorAll('[data-article-menu-panel] [data-menu-action]')].map((el) => el.getAttribute('data-menu-action'));
    expect(actions).toEqual(['showLess', 'follow', 'muteAuthor', 'blockAuthor', 'muteTopics', 'report']);
  });
});
