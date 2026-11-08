import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { PostCard } from './post-card';

function stubViewport(): void {
  vi.stubGlobal('matchMedia', (query: string) => ({ matches: query.includes('min-width'), media: query, addEventListener: () => undefined, removeEventListener: () => undefined }));
}

async function render(article: ArticleCardDto) {
  stubViewport();
  const { http } = setupSocialTesting();
  await TestBed.inject(LanguageService).setLanguage('ar');
  const fixture = TestBed.createComponent(PostCard);
  fixture.componentRef.setInput('article', article);
  fixture.detectChanges();
  await fixture.whenStable();
  for (const req of http.match((r) => r.url === `${TEST_API}/me/stats`)) req.flush(null, { status: 503, statusText: 'Unavailable' });
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    for (let i = 0; i < 3; i++) {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    }
  };
  await stable();
  // The card prefetches its preview once on screen; not this test's business.
  for (const req of http.match((r) => r.url.endsWith('/preview'))) req.flush(null, { status: 404, statusText: 'Not Found' });
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  return { fixture, root, http, stable, $ };
}

const REPOSTER = { id: 'u-sara', displayName: 'Sara Ali', username: 'sara', avatarUrl: null, isVerified: false };
const reposted = (patch: Partial<NonNullable<ArticleCardDto['repostedBy']>> = {}) =>
  testCard({ repostedBy: { user: REPOSTER, othersCount: 0, repostedAt: '2026-11-03T12:00:00Z', caption: 'Worth a read before your next project.', repostId: 'rp1', ...patch } });

describe('PostCard: reported content is hidden for the reporter (F22, store requirements)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => {
    TestBed.resetTestingModule();
    sessionStorage.clear();
  });
  afterEach(() => {
    http?.verify();
    http = null;
    vi.unstubAllGlobals();
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
  });

  it('an article you reported collapses to a notice; «عرض» brings the card back', async () => {
    const t = await render(testCard({ reportedByMe: true }));
    http = t.http;
    expect(t.$('[data-card-reported]')!.textContent).toContain('أبلغت عن هذا المحتوى، ولن يظهر لك بعد الآن.');
    expect(t.$('article')!.classList).toContain('hidden');
    t.$('[data-reported-show]')!.click();
    await t.stable();
    expect(t.$('[data-card-reported]')).toBeNull();
    expect(t.$('article')!.classList).not.toContain('hidden');
  });

  it('a card you did not report shows as usual', async () => {
    const t = await render(testCard());
    http = t.http;
    expect(t.$('[data-card-reported]')).toBeNull();
    expect(t.$('article')!.classList).not.toContain('hidden');
  });

  it("a repost you reported hides only the reposter's thoughts; the article stays", async () => {
    const t = await render(reposted({ reportedByMe: true }));
    http = t.http;
    expect(t.$('[data-card-repost-caption]')).toBeNull();
    expect(t.$('[data-card-repost] [data-reported-notice]')).not.toBeNull();
    expect(t.$('article')!.classList).not.toContain('hidden');
    t.$('[data-reported-show]')!.click();
    await t.stable();
    expect(t.$('[data-card-repost-caption]')!.textContent!.trim()).toBe('Worth a read before your next project.');
  });

  it('"⋯" → Report repost reports the repost (not the article), then hides its thoughts', async () => {
    const t = await render(reposted());
    http = t.http;
    t.$('[data-article-menu]')!.click();
    await t.stable();
    const actions = [...document.querySelectorAll('[data-article-menu-panel] [data-menu-action]')].map((el) => el.getAttribute('data-menu-action'));
    expect(actions).toEqual(['showLess', 'follow', 'muteAuthor', 'blockAuthor', 'muteTopics', 'report', 'reportRepost']);
    expect(document.querySelector('[data-menu-action="reportRepost"]')!.textContent!.trim()).toBe('الإبلاغ عن إعادة النشر');
    (document.querySelector('[data-menu-action="reportRepost"]') as HTMLElement).click();
    await t.stable();
    expect(t.$('#report-sheet-title')!.textContent!.trim()).toBe('الإبلاغ عن إعادة النشر');
    // "Also block" names the reposter.
    expect(t.$('[data-also-block]')!.textContent).toContain('@sara');
    t.$<HTMLInputElement>('[data-reason="spam"]')!.click();
    await t.stable();
    t.$('[data-report-submit]')!.click();
    const req = t.http.expectOne(`${TEST_API}/reports`);
    expect(req.request.body).toEqual({ targetType: 'repost', targetId: 'rp1', reason: 'spam' });
    req.flush(null, { status: 204, statusText: 'No Content' });
    await t.stable();
    expect(t.$('[data-card-repost-caption]')).toBeNull();
    expect(t.$('article')!.classList).not.toContain('hidden');
  });

  it('a repost label without a repost id (an older API) has no Report repost', async () => {
    const t = await render(reposted({ repostId: undefined }));
    http = t.http;
    t.$('[data-article-menu]')!.click();
    await t.stable();
    expect(document.querySelector('[data-menu-action="reportRepost"]')).toBeNull();
  });
});
