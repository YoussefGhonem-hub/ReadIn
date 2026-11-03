import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { CollectionDto } from '../../core/api/models';
import { CollectionsStore } from '../../core/social/collections.store';
import { CollectionNameSheet, CollectionPickerSheet, collectionNameProblem } from './collection-sheets';

const COLLECTIONS: CollectionDto[] = [
  { id: 'c1', name: 'Interview prep', articleCount: 2, createdAt: '2026-10-20T10:00:00Z' },
  { id: 'c2', name: 'قراءة الويك إند', articleCount: 0, createdAt: '2026-10-25T10:00:00Z' },
];

describe('collection sheets (F13)', () => {
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting());
  });

  afterEach(() => http.verify());

  it('validates names: 1–60 characters after trimming', () => {
    expect(collectionNameProblem('   ')).toBe('collections.nameRequired');
    expect(collectionNameProblem('x'.repeat(61))).toBe('collections.nameTooLong');
    expect(collectionNameProblem(`  ${'x'.repeat(60)}  `)).toBeNull();
  });

  describe('CollectionPickerSheet', () => {
    async function open() {
      const fixture = TestBed.createComponent(CollectionPickerSheet);
      fixture.componentRef.setInput('article', testCard());
      fixture.componentRef.setInput('open', true);
      fixture.detectChanges();
      http.expectOne(`${TEST_API}/me/collections`).flush(COLLECTIONS);
      const root = fixture.nativeElement as HTMLElement;
      const stable = async () => {
        await flushMicrotasks();
        fixture.detectChanges();
        await fixture.whenStable();
      };
      await stable();
      return { root, stable };
    }

    it('ticks a collection to add the article, and unticks to take it out', async () => {
      TestBed.inject(CollectionsStore).learn([{ savedAt: '2026-11-01T00:00:00Z', collectionIds: ['c1'], article: testCard() }]);
      const { root, stable } = await open();
      const box = (id: string) => root.querySelector<HTMLInputElement>(`[data-collection="${id}"] input`)!;
      expect(box('c1').checked).toBe(true);
      expect(box('c2').checked).toBe(false);

      box('c2').click();
      await stable();
      expect(root.querySelector('[data-collection="c2"]')!.textContent).toContain('مقال واحد');
      http.expectOne(`${TEST_API}/me/collections/c2/articles/a1`).flush(null, { status: 204, statusText: 'No Content' });
      await stable();

      box('c1').click();
      const remove = http.expectOne(`${TEST_API}/me/collections/c1/articles/a1`);
      expect(remove.request.method).toBe('DELETE');
      remove.flush(null, { status: 204, statusText: 'No Content' });
      await stable();
      expect(box('c1').checked).toBe(false);
    });

    it('creates a collection and puts the article in it', async () => {
      const { root, stable } = await open();
      (root.querySelector('[data-new-collection]') as HTMLElement).click();
      await stable();
      const input = root.querySelector<HTMLInputElement>('#new-collection-name')!;
      (root.querySelector('[data-create-collection]') as HTMLElement).click();
      await stable();
      expect(root.querySelector('#new-collection-error')!.textContent).toBe('اكتب اسم للمجموعة.');

      input.value = 'Algorithms';
      input.dispatchEvent(new Event('input'));
      (root.querySelector('[data-create-collection]') as HTMLElement).click();
      http.expectOne(`${TEST_API}/me/collections`).flush({ id: 'c3', name: 'Algorithms', articleCount: 0, createdAt: '2026-11-03T08:00:00Z' });
      await stable();
      http.expectOne(`${TEST_API}/me/collections/c3/articles/a1`).flush(null, { status: 204, statusText: 'No Content' });
      await stable();
      expect(root.querySelector<HTMLInputElement>('[data-collection="c3"] input')!.checked).toBe(true);
    });
  });

  describe('CollectionNameSheet', () => {
    it('shows the API error under the field', async () => {
      const fixture = TestBed.createComponent(CollectionNameSheet);
      fixture.componentRef.setInput('open', true);
      fixture.detectChanges();
      const root = fixture.nativeElement as HTMLElement;
      const input = root.querySelector<HTMLInputElement>('#collection-name')!;
      input.value = 'Interview Prep';
      input.dispatchEvent(new Event('input'));
      (root.querySelector('[data-submit]') as HTMLElement).click();
      http.expectOne(`${TEST_API}/me/collections`).flush(problem(409, 'collection.name_taken'), { status: 409, statusText: 'Conflict' });
      await flushMicrotasks();
      fixture.detectChanges();
      expect(root.querySelector('#collection-name-error')!.textContent).toBe('عندك مجموعة بنفس الاسم.');
      expect(input.getAttribute('aria-invalid')).toBe('true');
    });

    it("shows the API's generic validation codes on the name as the collection-name messages", async () => {
      const fixture = TestBed.createComponent(CollectionNameSheet);
      fixture.componentRef.setInput('open', true);
      fixture.detectChanges();
      const root = fixture.nativeElement as HTMLElement;
      const input = root.querySelector<HTMLInputElement>('#collection-name')!;
      input.value = 'Interview prep';
      input.dispatchEvent(new Event('input'));
      (root.querySelector('[data-submit]') as HTMLElement).click();
      http
        .expectOne(`${TEST_API}/me/collections`)
        .flush(problem(400, 'validation.failed', { name: ['validation.max_length'] }), { status: 400, statusText: 'Bad Request' });
      await flushMicrotasks();
      fixture.detectChanges();
      expect(root.querySelector('#collection-name-error')!.textContent).toBe('اسم المجموعة 60 حرف بالكتير.');

      input.value = 'Interview prep 2';
      input.dispatchEvent(new Event('input'));
      (root.querySelector('[data-submit]') as HTMLElement).click();
      http
        .expectOne(`${TEST_API}/me/collections`)
        .flush(problem(400, 'validation.failed', { name: ['validation.required'] }), { status: 400, statusText: 'Bad Request' });
      await flushMicrotasks();
      fixture.detectChanges();
      expect(root.querySelector('#collection-name-error')!.textContent).toBe('اكتب اسم للمجموعة.');
    });

    it('renames with the new name', async () => {
      const fixture = TestBed.createComponent(CollectionNameSheet);
      const done: CollectionDto[] = [];
      fixture.componentInstance.done.subscribe((c) => done.push(c));
      fixture.componentRef.setInput('collection', COLLECTIONS[0]);
      fixture.componentRef.setInput('open', true);
      fixture.detectChanges();
      await fixture.whenStable();
      const root = fixture.nativeElement as HTMLElement;
      const input = root.querySelector<HTMLInputElement>('#collection-name')!;
      expect(input.value).toBe('Interview prep');
      input.value = 'Interviews';
      input.dispatchEvent(new Event('input'));
      (root.querySelector('[data-submit]') as HTMLElement).click();
      const req = http.expectOne(`${TEST_API}/me/collections/c1`);
      expect(req.request.method).toBe('PATCH');
      expect(req.request.body).toEqual({ name: 'Interviews' });
      req.flush({ ...COLLECTIONS[0], name: 'Interviews' });
      await flushMicrotasks();
      expect(done.map((c) => c.name)).toEqual(['Interviews']);
    });
  });
});
