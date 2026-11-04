import { TestBed } from '@angular/core/testing';
import { Observable, Subject, of, throwError } from 'rxjs';
import { ApiError } from '../../core/api/api.config';
import { ArticlesApi, MyArticlesQuery } from '../../core/api/articles.api';
import { CursorPage, MyArticleDto } from '../../core/api/models';
import { MyArticlesStore } from './my-articles.store';

function mine(id: string, patch: Partial<MyArticleDto> = {}): MyArticleDto {
  return {
    id,
    status: 'draft',
    slug: null,
    language: 'ar-EG',
    title: `Article ${id}`,
    coverUrl: null,
    field: null,
    readingTimeMinutes: 3,
    savedAt: '2026-11-03T10:00:00Z',
    publishedAt: null,
    hasUnpublishedChanges: false,
    reactionCount: 0,
    commentCount: 0,
    readCount: 0,
    ...patch,
  };
}

describe('MyArticlesStore (My articles: Drafts / Published)', () => {
  let store: MyArticlesStore;
  let pages: Record<string, CursorPage<MyArticleDto>>;
  let api: { mine: ReturnType<typeof vi.fn>; delete: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    pages = {
      'draft|': { items: [mine('d1'), mine('d2', { title: '' })], nextCursor: 'c2' },
      'draft|c2': { items: [mine('d2'), mine('d3')], nextCursor: null },
      'published|': { items: [mine('p1', { status: 'published', slug: 'p-1', hasUnpublishedChanges: true })], nextCursor: null },
    };
    api = {
      mine: vi.fn((q: MyArticlesQuery): Observable<CursorPage<MyArticleDto>> => of(pages[`${q.status}|${q.cursor ?? ''}`])),
      delete: vi.fn(() => of(undefined)),
    };
    TestBed.configureTestingModule({ providers: [MyArticlesStore, { provide: ArticlesApi, useValue: api }] });
    store = TestBed.inject(MyArticlesStore);
  });

  it('loads each tab the first time it is shown, with GET /me/articles?status=', async () => {
    store.select('draft');
    await Promise.resolve();
    expect(api.mine).toHaveBeenCalledWith({ status: 'draft', limit: 20 });
    expect(store.status()).toBe('loaded');
    expect(store.items().map((a) => a.id)).toEqual(['d1', 'd2']);

    store.select('published');
    await Promise.resolve();
    expect(api.mine).toHaveBeenLastCalledWith({ status: 'published', limit: 20 });
    expect(store.items().map((a) => [a.id, a.hasUnpublishedChanges])).toEqual([['p1', true]]);

    store.select('draft'); // already loaded: no new request
    expect(api.mine).toHaveBeenCalledTimes(2);
    expect(store.items().map((a) => a.id)).toEqual(['d1', 'd2']);
  });

  it('loads more with the cursor and skips rows it already has', async () => {
    store.select('draft');
    await Promise.resolve();
    expect(store.hasMore()).toBe(true);
    await store.loadMore();
    expect(api.mine).toHaveBeenLastCalledWith({ status: 'draft', cursor: 'c2', limit: 20 });
    expect(store.items().map((a) => a.id)).toEqual(['d1', 'd2', 'd3']);
    expect(store.hasMore()).toBe(false);
    await store.loadMore();
    expect(api.mine).toHaveBeenCalledTimes(2);
  });

  it('shows an error state and loads again on retry', async () => {
    api.mine.mockReturnValueOnce(throwError(() => new ApiError(0, 'network', null)));
    store.select('draft');
    await Promise.resolve();
    expect(store.status()).toBe('error');
    await store.load();
    expect(store.status()).toBe('loaded');
  });

  it('drops a response for a list that was reloaded meanwhile', async () => {
    const slow = new Subject<CursorPage<MyArticleDto>>();
    api.mine.mockReturnValueOnce(slow);
    store.select('draft');
    const fresh = store.load();
    await fresh;
    slow.next({ items: [mine('stale')], nextCursor: null });
    slow.complete();
    await Promise.resolve();
    expect(store.items().map((a) => a.id)).toEqual(['d1', 'd2']);
  });

  it('deletes a row at once and puts it back when the request fails', async () => {
    store.select('draft');
    await Promise.resolve();
    const failing = new Subject<void>();
    api.delete.mockReturnValueOnce(failing);
    const result = store.delete(store.items()[0]);
    expect(store.items().map((a) => a.id)).toEqual(['d2']);
    expect(store.deleting()).toBe('d1');
    failing.error(new ApiError(500, 'server.error', null));
    expect(await result).toBe('server.error');
    expect(store.items().map((a) => a.id)).toEqual(['d1', 'd2']);
    expect(store.deleting()).toBeNull();

    expect(await store.delete(store.items()[1])).toBeNull();
    expect(api.delete).toHaveBeenLastCalledWith('d2');
    expect(store.items().map((a) => a.id)).toEqual(['d1']);
  });

  it('treats an article that is already gone as deleted', async () => {
    store.select('published');
    await Promise.resolve();
    api.delete.mockReturnValueOnce(throwError(() => new ApiError(404, 'article.not_found', null)));
    expect(await store.delete(store.items()[0])).toBeNull();
    expect(store.items()).toEqual([]);
  });
});
