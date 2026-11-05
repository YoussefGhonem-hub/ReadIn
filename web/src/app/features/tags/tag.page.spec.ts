import { RESPONSE_INIT } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController, TestRequest } from '@angular/common/http/testing';
import { Meta, Title } from '@angular/platform-browser';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto, CursorPage, TagDto } from '../../core/api/models';
import { TagPageStore } from './tag-page.store';
import { TagPage } from './tag.page';

const CSHARP: TagDto = { slug: 'csharp', name: 'C#', articleCount: 23 };
const card = (n: number): ArticleCardDto => testCard({ id: `a${n}`, slug: `note-${n}`, title: `C# note ${n}` });
const page = (from: number, count: number, nextCursor: string | null): CursorPage<ArticleCardDto> => ({
  items: Array.from({ length: count }, (_, i) => card(from + i)),
  nextCursor,
});

type Answer<T> = T | { status: number; code: string };

function answer<T extends object>(req: TestRequest, body: Answer<T>): void {
  if (body && typeof body === 'object' && 'status' in body && 'code' in body) req.flush(problem(body.status, body.code), { status: body.status, statusText: 'Error' });
  else req.flush(body);
}

describe('TagPage (F32)', () => {
  let http: HttpTestingController;
  let response: { status?: number };

  afterEach(() => {
    http?.verify();
    document.head.querySelectorAll('[data-rd-tag-seo]').forEach((el) => el.remove());
  });

  async function render(slug: string, tag: Answer<TagDto>, list: Answer<CursorPage<ArticleCardDto>>) {
    TestBed.resetTestingModule();
    response = {};
    ({ http } = setupSocialTesting({ guest: true, providers: [{ provide: RESPONSE_INIT, useValue: response }] }));
    const fixture = TestBed.createComponent(TagPage);
    fixture.componentRef.setInput('slug', slug);
    fixture.detectChanges();
    const url = `${TEST_API}/tags/${encodeURIComponent(slug)}`;
    answer(http.expectOne(url), tag);
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
    const store = fixture.debugElement.injector.get(TagPageStore);
    return { fixture, root, stable, store, url, $: <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector) };
  }

  const robots = () => TestBed.inject(Meta).getTag('name="robots"')?.content ?? null;
  const canonical = () => document.head.querySelector('link[rel="canonical"][data-rd-tag-seo]')?.getAttribute('href') ?? null;

  it('shows "#name", the article count and the articles as post cards; title, description and canonical for crawlers', async () => {
    const { $, root } = await render('csharp', CSHARP, page(1, 20, '20'));
    expect($('[data-tag-name]')!.textContent!.trim()).toBe('#C#');
    expect($('[data-tag-name]')!.getAttribute('dir')).toBe('auto');
    expect($('[data-tag-count]')!.textContent!.trim()).toBe('23 مقال');
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(20);
    expect($('[data-tag-end]')).toBeNull(); // more to come
    expect(TestBed.inject(Title).getTitle()).toBe('#C# — ReadIn');
    expect(TestBed.inject(Meta).getTag('name="description"')!.content).toBe('23 مقال بالتاج #C# على ReadIn.');
    expect(canonical()).toMatch(/\/tags\/csharp$/);
    expect(robots()).toBeNull();
    expect(response.status).toBeUndefined();
  });

  it('loads the next page with the cursor, then says that was all', async () => {
    const { root, store, stable, url, $ } = await render('csharp', CSHARP, page(1, 20, '20'));
    const more = store.loadMore();
    answer(
      http.expectOne((r) => r.url === `${url}/articles` && r.params.get('cursor') === '20'),
      page(21, 3, null),
    );
    await more;
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(23);
    expect($('[data-tag-end]')!.textContent).toContain('كده شفت كل المقالات بالتاج ده.');
    await store.loadMore(); // nothing left: no request
  });

  it('a page that fails to load more offers Retry, and keeps the cards', async () => {
    const { root, store, stable, url, $ } = await render('csharp', CSHARP, page(1, 20, '20'));
    const more = store.loadMore();
    answer(http.expectOne((r) => r.url === `${url}/articles` && r.params.get('cursor') === '20'), { status: 503, code: 'server.error' });
    await more;
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(20);
    $('[data-tag-load-more-retry]')!.click();
    answer(http.expectOne((r) => r.url === `${url}/articles` && r.params.get('cursor') === '20'), page(21, 3, null));
    await stable();
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(23);
  });

  it('an empty tag shows the empty state and is noindex', async () => {
    const { $, root } = await render('kotlin', { slug: 'kotlin', name: 'kotlin', articleCount: 0 }, page(1, 0, null));
    expect($('[data-tag-name]')!.textContent!.trim()).toBe('#kotlin');
    expect($('[data-tag-count]')!.textContent!.trim()).toBe('0 مقال');
    expect($('[data-tag-empty]')!.textContent).toContain('لسه مفيش مقالات بالتاج ده');
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(0);
    expect(robots()).toBe('noindex');
    expect(TestBed.inject(Meta).getTag('name="description"')!.content).toBe('لسه مفيش مقالات بالتاج #kotlin على ReadIn.');
  });

  it('an unknown or hidden tag is a 404 page, noindex', async () => {
    const notFound = { status: 404, code: 'tag.not_found' };
    const { $ } = await render('spam-links', notFound, notFound);
    expect($('[data-tag-not-found]')!.textContent).toContain('التاج ده مش موجود');
    expect($('[data-tag-header]')).toBeNull();
    expect(response.status).toBe(404);
    expect(robots()).toBe('noindex');
    expect(TestBed.inject(Title).getTitle()).toBe('التاج ده مش موجود — ReadIn');
    expect(canonical()).toBeNull();
  });

  it('a failure shows an error with Retry, which loads the page again', async () => {
    const { $, stable, url, root } = await render('csharp', { status: 503, code: 'server.error' }, page(1, 1, null));
    expect($('rd-error-state')).not.toBeNull();
    $<HTMLButtonElement>('rd-error-state button')!.click();
    answer(http.expectOne(url), CSHARP);
    answer(http.expectOne((r) => r.url === `${url}/articles`), page(1, 2, null));
    await stable();
    expect(root.querySelectorAll('rd-post-card')).toHaveLength(2);
  });

  it('an Arabic slug is percent-encoded in the API call; the name keeps its own direction', async () => {
    const tag: TagDto = { slug: 'الذكاء-الاصطناعي', name: 'الذكاء الاصطناعي', articleCount: 1 };
    const { $ } = await render(tag.slug, tag, page(1, 1, null));
    expect($('[data-tag-name]')!.textContent!.trim()).toBe('#الذكاء الاصطناعي');
    expect($('[data-tag-count]')!.textContent!.trim()).toBe('مقال واحد');
    expect(canonical()).toContain(`/tags/${encodeURIComponent(tag.slug)}`);
  });
});
