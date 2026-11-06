import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Router } from '@angular/router';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { SearchSuggestionsDto } from '../../core/api/models';
import { HeaderSearch } from './header-search';
import { RecentSearches } from './recent-searches';
import { SEARCH_DEBOUNCE_MS } from './search-query';

const isSuggest = (r: { url: string }) => r.url === `${TEST_API}/search/suggest`;
const SUGGESTIONS: SearchSuggestionsDto = {
  articles: [{ article: testCard({ id: 'a1', slug: 'cheat-sheet', title: 'ASP.NET Core cheat sheet', language: 'en' }), matchedIn: 'attachment' }],
  users: [{ id: 'u-mona', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: true, bio: null, isFollowing: false, followsYou: false }],
  topics: [
    {
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
      articleCount: 3,
    },
  ],
  tags: [{ slug: 'csharp', name: 'C#', articleCount: 23 }],
};

describe('HeaderSearch (F16)', () => {
  let http: HttpTestingController;

  afterEach(() => {
    vi.useRealTimers();
    http?.verify();
    localStorage.removeItem('readin.recentSearches');
  });

  async function render(recent: string[] = []) {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ guest: true }));
    for (const q of [...recent].reverse()) TestBed.inject(RecentSearches).add(q);
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    const fixture = TestBed.createComponent(HeaderSearch);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    await stable();
    const input = () => root.querySelector<HTMLInputElement>('[data-header-search-input]')!;
    const options = () => [...root.querySelectorAll<HTMLElement>('[role="option"]')];
    const type = async (value: string) => {
      input().value = value;
      input().dispatchEvent(new Event('input'));
      await stable();
    };
    const key = async (name: string) => {
      input().dispatchEvent(new KeyboardEvent('keydown', { key: name, cancelable: true }));
      await stable();
    };
    const focus = async () => {
      input().dispatchEvent(new Event('focus'));
      await stable();
    };
    return { fixture, root, input, options, type, key, focus, stable, navigate };
  }

  it('focused and empty, it lists your recent searches; Delete removes the chosen one, a pick opens the search page', async () => {
    const t = await render(['kestrel', 'mona']);
    expect(t.root.querySelector('[data-header-search-popup]')).toBeNull();
    await t.focus();
    expect(t.input().getAttribute('aria-expanded')).toBe('true');
    expect(t.options().map((o) => o.getAttribute('data-option'))).toEqual(['recent', 'recent']);
    expect(t.root.querySelector('[role="listbox"]')!.getAttribute('aria-label')).toBe('عمليات البحث الأخيرة');

    await t.key('ArrowDown');
    await t.key('ArrowDown');
    expect(t.input().getAttribute('aria-activedescendant')).toBe('header-search-list-1');
    await t.key('Delete');
    expect(TestBed.inject(RecentSearches).items()).toEqual(['kestrel']);
    expect(t.options()).toHaveLength(1);

    await t.key('Enter');
    expect(t.navigate).toHaveBeenCalledWith(['/search'], { queryParams: { q: 'kestrel' } });
  });

  it('as you type: suggestions 300 ms after the last key, by type, then "See all results"; the keyboard opens one', async () => {
    const t = await render();
    await t.focus();
    await t.type('m');
    // One character: only "See all results", and no lookup.
    expect(t.options().map((o) => o.getAttribute('data-option'))).toEqual(['all']);
    await t.type('mo');
    await t.type('mon');
    vi.advanceTimersByTime(SEARCH_DEBOUNCE_MS - 1);
    http.expectNone(isSuggest);
    expect(t.root.querySelector('[data-header-search-status]')!.textContent!.trim()).toBe('جارٍ البحث…');
    vi.advanceTimersByTime(1);
    const req = http.expectOne(isSuggest);
    expect(req.request.params.get('q')).toBe('mon');
    req.flush(SUGGESTIONS);
    await t.stable();

    expect([...t.root.querySelectorAll('[data-group]')].map((g) => g.getAttribute('data-group'))).toEqual(['articles', 'users', 'topics', 'tags']);
    expect(t.options().map((o) => o.getAttribute('data-option'))).toEqual(['article', 'user', 'topic', 'tag', 'all']);
    expect(t.options()[0].textContent).toContain('وُجدت في ملف PDF المرفق');
    expect(t.options()[4].textContent!.trim()).toBe('عرض كل نتائج «⁨mon⁩»');

    await t.key('ArrowDown');
    await t.key('ArrowDown');
    await t.key('Enter');
    expect(t.navigate).toHaveBeenCalledWith(['/@mona'], { queryParams: {} });
    expect(TestBed.inject(RecentSearches).items()).toEqual(['mon']);
    expect(t.input().value).toBe('');
  });

  it('opens a topic on its field page, a tag on its page and an article in the reader', async () => {
    const t = await render();
    await t.focus();
    await t.type('net');
    vi.advanceTimersByTime(SEARCH_DEBOUNCE_MS);
    http.expectOne(isSuggest).flush(SUGGESTIONS);
    await t.stable();
    t.options()[2].click();
    expect(t.navigate).toHaveBeenLastCalledWith(['/f', 'software'], { queryParams: { topic: 'dotnet' } });

    await t.focus();
    await t.type('c#');
    vi.advanceTimersByTime(SEARCH_DEBOUNCE_MS);
    http.expectOne(isSuggest).flush(SUGGESTIONS);
    await t.stable();
    t.options()[3].click();
    expect(t.navigate).toHaveBeenLastCalledWith(['/tags', 'csharp'], { queryParams: {} });

    await t.focus();
    await t.type('cheat');
    vi.advanceTimersByTime(SEARCH_DEBOUNCE_MS);
    http.expectOne(isSuggest).flush(SUGGESTIONS);
    await t.stable();
    t.options()[0].click();
    expect(t.navigate).toHaveBeenLastCalledWith(['/', 'en', 'a', 'cheat-sheet'], { queryParams: {} });
  });

  it('Enter without a pick searches what is typed (from 1 character); failed suggestions still leave "See all"', async () => {
    const t = await render();
    await t.focus();
    await t.type('dock');
    vi.advanceTimersByTime(SEARCH_DEBOUNCE_MS);
    http.expectOne(isSuggest).flush({ code: 'rate_limited' }, { status: 429, statusText: 'Too Many Requests' });
    await t.stable();
    expect(t.root.querySelector('[data-header-search-status]')!.textContent!.trim()).toBe('لا توجد اقتراحات بعد');
    expect(t.options().map((o) => o.getAttribute('data-option'))).toEqual(['all']);
    await t.key('Enter');
    expect(t.navigate).toHaveBeenCalledWith(['/search'], { queryParams: { q: 'dock' } });

    await t.focus();
    await t.type('x');
    await t.key('Enter');
    expect(t.navigate).toHaveBeenLastCalledWith(['/search'], { queryParams: { q: 'x' } });
  });

  it('Escape closes the list, then empties the box; the ✕ empties it too', async () => {
    const t = await render(['kestrel']);
    await t.focus();
    await t.type('abc');
    expect(t.root.querySelector('[data-header-search-popup]')).not.toBeNull();
    await t.key('Escape');
    expect(t.root.querySelector('[data-header-search-popup]')).toBeNull();
    await t.key('Escape');
    expect(t.input().value).toBe('');

    await t.type('abc');
    t.root.querySelector<HTMLButtonElement>('[data-header-search-clear]')!.click();
    await t.stable();
    expect(t.input().value).toBe('');
    expect(t.options().map((o) => o.getAttribute('data-option'))).toEqual(['recent']);
  });
});
