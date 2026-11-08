import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testDetails } from '../../../testing/social-testing';
import { ArticleDetailsDto } from '../../core/api/models';
import { BlockStore } from '../../core/social/block.store';
import { ArticlePage } from './article.page';

const SLUG = 'clean-architecture';
const ARTICLE = `${TEST_API}/articles/${SLUG}?lang=en`;
const OMAR = { id: 'writer-1', displayName: 'Karim Hassan', username: 'karim' };

/** The reader, signed in; `first` answers the article request (an article, or a refusal). */
async function render(first: ArticleDetailsDto | { status: number; code: string; blockedUser?: typeof OMAR }) {
  const { http } = setupSocialTesting();
  const fixture = TestBed.createComponent(ArticlePage);
  fixture.componentRef.setInput('lang', 'en');
  fixture.componentRef.setInput('slug', SLUG);
  fixture.detectChanges();
  await flushMicrotasks();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  const answer = async (response: typeof first) => {
    const req = http.expectOne(ARTICLE);
    if ('status' in response) {
      req.flush({ ...problem(response.status, response.code), ...(response.blockedUser ? { blockedUser: response.blockedUser } : {}) }, { status: response.status, statusText: 'Error' });
    } else {
      req.flush(response);
    }
    await flushMicrotasks();
    fixture.detectChanges();
    // Signed in, the page asks for more (highlights, reading progress, the streak): not these tests' business.
    for (const extra of http.match((r) => r.url !== ARTICLE)) extra.flush(null, { status: 503, statusText: 'Unavailable' });
    await stable();
  };
  await answer(first);
  const $ = (s: string) => root.querySelector<HTMLElement>(s);
  return { fixture, root, http, stable, answer, $ };
}

describe('ArticlePage: blocked writers and reported articles (F36, F22 store)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    for (const extra of http?.match(() => true) ?? []) extra.flush(null, { status: 503, statusText: 'Unavailable' });
    http?.verify();
    http = null;
  });

  it('a writer you blocked: "This content isn\'t available" with Unblock, which loads the article', async () => {
    const t = await render({ status: 403, code: 'block.blocked', blockedUser: OMAR });
    http = t.http;
    const state = t.$('rd-blocked-state')!;
    expect(state.getAttribute('data-blocked-state')).toBe('content');
    expect(state.textContent).toContain('هذا المحتوى غير متاح');
    expect(state.textContent!.replace(/\s+/g, ' ')).toContain('لقد حظرت @karim');
    expect(t.$('[data-article-card]')).toBeNull();

    t.$('[data-unblock]')!.click();
    await t.stable();
    const del = t.http.expectOne(`${TEST_API}/users/writer-1/block`);
    expect(del.request.method).toBe('DELETE');
    del.flush({ userId: 'writer-1', isBlocked: false, followRemoved: false });
    // The page stays unstable while the article is on its way again.
    await flushMicrotasks();
    t.fixture.detectChanges();
    await t.answer(testDetails());
    expect(t.$('rd-blocked-state')).toBeNull();
    expect(t.$('[data-article-card]')).not.toBeNull();
  });

  it('blocking the writer while reading replaces the article at once', async () => {
    const t = await render(testDetails());
    http = t.http;
    expect(t.$('[data-article-card]')).not.toBeNull();
    TestBed.inject(BlockStore).learnBlocked('writer-1');
    await t.stable();
    expect(t.$('rd-blocked-state')!.textContent).toContain('هذا المحتوى غير متاح');
    expect(t.$('[data-article-card]')).toBeNull();
  });

  it('an article you reported collapses to a notice; «عرض» shows it', async () => {
    const t = await render(testDetails({ reportedByMe: true }));
    http = t.http;
    expect(t.$('[data-article-reported]')!.textContent).toContain('أبلغت عن هذا المحتوى، ولن يظهر لك بعد الآن.');
    expect(t.$('[data-article-card]')!.classList).toContain('hidden');
    t.$('[data-reported-show]')!.click();
    await t.stable();
    expect(t.$('[data-article-reported]')).toBeNull();
    expect(t.$('[data-article-card]')!.classList).not.toContain('hidden');
  });
});
