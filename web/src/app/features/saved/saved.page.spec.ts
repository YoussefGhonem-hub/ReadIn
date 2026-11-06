import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CollectionDto, FieldDto, SavedArticleDto } from '../../core/api/models';
import { SEARCH_DEBOUNCE_MS, SavedPage } from './saved.page';

const FIELDS: FieldDto[] = [
  { id: 'f1', slug: 'software', name: 'Software', nameAr: 'البرمجيات', nameEn: 'Software', icon: 'code', color: 'primary', isSensitive: false, requiresSources: false, topicCount: 0 },
  { id: 'f2', slug: 'medicine', name: 'Medicine', nameAr: 'الطب', nameEn: 'Medicine', icon: 'stethoscope', color: 'primary', isSensitive: true, requiresSources: true, topicCount: 0 },
];
const COLLECTIONS: CollectionDto[] = [{ id: 'c1', name: 'Interview prep', articleCount: 1, createdAt: '2026-10-20T10:00:00Z' }];

function saved(id: string, title: string, collectionIds: string[] = []): SavedArticleDto {
  return { savedAt: '2026-11-02T08:00:00Z', collectionIds, article: testCard({ id, slug: id, title, isSaved: true, saveCount: 5 }) };
}

const isList = (r: { url: string }) => r.url === `${TEST_API}/me/saved`;

describe('SavedPage (F13)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
  });

  afterEach(() => {
    vi.useRealTimers();
    http.verify();
  });

  async function render(items: SavedArticleDto[] = [saved('a1', 'Clean Architecture', ['c1']), saved('a2', 'Sleep and memory')]) {
    const fixture = TestBed.createComponent(SavedPage);
    fixture.detectChanges();
    http.expectOne(`${TEST_API}/fields`).flush(FIELDS);
    http.expectOne(`${TEST_API}/me/collections`).flush(COLLECTIONS);
    http.expectOne(isList).flush({ items, nextCursor: null });
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    await stable();
    return { fixture, root, stable, titles: () => [...root.querySelectorAll('[data-saved-item] h3')].map((h) => h.textContent!.trim()) };
  }

  it('lists saved articles with chips for collections and fields', async () => {
    const { root, titles } = await render();
    expect(titles()).toEqual(['Clean Architecture', 'Sleep and memory']);
    expect(root.querySelector('[data-collection-chip="c1"]')!.textContent).toContain('Interview prep');
    expect(root.querySelector('[data-field-chip="medicine"]')).not.toBeNull();
    // The article in a collection shows how many.
    expect(root.querySelector('[data-saved-item] [data-item-collections] .rd-tag')!.textContent).toBe('1');
  });

  it('searches after a pause in typing, not on every key', async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    const { root, stable } = await render();
    const input = root.querySelector<HTMLInputElement>('[data-saved-search]')!;
    for (const value of ['s', 'sl', 'sle']) {
      input.value = value;
      input.dispatchEvent(new Event('input'));
    }
    vi.advanceTimersByTime(SEARCH_DEBOUNCE_MS - 1);
    http.expectNone(isList);
    vi.advanceTimersByTime(1);
    const req: TestRequest = http.expectOne(isList);
    expect(req.request.params.get('q')).toBe('sle');
    req.flush({ items: [], nextCursor: null });
    await stable();
    expect(root.querySelector('[data-saved-no-results]')).not.toBeNull();

    (root.querySelector('[data-saved-no-results] button') as HTMLElement).click();
    http.expectOne((r) => isList(r) && !r.params.has('q')).flush({ items: [saved('a1', 'Clean Architecture')], nextCursor: null });
  });

  it('filters by field and by collection, with rename and delete for the open collection', async () => {
    const { root, stable } = await render();
    (root.querySelector('[data-field-chip="medicine"]') as HTMLElement).click();
    const byField = http.expectOne(isList);
    expect(byField.request.params.get('field')).toBe('medicine');
    byField.flush({ items: [saved('a2', 'Sleep and memory')], nextCursor: null });
    await stable();

    (root.querySelector('[data-collection-chip="c1"]') as HTMLElement).click();
    const byCollection = http.expectOne(isList);
    expect(byCollection.request.params.get('collection')).toBe('c1');
    expect(byCollection.request.params.get('field')).toBe('medicine');
    byCollection.flush({ items: [], nextCursor: null });
    await stable();
    expect(root.querySelector('[data-collection-header]')!.textContent).toContain('Interview prep');
    expect(root.querySelector('[data-rename-collection]')).not.toBeNull();
    expect(root.querySelector('[data-delete-collection]')).not.toBeNull();
  });

  it('an unsaved article leaves the list at once and comes back if that fails', async () => {
    const { root, stable, titles } = await render();
    (root.querySelector('[data-saved-item] [data-card-save]') as HTMLElement).click();
    await stable();
    expect(titles()).toEqual(['Sleep and memory']);
    http.expectOne(`${TEST_API}/me/saved/a1`).flush(null, { status: 500, statusText: 'Error' });
    await stable();
    expect(titles()).toEqual(['Clean Architecture', 'Sleep and memory']);
  });

  it('an empty list invites you to save something', async () => {
    const { root } = await render([]);
    expect(root.querySelector('[data-saved-empty]')!.textContent).toContain('لم تحفظ شيئًا بعد');
  });
});
