import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Meta } from '@angular/platform-browser';
import { Router } from '@angular/router';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CursorPage, FieldDto, SearchArticleDto, SearchTopicDto, TagDto, UserSummaryDto } from '../../core/api/models';
import { RecentSearches } from './recent-searches';
import { SEARCH_DEBOUNCE_MS } from './search-query';
import { SearchPage } from './search.page';

const isSearch = (r: { url: string }) => r.url === `${TEST_API}/search`;
const FIELDS: FieldDto[] = [
  {
    id: 'f1',
    slug: 'software',
    name: 'البرمجيات',
    nameAr: 'البرمجيات',
    nameEn: 'Software',
    icon: 'code',
    color: 'primary',
    isSensitive: false,
    requiresSources: false,
    topicCount: 2,
  },
];
const PDF_HIT: SearchArticleDto = {
  article: testCard({
    id: 'a-cheat',
    slug: 'cheat-sheet',
    title: 'ASP.NET Core cheat sheet',
    attachments: {
      kind: 'document',
      images: [],
      document: {
        assetId: 'd1',
        title: 'Cheat sheet',
        pageCount: 2,
        allowDownload: false,
        canDownload: false,
        downloadUrl: 'https://x/d1',
        pages: [{ pageNo: 1, width: 1080, height: 1400, blurHash: 'L', thumbUrl: 'https://cdn/p1-thumb.png', viewUrl: 'https://cdn/p1.png' }],
      },
    },
  }),
  matchedIn: 'attachment',
};
const TITLE_HIT: SearchArticleDto = { article: testCard({ id: 'a-docker', slug: 'docker', title: 'Docker in plain words' }), matchedIn: 'title' };
const MONA: UserSummaryDto = { id: 'u-mona', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: true, bio: 'Backend', isFollowing: false, followsYou: true };
const TOPIC: SearchTopicDto = {
  kind: 'topic',
  id: 't1',
  name: '.NET',
  nameAr: '.NET',
  nameEn: '.NET',
  fieldSlug: 'software',
  topicSlug: 'dotnet',
  fieldName: 'البرمجيات',
  icon: 'code',
  color: 'primary',
  articleCount: 12,
};
const TAG: TagDto = { slug: 'csharp', name: 'C#', articleCount: 23 };

describe('SearchPage (F16)', () => {
  let http: HttpTestingController;

  afterEach(() => {
    vi.useRealTimers();
    http?.verify();
    localStorage.removeItem('readin.recentSearches');
  });

  async function render(params: Record<string, string> = {}) {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ guest: true }));
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    const fixture = TestBed.createComponent(SearchPage);
    for (const [name, value] of Object.entries(params)) fixture.componentRef.setInput(name, value);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    await stable();
    for (const req of http.match(`${TEST_API}/fields`)) req.flush(FIELDS);
    await stable();
    const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
    const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
    const box = () => $<HTMLInputElement>('[data-search-input]')!;
    const type = async (value: string) => {
      box().value = value;
      box().dispatchEvent(new Event('input'));
      await stable();
    };
    /** The last navigation's query parameters (the page replaces its own URL). */
    const lastParams = () => {
      const call = navigate.mock.calls.at(-1)!;
      expect(call[1]?.replaceUrl).toBe(true);
      return call[1]?.queryParams as Record<string, string | null>;
    };
    return { fixture, root, $, $$, box, type, stable, navigate, lastParams };
  }

  async function answer<T>(t: { stable: () => Promise<void> }, page: CursorPage<T>) {
    http.expectOne(isSearch).flush(page);
    await t.stable();
  }

  it('shows articles as compact rows; a PDF-only hit says so and shows its first page instead of the attachments', async () => {
    const t = await render({ q: 'kestrel' });
    expect(t.$('[data-search-results]')!.getAttribute('data-status')).toBe('loading');
    expect(t.$('[data-search-loading]')).not.toBeNull();
    await answer(t, { items: [PDF_HIT, TITLE_HIT], nextCursor: null });

    const rows = t.$$('[data-search-article]');
    expect(rows.map((r) => r.getAttribute('data-matched-in'))).toEqual(['attachment', 'title']);
    expect(rows[0].querySelector('[data-in-attachment]')!.textContent!.trim()).toBe('لقيناها في ملف الـ PDF المرفق');
    expect(rows[1].querySelector('[data-in-attachment]')).toBeNull();
    expect(rows[0].querySelector('rd-article-attachments')).toBeNull();
    expect(rows[0].querySelector('img')!.getAttribute('src')).toBe('https://cdn/p1-thumb.png');
    expect(t.$('[data-search-end]')!.textContent!.trim()).toBe('كده شفت كل النتايج.');
    expect(t.box().value).toBe('kestrel');
    expect(t.box().getAttribute('dir')).toBe('auto');
    // Articles is the chosen tab, with its filters.
    expect(t.$('[data-search-tab="articles"]')!.getAttribute('aria-selected')).toBe('true');
    expect(t.$$('[data-search-filters] select').map((s) => s.getAttribute('data-filter'))).toEqual(['field', 'lang', 'time']);
    expect(t.$('[data-search-announce]')!.textContent).toContain('kestrel');
    expect(TestBed.inject(Meta).getTag('name="robots"')?.content).toBe('noindex');
  });

  it('nothing found says so with a tip; with filters it offers to clear them', async () => {
    const t = await render({ q: 'docker يعني' });
    await answer(t, { items: [], nextCursor: null });
    expect(t.$('[data-search-empty] h3')!.textContent!.trim()).toBe('مفيش نتايج لـ «⁨docker يعني⁩»');
    expect(t.$('[data-search-empty]')!.textContent).toContain('جرّب كلمة تانية أو أقصر');

    const f = await render({ q: 'docker', lang: 'en', time: 'long' });
    const req = http.expectOne(isSearch);
    expect(req.request.params.get('minMinutes')).toBe('11');
    req.flush({ items: [], nextCursor: null });
    await f.stable();
    expect(f.$('[data-search-empty="filtered"] h3')!.textContent!.trim()).toBe('مفيش نتايج بالفلاتر دي');
    f.$<HTMLButtonElement>('[data-search-empty="filtered"] button')!.click();
    expect(f.lastParams()).toEqual({ q: 'docker', type: null, field: null, lang: null, time: null });
  });

  it('writers with Follow (and "Follows you"), topics to the field page, tags to the tag page', async () => {
    const users = await render({ q: 'mona', type: 'users' });
    await answer(users, { items: [MONA], nextCursor: null });
    const row = users.$('[data-search-user][data-user="mona"]')!;
    expect(row.textContent).toContain('Mona Adel');
    expect(row.textContent).toContain('بيتابعك');
    expect(row.querySelector('[data-follow]')).not.toBeNull();
    expect(users.$('[data-search-filters]')).toBeNull();

    const topics = await render({ q: 'net', type: 'topics' });
    await answer(topics, { items: [TOPIC], nextCursor: null });
    const topic = topics.$<HTMLAnchorElement>('[data-search-topic]')!;
    expect(topic.getAttribute('href')).toBe('/f/software?topic=dotnet');
    expect(topic.textContent).toContain('موضوع في ⁨البرمجيات⁩');
    expect(topic.textContent).toContain('12 مقال');

    const tags = await render({ q: 'c#', type: 'tags' });
    await answer(tags, { items: [TAG], nextCursor: null });
    const tag = tags.$<HTMLAnchorElement>('[data-search-tag]')!;
    expect(tag.getAttribute('href')).toBe('/tags/csharp');
    expect(tag.querySelector('bdi')!.textContent).toBe('#C#');
    expect(tag.querySelector('bdi')!.getAttribute('dir')).toBe('auto');
  });

  it('a failure offers Retry; rate limiting says to wait', async () => {
    const t = await render({ q: 'docker' });
    http.expectOne(isSearch).flush({ code: 'rate_limited', status: 429 }, { status: 429, statusText: 'Too Many Requests' });
    await t.stable();
    expect(t.$('[data-search-error]')!.textContent).toContain('طلبات كتير، استنى شوية وجرّب تاني.');
    t.$<HTMLButtonElement>('[data-search-error] button')!.click();
    await answer(t, { items: [TITLE_HIT], nextCursor: null });
    expect(t.$$('[data-search-article]')).toHaveLength(1);
  });

  it('searches 300 ms after typing stops (from 2 characters); Enter searches at once and keeps it in recent searches', async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    const t = await render({ type: 'users' });
    await t.type('m');
    vi.advanceTimersByTime(SEARCH_DEBOUNCE_MS * 2);
    expect(t.navigate).not.toHaveBeenCalled();
    await t.type('mo');
    await t.type('mon');
    vi.advanceTimersByTime(SEARCH_DEBOUNCE_MS - 1);
    expect(t.navigate).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(t.lastParams()).toEqual({ q: 'mon', type: 'users', field: null, lang: null, time: null });

    t.navigate.mockClear();
    await t.type('a');
    t.box().form!.dispatchEvent(new Event('submit', { cancelable: true }));
    expect(t.lastParams()).toMatchObject({ q: 'a', type: 'users' });
    expect(TestBed.inject(RecentSearches).items()).toEqual(['a']);
    // Emptying the box goes back to recent searches at once.
    await t.type('');
    expect(t.lastParams()).toMatchObject({ q: null, type: 'users' });
  });

  it('tabs and filters change the URL (arrows move between tabs)', async () => {
    const t = await render({ q: 'docker' });
    await answer(t, { items: [TITLE_HIT], nextCursor: null });
    t.$<HTMLButtonElement>('[data-search-tab="tags"]')!.click();
    expect(t.lastParams()).toMatchObject({ q: 'docker', type: 'tags' });
    t.$('[data-search-tab="articles"]')!.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowLeft', cancelable: true }));
    // Arabic: the left arrow goes to the next tab.
    expect(t.lastParams()).toMatchObject({ type: 'users' });

    const field = t.$<HTMLSelectElement>('[data-filter="field"]')!;
    expect([...field.options].map((o) => o.textContent!.trim())).toEqual(['كل المجالات', 'البرمجيات']);
    field.value = 'software';
    field.dispatchEvent(new Event('change'));
    expect(t.lastParams()).toMatchObject({ q: 'docker', field: 'software' });
    const time = t.$<HTMLSelectElement>('[data-filter="time"]')!;
    expect([...time.options].map((o) => o.textContent!.trim())).toEqual(['أي مدة', 'لحد 5 دقايق', 'من 5 لـ 10 دقايق', 'أكتر من 10 دقايق']);
    time.value = 'short';
    time.dispatchEvent(new Event('change'));
    expect(t.lastParams()).toMatchObject({ time: 'short' });
  });

  it('with no query: recent searches (open, remove one, clear all), else where to start', async () => {
    localStorage.setItem('readin.recentSearches', JSON.stringify(['kestrel', 'يعني إيه Transformer']));
    const t = await render();
    expect(t.$$('[data-recent]').map((r) => r.getAttribute('data-recent'))).toEqual(['kestrel', 'يعني إيه Transformer']);
    expect(t.$('[data-recent] bdi')!.getAttribute('dir')).toBe('auto');
    expect(t.$('[data-recent-remove]')!.getAttribute('aria-label')).toBe('شيل «⁨kestrel⁩» من آخر حاجات دوّرت عليها');

    t.$$('[data-recent-open]')[1].click();
    expect(t.lastParams()).toMatchObject({ q: 'يعني إيه Transformer' });
    t.$<HTMLButtonElement>('[data-recent-remove]')!.click();
    await t.stable();
    expect(t.$$('[data-recent]').map((r) => r.getAttribute('data-recent'))).toEqual(['يعني إيه Transformer']);
    t.$<HTMLButtonElement>('[data-recent-clear]')!.click();
    await t.stable();
    expect(t.$('[data-recent-searches]')).toBeNull();
    expect(t.$('[data-search-start] h2')!.textContent!.trim()).toBe('عايز تقرا عن إيه؟');
    expect(localStorage.getItem('readin.recentSearches')).toBeNull();
  });
});
