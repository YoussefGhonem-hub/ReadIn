import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { testPathCard } from '../../../testing/paths-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ExploreDto, FieldSummaryDto, UserSummaryDto } from '../../core/api/models';
import { ExplorePage } from './explore.page';

const field = (slug: string, nameAr: string, nameEn: string, articleCount: number, patch: Partial<FieldSummaryDto> = {}): FieldSummaryDto => ({
  id: `f-${slug}`,
  slug,
  name: nameAr,
  nameAr,
  nameEn,
  icon: 'code',
  color: 'primary',
  articleCount,
  ...patch,
});
const cards = (prefix: string, count: number) => Array.from({ length: count }, (_, i) => testCard({ id: `${prefix}${i + 1}`, slug: `${prefix}-${i + 1}`, title: `${prefix} ${i + 1}` }));
const writer = (id: string, patch: Partial<UserSummaryDto> = {}): UserSummaryDto => ({
  id,
  displayName: 'سلمى إبراهيم',
  username: `salma_${id}`,
  avatarUrl: null,
  isVerified: true,
  bio: null,
  isFollowing: false,
  followsYou: false,
  ...patch,
});

const EXPLORE: ExploreDto = {
  fields: [field('software', 'البرمجيات', 'Software', 32), field('medicine', 'الطب', 'Medicine', 1, { icon: 'stethoscope', color: 'success' }), field('design', 'التصميم', 'Design', 0)],
  trending: cards('trending', 6),
  mostSaved: cards('saved', 6),
  newWriters: [writer('1'), writer('2', { isFollowing: true })],
  featuredPaths: [testPathCard({ id: 'p1', slug: 'web' }), testPathCard({ id: 'p2', slug: 'ai' })],
};

describe('ExplorePage (F15)', () => {
  let http: HttpTestingController;

  afterEach(() => http?.verify());

  async function render(body: ExploreDto | { status: number; code: string } = EXPLORE) {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ guest: true }));
    const fixture = TestBed.createComponent(ExplorePage);
    fixture.detectChanges();
    const req = http.expectOne(`${TEST_API}/explore`);
    if ('code' in body) req.flush(problem(body.status, body.code), { status: body.status, statusText: 'Error' });
    else req.flush(body);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      // Path covers without an image take their field's icon (GET /fields, once per app); SSR would wait for them.
      http.match(`${TEST_API}/fields`).forEach((r) => r.flush([]));
      await flushMicrotasks();
      fixture.detectChanges();
    };
    await stable();
    return { fixture, root, stable, $: <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector) };
  }

  const text = (el: Element | null) => el?.textContent?.replace(/\s+/g, ' ').trim() ?? null;

  it('shows every field, the first trending and most saved articles with "See all", new writers and featured paths', async () => {
    const { root, $ } = await render();
    const tiles = [...root.querySelectorAll<HTMLAnchorElement>('[data-field-tile]')];
    expect(tiles.map((t) => t.getAttribute('href'))).toEqual(['/f/software', '/f/medicine', '/f/design']);
    expect(text(tiles[0].querySelector('rd-bdi-text'))).toBe('البرمجيات');
    expect(text(tiles[0].querySelector('[data-field-count]'))).toBe('32 مقال');
    // An empty field is listed too: its page says so.
    expect(text(tiles[2].querySelector('[data-field-count]'))).toBe('0 مقال');

    // Three of each ranking as compact rows; the rest is on its own page.
    expect([...root.querySelectorAll('[data-explore-trending] rd-article-card h3')].map((h) => text(h))).toEqual(['trending 1', 'trending 2', 'trending 3']);
    expect(root.querySelectorAll('[data-explore-most-saved] rd-article-card')).toHaveLength(3);
    expect($('[data-see-all="trending"]')!.getAttribute('href')).toBe('/explore/trending');
    expect($('[data-see-all="most-saved"]')!.getAttribute('href')).toBe('/explore/most-saved');
    expect(text($('[data-see-all="trending"]'))).toBe('عرض الكل · الترند الأسبوع ده');

    // New writers with Follow (a guest sees it too: tapping asks to sign in).
    expect(root.querySelectorAll('[data-explore-new-writers] [data-writer]')).toHaveLength(2);
    expect(root.querySelectorAll('[data-explore-new-writers] [data-follow]')).toHaveLength(2);
    expect($('[data-explore-new-writers] [data-writer] a')!.getAttribute('href')).toBe('/@salma_1');

    expect(root.querySelectorAll('[data-explore-paths] rd-path-card')).toHaveLength(2);
    expect($('[data-see-all="paths"]')!.getAttribute('href')).toBe('/paths');
    // The way into Search on narrow screens.
    expect($('[data-explore-search]')!.getAttribute('href')).toBe('/search');
    expect($('[data-explore-empty]')).toBeNull();
  });

  it('leaves out the sections with nothing in them', async () => {
    const { root, $ } = await render({ ...EXPLORE, trending: [], newWriters: [], featuredPaths: [] });
    expect($('[data-explore-fields]')).not.toBeNull();
    expect($('[data-explore-trending]')).toBeNull();
    expect($('[data-explore-most-saved]')).not.toBeNull();
    expect($('[data-explore-new-writers]')).toBeNull();
    expect($('[data-explore-paths]')).toBeNull();
    expect(root.querySelectorAll('[data-explore-most-saved] rd-article-card')).toHaveLength(3);
  });

  it('says so when every section is empty', async () => {
    const { $ } = await render({ fields: [], trending: [], mostSaved: [], newWriters: [], featuredPaths: [] });
    expect(text($('[data-explore-empty] h3'))).toBe('لسه مفيش حاجة تستكشفها');
    expect($('[data-explore-fields]')).toBeNull();
  });

  it('a failure shows an error with Retry, which loads the page again', async () => {
    const { $, root, stable } = await render({ status: 503, code: 'server.error' });
    expect(text($('rd-error-state'))).toContain('معرفناش نحمّل صفحة الاستكشاف.');
    $<HTMLButtonElement>('rd-error-state button')!.click();
    http.expectOne(`${TEST_API}/explore`).flush(EXPLORE);
    await stable();
    expect(root.querySelectorAll('[data-field-tile]')).toHaveLength(3);
  });
});
