import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, WARM_UP_TIMEOUT_MS, flushMicrotasks, problem, setupSocialTesting, testCard, warmUpPostCards } from '../../../testing/social-testing';
import { ArticleCardDto, CursorPage } from '../../core/api/models';
import { RankingPage } from './ranking.page';

const card = (n: number): ArticleCardDto => testCard({ id: `a${n}`, slug: `article-${n}`, title: `Article ${n}` });
const page = (from: number, count: number, nextCursor: string | null): CursorPage<ArticleCardDto> => ({
  items: Array.from({ length: count }, (_, i) => card(from + i)),
  nextCursor,
});

describe('RankingPage (F15 "See all")', () => {
  let http: HttpTestingController;

  // The cards prefetch their preview chunk: load it once here, not inside the first test (see warmUpPostCards).
  beforeAll(warmUpPostCards, WARM_UP_TIMEOUT_MS);

  afterEach(() => http?.verify());

  async function render(ranking: 'trending' | 'most-saved', first: CursorPage<ArticleCardDto> | { status: number; code: string }) {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ guest: true }));
    const fixture = TestBed.createComponent(RankingPage);
    fixture.componentRef.setInput('ranking', ranking);
    fixture.detectChanges();
    const req = http.expectOne((r) => r.url === `${TEST_API}/explore/${ranking}` && r.params.get('limit') === '20' && !r.params.has('cursor'));
    if ('code' in first) req.flush(problem(first.status, first.code), { status: first.status, statusText: 'Error' });
    else req.flush(first);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
      fixture.detectChanges();
    };
    await stable();
    return { fixture, root, stable, $: <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector) };
  }

  const text = (el: Element | null) => el?.textContent?.replace(/\s+/g, ' ').trim() ?? null;

  it('trending: the title, post cards best first, the next page near the end (no card twice), then the end', async () => {
    const { root, $, stable, fixture } = await render('trending', page(1, 20, '20'));
    expect(text($('h1'))).toBe('الأكثر رواجًا هذا الأسبوع');
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(20);
    expect($('[data-list-end]')).toBeNull();

    const pages = fixture.componentInstance['pages'];
    const more = pages.loadMore();
    // Rankings move while people read: an article already shown comes back on page 2.
    http.expectOne((r) => r.url === `${TEST_API}/explore/trending` && r.params.get('cursor') === '20').flush({ items: [card(20), card(21), card(22)], nextCursor: null });
    await more;
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(22);
    expect(text($('[data-list-end]'))).toBe('هذه كل المقالات الرائجة هذا الأسبوع.');
  });

  it('most saved: its own texts and its empty state', async () => {
    const { $ } = await render('most-saved', page(1, 0, null));
    expect(text($('h1'))).toBe('الأكثر حفظًا');
    expect(text($('[data-list-empty] h3'))).toBe('لا توجد مقالات محفوظة بعد');
  });

  it('a failure shows an error with Retry; a page that fails to load more offers Retry and keeps the cards', async () => {
    const { $, root, stable, fixture } = await render('trending', { status: 503, code: 'server.error' });
    expect(text($('rd-error-state'))).toContain('تعذّر تحميل هذه المقالات.');
    $<HTMLButtonElement>('rd-error-state button')!.click();
    http.expectOne((r) => r.url === `${TEST_API}/explore/trending` && !r.params.has('cursor')).flush(page(1, 20, '20'));
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(20);

    const more = fixture.componentInstance['pages'].loadMore();
    http.expectOne((r) => r.params.get('cursor') === '20').flush(problem(503, 'server.error'), { status: 503, statusText: 'Error' });
    await more;
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(20);
    $<HTMLButtonElement>('[data-load-more-retry]')!.click();
    http.expectOne((r) => r.params.get('cursor') === '20').flush(page(21, 1, null));
    await stable();
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(21);
  });
});
