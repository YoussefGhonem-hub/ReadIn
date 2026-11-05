import { RESPONSE_INIT } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { Meta, Title } from '@angular/platform-browser';
import { TEST_API, WARM_UP_TIMEOUT_MS, flushMicrotasks, problem, setupSocialTesting, testCard, warmUpPostCards } from '../../../testing/social-testing';
import { ArticleCardDto, CursorPage, WriterCategoryPageDto } from '../../core/api/models';
import { CategoryPageStore } from './category-page.store';
import { CategoryPage } from './category.page';

const MONA = { id: 'u-writer', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: true };
const TIPS: WriterCategoryPageDto = { id: 'c-tips', slug: 'نصايح-البرمجة', name: 'نصايح البرمجة', articleCount: 23, author: MONA };
const card = (n: number): ArticleCardDto => testCard({ id: `a${n}`, slug: `note-${n}`, title: `Note ${n}` });
const page = (from: number, count: number, nextCursor: string | null): CursorPage<ArticleCardDto> => ({
  items: Array.from({ length: count }, (_, i) => card(from + i)),
  nextCursor,
});

type Answer<T> = T | { status: number; code: string };

function answer<T extends object>(req: TestRequest, body: Answer<T>): void {
  if (body && typeof body === 'object' && 'status' in body && 'code' in body) req.flush(problem(body.status, body.code), { status: body.status, statusText: 'Error' });
  else req.flush(body);
}

describe('CategoryPage (F31)', () => {
  let http: HttpTestingController;

  // The cards prefetch their preview chunk: load it once here, not inside the first test (see warmUpPostCards).
  beforeAll(warmUpPostCards, WARM_UP_TIMEOUT_MS);
  let response: { status?: number };

  afterEach(() => {
    http?.verify();
    document.head.querySelectorAll('[data-rd-category-seo]').forEach((el) => el.remove());
  });

  async function render(slug: string, header: Answer<WriterCategoryPageDto>, list: Answer<CursorPage<ArticleCardDto>>) {
    TestBed.resetTestingModule();
    response = {};
    ({ http } = setupSocialTesting({ guest: true, providers: [{ provide: RESPONSE_INIT, useValue: response }] }));
    const fixture = TestBed.createComponent(CategoryPage);
    fixture.componentRef.setInput('username', 'mona');
    fixture.componentRef.setInput('slug', slug);
    fixture.detectChanges();
    const url = `${TEST_API}/users/mona/categories/${encodeURIComponent(slug)}`;
    answer(http.expectOne(url), header);
    answer(
      http.expectOne((r) => r.url === `${url}/articles` && r.params.get('limit') === '20' && !r.params.has('cursor')),
      list,
    );
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
      await fixture.whenStable();
    };
    await stable();
    const store = fixture.debugElement.injector.get(CategoryPageStore);
    return { fixture, root, stable, store, url, $: <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector) };
  }

  const robots = () => TestBed.inject(Meta).getTag('name="robots"')?.content ?? null;
  const canonical = () => document.head.querySelector('link[rel="canonical"][data-rd-category-seo]')?.getAttribute('href') ?? null;

  it('shows the writer, the name in its own direction, the count and the articles; title, description and canonical', async () => {
    const { $, root } = await render('نصايح-البرمجة', TIPS, page(1, 20, '20'));
    expect($('[data-category-name]')!.textContent!.trim()).toBe('نصايح البرمجة');
    expect($('[data-category-name]')!.getAttribute('dir')).toBe('auto');
    expect($('[data-category-count]')!.textContent!.trim()).toBe('23 مقال');
    expect($('[data-category-author]')!.getAttribute('href')).toBe('/@mona');
    expect($('[data-category-author]')!.textContent).toContain('Mona Adel');
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(20);
    expect($('[data-category-end]')).toBeNull();
    expect(TestBed.inject(Title).getTitle()).toBe('نصايح البرمجة · Mona Adel — ReadIn');
    expect(TestBed.inject(Meta).getTag('name="description"')!.content).toBe('23 مقال من Mona Adel في «نصايح البرمجة» على ReadIn.');
    // The slug is percent-encoded in the canonical URL.
    expect(canonical()).toMatch(/\/@mona\/c\/%D9%86%D8%B5%D8%A7%D9%8A%D8%AD-%D8%A7%D9%84%D8%A8%D8%B1%D9%85%D8%AC%D8%A9$/);
    expect(robots()).toBeNull();
    expect(response.status).toBeUndefined();
  });

  it('loads the next page with the cursor, then says that was all', async () => {
    const { root, store, stable, url, $ } = await render('نصايح-البرمجة', TIPS, page(1, 20, '20'));
    const more = store.loadMore();
    answer(
      http.expectOne((r) => r.url === `${url}/articles` && r.params.get('cursor') === '20'),
      page(21, 3, null),
    );
    await more;
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(23);
    expect($('[data-category-end]')).not.toBeNull();
  });

  it('"مقالات تانية" (_other): the uncategorized list, with its own title', async () => {
    const other: WriterCategoryPageDto = { id: null, slug: '_other', name: null, articleCount: 1, author: MONA };
    const { $ } = await render('_other', other, page(1, 1, null));
    expect($('[data-category-name]')!.textContent!.trim()).toBe('مقالات تانية');
    expect($('[data-category-author]')!.textContent).toContain('من غير قسم');
    expect(TestBed.inject(Title).getTitle()).toBe('مقالات تانية · Mona Adel — ReadIn');
    expect(canonical()).toMatch(/\/@mona\/c\/_other$/);
  });

  it('an empty category: the empty state, a way back to the profile, and noindex', async () => {
    const { $ } = await render('ideas', { ...TIPS, slug: 'ideas', name: 'أفكار جاية', articleCount: 0 }, page(1, 0, null));
    expect($('[data-category-count]')!.textContent!.trim()).toBe('لسه مفيش مقالات');
    expect($('[data-category-empty]')!.textContent).toContain('لسه مفيش مقالات في القسم ده');
    expect($('[data-category-empty]')!.textContent).toContain('أول ما الكاتب يحط فيه مقالات، هتلاقيها هنا.');
    expect($('[data-category-empty] a')!.getAttribute('href')).toBe('/@mona');
    expect($('[data-category-empty] a')!.textContent!.trim()).toBe('روح لبروفايل الكاتب');
    expect(robots()).toBe('noindex');
  });

  it('an empty "مقالات تانية" doesn\'t call itself a category', async () => {
    const other: WriterCategoryPageDto = { id: null, slug: '_other', name: null, articleCount: 0, author: MONA };
    const { $ } = await render('_other', other, page(1, 0, null));
    const empty = $('[data-category-empty]')!.textContent!;
    expect(empty).toContain('مفيش مقالات من غير قسم');
    expect(empty).toContain('كل مقالات الكاتب ده في أقسام.');
    expect(empty).not.toContain('القسم ده');
  });

  it('an unknown slug is a 404 that leads back to the writer; an unknown writer leads Home', async () => {
    const missing = await render('gone', { status: 404, code: 'category.not_found' }, { status: 404, code: 'category.not_found' });
    expect(missing.$('[data-category-not-found]')!.textContent).toContain('القسم ده مش موجود');
    // A rename keeps the slug, so the link broke because it was deleted (or cleared), or it is wrong.
    expect(missing.$('[data-category-not-found]')!.textContent).toContain('ممكن يكون اتمسح، أو اللينك غلط.');
    expect(missing.$('[data-category-not-found] a')!.getAttribute('href')).toBe('/@mona');
    expect(response.status).toBe(404);
    expect(robots()).toBe('noindex');

    const nobody = await render('x', { status: 404, code: 'user.not_found' }, { status: 404, code: 'user.not_found' });
    expect(nobody.$('[data-category-not-found] a')!.getAttribute('href')).toBe('/');
  });

  it('a failure offers Retry', async () => {
    const { $, stable, url } = await render('نصايح-البرمجة', { status: 500, code: 'server.error' }, page(1, 1, null));
    expect($('rd-error-state')).not.toBeNull();
    ($('rd-error-state button') as HTMLButtonElement).click();
    answer(http.expectOne(url), TIPS);
    answer(http.expectOne((r) => r.url === `${url}/articles`), page(1, 2, null));
    await stable();
    expect($('[data-category-header]')).not.toBeNull();
  });
});
