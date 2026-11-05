import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CursorPage, SearchArticleDto, UserSummaryDto } from '../../core/api/models';
import { SearchRequest } from './search-query';
import { SearchStore } from './search.store';

const request = (patch: Partial<SearchRequest> = {}): SearchRequest => ({ q: 'docker', type: 'articles', field: null, lang: null, time: null, ...patch });
const hit = (n: number, matchedIn: SearchArticleDto['matchedIn'] = 'title'): SearchArticleDto => ({
  article: testCard({ id: `a${n}`, slug: `docker-${n}`, title: `Docker ${n}` }),
  matchedIn,
});
const person = (n: number): UserSummaryDto => ({
  id: `u${n}`,
  displayName: `Person ${n}`,
  username: `person${n}`,
  avatarUrl: null,
  isVerified: false,
  bio: null,
  isFollowing: false,
  followsYou: false,
});
const isSearch = (r: { url: string }) => r.url === `${TEST_API}/search`;

describe('SearchStore (F16)', () => {
  let http: HttpTestingController;
  let store: SearchStore;

  function setup(platform: 'browser' | 'server' = 'browser') {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ guest: true, providers: [SearchStore, { provide: PLATFORM_ID, useValue: platform }] }));
    store = TestBed.inject(SearchStore);
  }

  beforeEach(() => setup());
  afterEach(() => http.verify());

  async function answer<T>(req: TestRequest, body: CursorPage<T>) {
    req.flush(body);
    await flushMicrotasks();
  }

  it('searches the tab with the filters as minute ranges, then pages with the cursor and drops repeats', async () => {
    store.open(request({ field: 'software', lang: 'ar-EG', time: 'medium' }));
    expect(store.status()).toBe('loading');
    const first = http.expectOne(isSearch);
    expect(first.request.params.keys().sort()).toEqual(['field', 'lang', 'limit', 'maxMinutes', 'minMinutes', 'q', 'type']);
    expect(first.request.params.get('q')).toBe('docker');
    expect(first.request.params.get('type')).toBe('articles');
    expect(first.request.params.get('minMinutes')).toBe('6');
    expect(first.request.params.get('maxMinutes')).toBe('10');
    expect(first.request.params.get('limit')).toBe('20');
    await answer(first, { items: [hit(1), hit(2, 'attachment')], nextCursor: 'c2' });
    expect(store.status()).toBe('loaded');
    expect(store.articles().map((r) => r.matchedIn)).toEqual(['title', 'attachment']);
    expect(store.hasFilters()).toBe(true);

    const more = store.loadMore();
    const second = http.expectOne(isSearch);
    expect(second.request.params.get('cursor')).toBe('c2');
    await answer(second, { items: [hit(2), hit(3)], nextCursor: null });
    await more;
    expect(store.articles().map((r) => r.article.id)).toEqual(['a1', 'a2', 'a3']);
    expect(store.nextCursor()).toBeNull();
  });

  it('another tab sends no filters; the same search again asks nothing', async () => {
    store.open(request({ type: 'users', lang: 'en', time: 'long' }));
    const req = http.expectOne(isSearch);
    expect(req.request.params.get('type')).toBe('users');
    expect(req.request.params.has('lang')).toBe(false);
    expect(req.request.params.has('minMinutes')).toBe(false);
    await answer(req, { items: [person(1)], nextCursor: null });
    expect(store.users().map((u) => u.username)).toEqual(['person1']);
    expect(store.articles()).toEqual([]);
    expect(store.hasFilters()).toBe(false);

    store.open(request({ type: 'users', lang: null }));
    http.expectNone(isSearch);
  });

  it('a newer search wins over an older answer', async () => {
    store.open(request({ q: 'dock' }));
    const old = http.expectOne(isSearch);
    store.open(request({ q: 'docker' }));
    const fresh = http.expectOne(isSearch);
    await answer(fresh, { items: [hit(1)], nextCursor: null });
    await answer(old, { items: [hit(9)], nextCursor: null });
    expect(store.request()?.q).toBe('docker');
    expect(store.articles().map((r) => r.article.id)).toEqual(['a1']);
  });

  it('no query is idle; nothing to search for is invalid without asking; the API saying so is too', async () => {
    store.open(null);
    expect(store.status()).toBe('idle');
    store.open(request({ q: '!!' }));
    expect(store.status()).toBe('invalid');
    http.expectNone(isSearch);

    store.open(request({ q: 'x' }));
    http.expectOne(isSearch).flush(problem(400, 'search.query_invalid'), { status: 400, statusText: 'Bad Request' });
    await flushMicrotasks();
    expect(store.status()).toBe('invalid');
  });

  it('a failure shows the error, and Retry asks again; the same search after an error asks again too', async () => {
    store.open(request());
    http.expectOne(isSearch).flush(problem(429, 'rate_limited'), { status: 429, statusText: 'Too Many Requests' });
    await flushMicrotasks();
    expect(store.status()).toBe('error');
    void store.load();
    await answer(http.expectOne(isSearch), { items: [hit(1)], nextCursor: null });
    expect(store.status()).toBe('loaded');

    store.open(request({ q: 'kafka' }));
    http.expectOne(isSearch).flush(null, { status: 500, statusText: 'Error' });
    await flushMicrotasks();
    store.open(request({ q: 'kafka' }));
    await answer(http.expectOne(isSearch), { items: [], nextCursor: null });
    expect(store.status()).toBe('loaded');
    expect(store.count()).toBe(0);
  });

  it('a failed next page offers Retry and keeps the list', async () => {
    store.open(request());
    await answer(http.expectOne(isSearch), { items: [hit(1)], nextCursor: 'c2' });
    const more = store.loadMore();
    http.expectOne(isSearch).flush(null, { status: 500, statusText: 'Error' });
    await more;
    expect(store.loadMoreFailed()).toBe(true);
    expect(store.count()).toBe(1);
  });

  it('refreshes the first page in place (you signed in or out)', async () => {
    store.open(request());
    await answer(http.expectOne(isSearch), { items: [hit(1)], nextCursor: null });
    const refresh = store.refresh();
    expect(store.status()).toBe('loaded');
    await answer(http.expectOne(isSearch), { items: [hit(1), hit(2)], nextCursor: null });
    await refresh;
    expect(store.count()).toBe(2);
  });

  it('never searches on the server: it renders the skeleton', () => {
    setup('server');
    store.open(request());
    expect(store.status()).toBe('loading');
    http.expectNone(isSearch);
  });
});
