import { Type } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { WriterCategoryDto, WriterCategoryListDto } from '../../core/api/models';
import { ManageCategories, ProfileCategories } from './profile-categories';

const MINE = `${TEST_API}/me/categories`;
const category = (id: string, name: string, articleCount: number, sortOrder: number, slug = id): WriterCategoryDto => ({ id, slug, name, articleCount, sortOrder });
const LIST: WriterCategoryListDto = {
  items: [category('c1', 'ASP.NET Core', 3, 1, 'asp-net-core'), category('c2', 'Clean Code بالعربي', 0, 2, 'clean-code'), category('c3', 'أفكار جاية', 1, 3, 'ideas')],
  uncategorizedCount: 2,
};

describe('Writer categories on the profile (F31)', () => {
  let http: HttpTestingController;

  afterEach(() => http.verify());

  async function mount<T>(component: Type<T>) {
    TestBed.resetTestingModule();
    const t = setupSocialTesting();
    http = t.http;
    const fixture = TestBed.createComponent(component);
    fixture.componentRef.setInput('username', 'mona');
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    const $ = <E extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<E>(selector);
    const $$ = (selector: string) => [...root.querySelectorAll<HTMLElement>(selector)];
    return { fixture, root, stable, $, $$, toasts: t.toasts };
  }

  const type = (input: HTMLInputElement, value: string) => {
    input.value = value;
    input.dispatchEvent(new Event('input'));
  };

  describe('the public tab', () => {
    it('one card per category with its count, in order, then "مقالات تانية"; the names keep their direction', async () => {
      const t = await mount(ProfileCategories);
      http.expectOne(`${TEST_API}/users/mona/categories`).flush({ items: [LIST.items[0], LIST.items[2]], uncategorizedCount: 2 });
      await t.stable();
      const cards = t.$$('[data-category-card]');
      expect(cards.map((c) => c.getAttribute('data-category-card'))).toEqual(['asp-net-core', 'ideas', '_other']);
      expect(cards.map((c) => c.getAttribute('href'))).toEqual(['/@mona/c/asp-net-core', '/@mona/c/ideas', '/@mona/c/_other']);
      expect(cards[0].querySelector('[data-category-card-name]')!.getAttribute('dir')).toBe('auto');
      expect(cards[0].querySelector('[data-category-card-count]')!.textContent!.trim()).toBe('3 مقالات');
      expect(cards[2].querySelector('[data-category-card-name]')!.textContent!.trim()).toBe('مقالات تانية');
      expect(cards[2].querySelector('[data-category-card-count]')!.textContent!.trim()).toBe('مقالين');
    });

    it('nothing to show is an empty state; a failure offers Retry', async () => {
      const t = await mount(ProfileCategories);
      http.expectOne(`${TEST_API}/users/mona/categories`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
      await t.stable();
      t.$<HTMLButtonElement>('rd-error-state button')!.click();
      http.expectOne(`${TEST_API}/users/mona/categories`).flush({ items: [], uncategorizedCount: 0 });
      await t.stable();
      expect(t.$('[data-categories-empty]')!.textContent).toContain('لسه مفيش أقسام');
    });

    it('no category but articles: the empty state, without "مقالات تانية" alone (as on mobile)', async () => {
      const t = await mount(ProfileCategories);
      http.expectOne(`${TEST_API}/users/mona/categories`).flush({ items: [], uncategorizedCount: 4 });
      await t.stable();
      expect(t.$$('[data-category-card]')).toHaveLength(0);
      expect(t.$('[data-categories-empty]')!.textContent).toContain('لما الكاتب ده يرتّب مقالاته في أقسام، هتلاقيها هنا.');
    });
  });

  describe('your own tab (manage)', () => {
    async function manage(list: WriterCategoryListDto = LIST) {
      const t = await mount(ManageCategories);
      http.expectOne(MINE).flush(list);
      await t.stable();
      const names = () => t.$$('[data-category-row] [data-category-name]').map((n) => n.textContent!.trim());
      return { ...t, names };
    }

    it('lists every category, empty ones too, with "مقالات تانية" last', async () => {
      const t = await manage();
      expect(t.names()).toEqual(['ASP.NET Core', 'Clean Code بالعربي', 'أفكار جاية']);
      // An empty one says visitors don't see it, instead of "0 articles".
      expect(t.$$('[data-category-row] [data-category-count]').map((n) => n.textContent!.trim())).toEqual(['3 مقالات', 'فاضي، والزوار مش شايفينه', 'مقال واحد']);
      expect(t.$$('[data-category-row] [data-category-empty]')).toHaveLength(1);
      expect(t.$('[data-category-row="c2"] [data-category-empty]')).not.toBeNull();
      expect(t.$('[data-categories-hint]')!.textContent!.trim()).toBe('رتّب مقالاتك في أقسام. بروفايلك هيعرضها بالترتيب ده.');
      expect(t.$('[data-category-card="_other"]')).not.toBeNull();
      // The first can't move up, the last can't move down.
      const rows = t.$$('[data-category-row]');
      expect(rows[0].querySelector<HTMLButtonElement>('[data-move="up"]')!.disabled).toBe(true);
      expect(rows[2].querySelector<HTMLButtonElement>('[data-move="down"]')!.disabled).toBe(true);
      expect(rows[0].querySelector('[data-move="down"]')!.getAttribute('aria-label')).toBe('نزّل «⁨ASP.NET Core⁩» لتحت');
    });

    it('no category yet: the "رتّب مقالاتك" empty view holds the create field; "مقالات تانية" waits for a category', async () => {
      const t = await manage({ items: [], uncategorizedCount: 3 });
      const empty = t.$('[data-categories-empty]')!;
      expect(empty.textContent).toContain('رتّب مقالاتك');
      expect(empty.textContent).toContain('اعمل أقسام زي «نصايح Backend»، وبعدين حط مقالاتك فيها من المحرر. القرّاء هيشوفوها في بروفايلك.');
      expect(t.$('[data-category-card="_other"]')).toBeNull();
      expect(t.$('[data-categories-hint]')).toBeNull();

      const input = empty.querySelector<HTMLInputElement>('[data-category-create] [data-category-name-input]')!;
      type(input, 'Docker');
      await t.stable();
      empty.querySelector<HTMLButtonElement>('[data-category-create] [data-category-name-submit]')!.click();
      http.expectOne((r) => r.method === 'POST' && r.url === MINE).flush(category('c1', 'Docker', 0, 1, 'docker'));
      await t.stable();
      expect(t.$('[data-categories-empty]')).toBeNull();
      expect(t.names()).toEqual(['Docker']);
      expect(t.$('[data-category-card="_other"] [data-category-card-count]')!.textContent!.trim()).toBe('3 مقالات');
      // The create field is back above the list, empty.
      expect(t.$<HTMLInputElement>('[data-category-create] [data-category-name-input]')!.value).toBe('');
    });

    it('create: the name is checked as you type (a name you have, too long), then sent cleaned', async () => {
      const t = await manage();
      const input = t.$<HTMLInputElement>('[data-category-create] [data-category-name-input]')!;
      const submit = t.$<HTMLButtonElement>('[data-category-create] [data-category-name-submit]')!;
      expect(input.getAttribute('dir')).toBe('auto');
      expect(submit.disabled).toBe(true);

      type(input, '  asp.net CORE ');
      await t.stable();
      expect(t.$('[data-category-create] [data-category-name-error]')!.textContent!.trim()).toBe('عندك قسم بنفس الاسم بالفعل.');
      expect(submit.disabled).toBe(true);

      type(input, 'x'.repeat(41));
      await t.stable();
      expect(t.$('[data-category-create] [data-category-name-error]')!.textContent!.trim()).toBe('اسم القسم أقصاه 40 حرف.');

      type(input, '  Docker   🐳 ');
      await t.stable();
      expect(submit.disabled).toBe(false);
      submit.click();
      const req = http.expectOne((r) => r.method === 'POST' && r.url === MINE);
      expect(req.request.body).toEqual({ name: 'Docker 🐳' });
      req.flush(category('c4', 'Docker 🐳', 0, 4, 'docker'));
      await t.stable();
      expect(t.names()).toEqual(['ASP.NET Core', 'Clean Code بالعربي', 'أفكار جاية', 'Docker 🐳']);
      expect(input.value).toBe('');
    });

    it('create: a refused name shows the server\'s reason until it changes', async () => {
      const t = await manage();
      const input = t.$<HTMLInputElement>('[data-category-create] [data-category-name-input]')!;
      type(input, 'Testing');
      await t.stable();
      t.$<HTMLButtonElement>('[data-category-create] [data-category-name-submit]')!.click();
      http.expectOne(MINE).flush(problem(400, 'category.limit'), { status: 400, statusText: 'Bad Request' });
      await t.stable();
      expect(t.$('[data-category-create] [data-category-name-error]')!.textContent!.trim()).toBe('وصلت لأقصى عدد أقسام (50).');
      type(input, 'Testing 2');
      await t.stable();
      expect(t.$('[data-category-create] [data-category-name-error]')!.textContent!.trim()).toBe('');
    });

    it('at 50 categories there is no create field, only the reason', async () => {
      const items = Array.from({ length: 50 }, (_, i) => category(`c${i}`, `Category ${i}`, 0, i + 1));
      const t = await manage({ items, uncategorizedCount: 0 });
      expect(t.$('[data-category-create]')).toBeNull();
      expect(t.$('[data-category-limit]')!.textContent).toContain('50');
    });

    it('rename in place: PATCH with the new name; the same name can be saved in another case; Escape cancels', async () => {
      const t = await manage();
      t.$$('[data-category-row]')[0].querySelector<HTMLButtonElement>('[data-category-rename]')!.click();
      await t.stable();
      const input = t.$<HTMLInputElement>('[data-category-row="c1"] [data-category-name-input]')!;
      expect(input.value).toBe('ASP.NET Core');
      const save = t.$<HTMLButtonElement>('[data-category-row="c1"] [data-category-name-submit]')!;
      expect(save.disabled).toBe(true); // nothing changed yet
      type(input, 'asp.net core');
      await t.stable();
      expect(save.disabled).toBe(false);
      type(input, 'أفكار جايه');
      await t.stable();
      expect(t.$('[data-category-row="c1"] [data-category-name-error]')!.textContent!.trim()).toBe('عندك قسم بنفس الاسم بالفعل.');
      type(input, 'ASP.NET Core 10');
      await t.stable();
      save.click();
      const req = http.expectOne((r) => r.method === 'PATCH' && r.url === `${MINE}/c1`);
      expect(req.request.body).toEqual({ name: 'ASP.NET Core 10' });
      req.flush(category('c1', 'ASP.NET Core 10', 3, 1, 'asp-net-core'));
      await t.stable();
      expect(t.names()[0]).toBe('ASP.NET Core 10');
      // The slug (and every link to it) stays.
      expect(t.$('[data-category-row="c1"] [data-category-link]')!.getAttribute('href')).toBe('/@mona/c/asp-net-core');

      t.$('[data-category-row="c2"] [data-category-rename]')!.click();
      await t.stable();
      t.$('[data-category-row="c2"] [data-category-name-input]')!.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
      await t.stable();
      expect(t.$('[data-category-row="c2"] [data-category-name-input]')).toBeNull();
    });

    it('move down sends the whole order at once; a refused order goes back with a message', async () => {
      const t = await manage();
      t.$('[data-category-row="c1"] [data-move="down"]')!.click();
      await t.stable();
      expect(t.names()).toEqual(['Clean Code بالعربي', 'ASP.NET Core', 'أفكار جاية']);
      const req = http.expectOne((r) => r.method === 'PUT' && r.url === `${MINE}/order`);
      expect(req.request.body).toEqual({ categoryIds: ['c2', 'c1', 'c3'] });
      req.flush({ items: [{ ...LIST.items[1], sortOrder: 1 }, { ...LIST.items[0], sortOrder: 2 }, LIST.items[2]], uncategorizedCount: 2 });
      await t.stable();
      expect(t.names()).toEqual(['Clean Code بالعربي', 'ASP.NET Core', 'أفكار جاية']);

      const error = vi.spyOn(t.toasts, 'error');
      t.$('[data-category-row="c3"] [data-move="up"]')!.click();
      await t.stable();
      expect(t.names()).toEqual(['Clean Code بالعربي', 'أفكار جاية', 'ASP.NET Core']);
      http.expectOne(`${MINE}/order`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Error' });
      await t.stable();
      expect(t.names()).toEqual(['Clean Code بالعربي', 'ASP.NET Core', 'أفكار جاية']);
      expect(error).toHaveBeenCalledWith('معرفناش نحفظ الترتيب الجديد. جرّب تاني.');
    });

    it('delete asks first with the article count; its articles join "مقالات تانية"', async () => {
      const t = await manage();
      t.$('[data-category-row="c1"] [data-category-delete]')!.click();
      await t.stable();
      expect(document.querySelector('#category-delete-title')!.textContent!.trim()).toBe('تمسح «⁨ASP.NET Core⁩»؟');
      expect(document.querySelector('[data-category-delete-body]')!.textContent!.trim()).toBe('القسم ده فيه 3 مقالات، وهيفضلوا منشورين من غير قسم.');
      document.querySelector<HTMLButtonElement>('[data-category-delete-confirm]')!.click();
      const req = http.expectOne((r) => r.method === 'DELETE' && r.url === `${MINE}/c1`);
      req.flush(null, { status: 204, statusText: 'No Content' });
      await t.stable();
      expect(t.names()).toEqual(['Clean Code بالعربي', 'أفكار جاية']);
      expect(t.$('[data-category-card="_other"] [data-category-card-count]')!.textContent!.trim()).toBe('5 مقالات');

      t.$('[data-category-row="c2"] [data-category-delete]')!.click();
      await t.stable();
      expect(document.querySelector('[data-category-delete-body]')!.textContent!.trim()).toBe('القسم ده فاضي.');
    });
  });
});
