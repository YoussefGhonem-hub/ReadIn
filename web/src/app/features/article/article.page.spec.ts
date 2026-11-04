import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { DOCUMENT } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { TEST_API, flushMicrotasks, setupSocialTesting, testDetails } from '../../../testing/social-testing';
import { ArticleDetailsDto } from '../../core/api/models';
import { ArticlePage } from './article.page';

const SLUG = 'clean-architecture';

/** The reader for `article`, as a guest (no reading progress is reported). */
async function render(article: ArticleDetailsDto, lang: 'ar' | 'en' = 'ar') {
  const { http } = setupSocialTesting({ guest: true });
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
