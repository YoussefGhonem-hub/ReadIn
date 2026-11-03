import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CollectionDto } from '../api/models';
import { ArticleSocialStore } from './article-social.store';
import { CollectionsStore } from './collections.store';

const INTERVIEW: CollectionDto = { id: 'c1', name: 'Interview prep', articleCount: 2, createdAt: '2026-10-20T10:00:00Z' };
const WEEKEND: CollectionDto = { id: 'c2', name: 'قراءة الويك إند', articleCount: 1, createdAt: '2026-10-25T10:00:00Z' };

describe('CollectionsStore (F13)', () => {
  let http: HttpTestingController;
  let store: CollectionsStore;
  let social: ArticleSocialStore;

  async function loaded(): Promise<void> {
    const done = store.load();
    http.expectOne(`${TEST_API}/me/collections`).flush([INTERVIEW, WEEKEND]);
    await done;
  }

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
    store = TestBed.inject(CollectionsStore);
    social = TestBed.inject(ArticleSocialStore);
    TestBed.tick();
  });

  afterEach(() => http.verify());

  it('loads once, and again when forced', async () => {
    await loaded();
    expect(store.status()).toBe('loaded');
    await store.load();
    http.expectNone(`${TEST_API}/me/collections`);
    void store.load(true);
    http.expectOne(`${TEST_API}/me/collections`).flush([]);
  });

  it('creates and renames in name order, trimming the name', async () => {
    await loaded();
    const created = store.create('  Algorithms  ');
    const req = http.expectOne(`${TEST_API}/me/collections`);
    expect(req.request.body).toEqual({ name: 'Algorithms' });
    req.flush({ id: 'c3', name: 'Algorithms', articleCount: 0, createdAt: '2026-11-03T08:00:00Z' });
    await created;
    expect(store.collections().map((c) => c.name)).toEqual(['Algorithms', 'Interview prep', 'قراءة الويك إند']);

    const renamed = store.rename('c3', 'Zebra');
    http.expectOne(`${TEST_API}/me/collections/c3`).flush({ id: 'c3', name: 'Zebra', articleCount: 0, createdAt: '2026-11-03T08:00:00Z' });
    await renamed;
    expect(store.collections().map((c) => c.name)).toEqual(['Interview prep', 'Zebra', 'قراءة الويك إند']);
  });

  it('passes create errors on to the form', async () => {
    await loaded();
    const created = store.create('interview PREP');
    http.expectOne(`${TEST_API}/me/collections`).flush(problem(409, 'collection.name_taken'), { status: 409, statusText: 'Conflict' });
    await expect(created).rejects.toMatchObject({ code: 'collection.name_taken' });
    expect(store.collections()).toHaveLength(2);
  });

  it('adds an article at once, counts it and marks it saved', async () => {
    await loaded();
    const article = testCard();
    const done = store.addArticle('c2', article);
    expect(store.collectionsOf('a1')?.has('c2')).toBe(true);
    expect(store.collections().find((c) => c.id === 'c2')!.articleCount).toBe(2);
    http.expectOne(`${TEST_API}/me/collections/c2/articles/a1`).flush(null, { status: 204, statusText: 'No Content' });
    expect(await done).toBe(true);
    expect(social.state(article).isSaved).toBe(true);
    expect(social.state(article).saveCount).toBe(5);
  });

  it('rolls a failed removal back', async () => {
    await loaded();
    store.learn([{ savedAt: '2026-11-01T00:00:00Z', collectionIds: ['c1'], article: testCard() }]);
    const done = store.removeArticle('c1', 'a1');
    expect(store.collectionsOf('a1')?.size).toBe(0);
    expect(store.collections()[0].articleCount).toBe(1);
    http.expectOne(`${TEST_API}/me/collections/c1/articles/a1`).flush(problem(404, 'collection.not_found'), { status: 404, statusText: 'Not Found' });
    expect(await done).toBe(false);
    expect(store.collectionsOf('a1')?.has('c1')).toBe(true);
    expect(store.collections()[0].articleCount).toBe(2);
  });

  it('an unsaved article leaves every collection', async () => {
    await loaded();
    const article = testCard({ isSaved: true });
    store.learn([{ savedAt: '2026-11-01T00:00:00Z', collectionIds: ['c1', 'c2'], article }]);
    void social.toggleSave(article);
    http.expectOne(`${TEST_API}/me/saved/a1`).flush({ isSaved: false, saveCount: 3 });
    await flushMicrotasks();
    expect(store.collectionsOf('a1')?.size).toBe(0);
    expect(store.collections().map((c) => c.articleCount)).toEqual([1, 0]);
  });

  it('deleting a collection keeps the articles but drops the membership', async () => {
    await loaded();
    store.learn([{ savedAt: '2026-11-01T00:00:00Z', collectionIds: ['c1'], article: testCard() }]);
    const done = store.remove('c1');
    http.expectOne(`${TEST_API}/me/collections/c1`).flush(null, { status: 204, statusText: 'No Content' });
    await done;
    expect(store.collections().map((c) => c.id)).toEqual(['c2']);
    expect(store.collectionsOf('a1')?.size).toBe(0);
  });
});
