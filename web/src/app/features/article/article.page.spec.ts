import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { DOCUMENT } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard, testDetails } from '../../../testing/social-testing';
import { ArticleDetailsDto } from '../../core/api/models';
import { AppHistory } from '../../core/platform/app-history';
import { ArticlePage } from './article.page';

const SLUG = 'clean-architecture';

/** The reader for `article`, as a guest (no reading progress is reported). */
async function render(article: ArticleDetailsDto, lang: 'ar' | 'en' = 'ar', providers: unknown[] = []) {
  const { http } = setupSocialTesting({ guest: true, providers });
  TestBed.inject(TranslocoService).setActiveLang(lang);
  const fixture = TestBed.createComponent(ArticlePage);
  fixture.componentRef.setInput('lang', 'en');
  fixture.componentRef.setInput('slug', SLUG);
  fixture.detectChanges();
  await flushMicrotasks();
  // The page stays unstable while the article is on its way.
  http.expectOne(`${TEST_API}/articles/${SLUG}?lang=en`).flush(article);
  await flushMicrotasks();
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const byline = root.querySelector<HTMLElement>('[data-byline]')!;
  const jsonLd = () => JSON.parse(TestBed.inject(DOCUMENT).head.querySelector('script[type="application/ld+json"]')!.textContent!) as Record<string, unknown>;
  return { http, fixture, root, byline, jsonLd };
}

describe('ArticlePage byline', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http?.verify());

  it('shows the writer: photo or initial, profile link, verified mark and Follow', async () => {
    const t = await render(testDetails());
    http = t.http;
    expect(t.byline.querySelector('rd-avatar')!.textContent!.trim()).toBe('K');
    expect(t.byline.querySelector('rd-avatar')!.hasAttribute('data-generic-avatar')).toBe(false);
    expect(t.byline.querySelector('a[data-author-avatar][href="/@karim"] rd-avatar')).not.toBeNull();
    const profile = t.byline.querySelector<HTMLAnchorElement>('a[href="/@karim"]:not([data-author-avatar])')!;
    expect(profile.textContent).toContain('Karim Hassan');
    expect(profile.querySelector('svg[aria-label="كاتب موثّق"]')).not.toBeNull();
    expect(t.byline.querySelector('[data-author-follow] [data-follow]')!.textContent).toContain('متابعة');
    expect(t.byline.querySelector('[data-deleted-author]')).toBeNull();
    expect(t.jsonLd()['author']).toEqual({ '@type': 'Person', name: 'Karim Hassan', url: expect.stringMatching(/\/@karim$/) });
  });

  it('every tag links to its tag page by the slug the API gave it (F32), and is in the JSON-LD keywords', async () => {
    const tags = [
      { slug: 'csharp', name: 'C#' },
      { slug: 'الذكاء-الاصطناعي', name: 'الذكاء الاصطناعي' },
    ];
    const t = await render(testDetails({ tags, tagCount: 2 }));
    http = t.http;
    const links = [...t.root.querySelectorAll<HTMLAnchorElement>('[data-article-tags] a')];
    expect(links.map((a) => a.textContent!.trim())).toEqual(['#C#', '#الذكاء الاصطناعي']);
    expect(links.map((a) => a.getAttribute('href'))).toEqual(['/tags/csharp', `/tags/${encodeURIComponent('الذكاء-الاصطناعي')}`]);
    expect(links.every((a) => a.getAttribute('dir') === 'auto')).toBe(true);
    expect(t.root.querySelector('[data-article-tags]')!.getAttribute('aria-label')).toBe('التاجات');
    expect(t.jsonLd()['keywords']).toBe('C#, الذكاء الاصطناعي');
  });

  it('a deleted account’s article says “Deleted user”: a neutral avatar, no link, @username, verified mark or Follow (SPEC §9.6)', async () => {
    const t = await render(testDetails({ author: null, isFollowingAuthor: false }));
    http = t.http;
    expect(t.byline.querySelector('[data-deleted-author]')!.textContent!.trim()).toBe('مستخدم محذوف');
    const avatar = t.byline.querySelector('rd-avatar')!;
    expect(avatar.hasAttribute('data-generic-avatar')).toBe(true);
    expect(avatar.textContent!.trim()).toBe(''); // an icon, no initial
    expect(avatar.querySelector('img')).toBeNull();
    expect(t.byline.querySelector('a')).toBeNull();
    expect(t.root.querySelector('a[href^="/@"]')).toBeNull();
    expect(t.root.querySelector('[data-author-follow]')).toBeNull();
    expect(t.root.querySelector('[data-follow]')).toBeNull();
    expect(t.root.querySelector('[aria-label="كاتب موثّق"]')).toBeNull();
    expect(t.root.textContent).not.toContain('كاتب موثّق'); // nor in the trust row
    expect(t.byline.textContent).not.toMatch(/undefined|null|@/);
    // The article itself is still there, and nothing in its structured data points to the person.
    expect(t.root.querySelector('h1')!.textContent).toContain('Clean Architecture on one whiteboard');
    expect(t.jsonLd()).not.toHaveProperty('author');
    expect(JSON.stringify(t.jsonLd())).not.toContain('/@');
  });

  it('says “Deleted user” in English', async () => {
    const t = await render(testDetails({ author: null }), 'en');
    http = t.http;
    expect(t.byline.querySelector('[data-deleted-author]')!.textContent!.trim()).toBe('Deleted user');
  });
});

describe('ArticlePage health disclaimer (SPEC F04, §20)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http?.verify());

  const sensitive = (patch: Partial<ArticleDetailsDto> = {}) =>
    testDetails({ field: { ...testCard().field, id: 'f-medicine', slug: 'medicine', nameAr: 'الطب', nameEn: 'Medicine', isSensitive: true }, ...patch });

  it('shows on Medicine and Public Health articles: below the trust row, above the TL;DR and the content', async () => {
    const t = await render(sensitive({ summary: 'Sleep consolidates memory.' }));
    http = t.http;
    const notice = t.root.querySelector('[data-health-disclaimer]')!;
    expect(notice.getAttribute('role')).toBe('note');
    expect(notice.textContent!.trim()).toBe('المعلومات دي للتوعية ولا تغني عن استشارة الطبيب.');
    expect(notice.querySelector('svg')!.getAttribute('aria-hidden')).toBe('true');
    const follows = (a: Element, b: Element) => !!(a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING);
    expect(follows(t.root.querySelector('[data-trust-row]')!, notice)).toBe(true);
    expect(follows(notice, t.root.querySelector('.rd-summary')!)).toBe(true);
    expect(follows(notice, t.root.querySelector('rd-rdoc')!)).toBe(true);
  });

  it('is in the UI language', async () => {
    const t = await render(sensitive(), 'en');
    http = t.http;
    expect(t.root.querySelector('[data-health-disclaimer]')!.textContent!.trim()).toBe(
      "This information is for awareness only and is not a substitute for a doctor's advice.",
    );
  });

  it('is not on other fields (nor when an older API leaves the flag out)', async () => {
    const t = await render(testDetails());
    http = t.http;
    expect(t.root.querySelector('[data-health-disclaimer]')).toBeNull();
  });
});

describe('ArticlePage back button (F04)', () => {
  let http: HttpTestingController | null = null;
  const back = vi.fn();

  beforeEach(() => {
    TestBed.resetTestingModule();
    back.mockClear();
  });
  afterEach(() => http?.verify());

  it('goes back through the app history (Home when the article is the first page), a link to Home without JavaScript', async () => {
    const t = await render(testDetails(), 'ar', [{ provide: AppHistory, useValue: { back } }]);
    http = t.http;
    const link = t.root.querySelector<HTMLAnchorElement>('a[data-reader-back]')!;
    expect(link.getAttribute('href')).toBe('/');
    expect(link.getAttribute('aria-label')).toBe('رجوع');
    const click = new MouseEvent('click', { bubbles: true, cancelable: true, button: 0 });
    link.dispatchEvent(click);
    expect(back).toHaveBeenCalledExactlyOnceWith('/');
    expect(click.defaultPrevented).toBe(true);
  });

  it('a modified click opens Home in a new tab or window, like any link', async () => {
    const t = await render(testDetails(), 'ar', [{ provide: AppHistory, useValue: { back } }]);
    http = t.http;
    const click = new MouseEvent('click', { bubbles: true, cancelable: true, button: 0, ctrlKey: true });
    t.root.querySelector('a[data-reader-back]')!.dispatchEvent(click);
    expect(back).not.toHaveBeenCalled();
    expect(click.defaultPrevented).toBe(false);
  });
});
