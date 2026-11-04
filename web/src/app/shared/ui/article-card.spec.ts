import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TranslocoService } from '@jsverse/transloco';
import { setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto } from '../../core/api/models';
import { ArticleCard } from './article-card';

async function render(article: ArticleCardDto, lang: 'ar' | 'en' = 'ar') {
  const { http } = setupSocialTesting({ guest: true });
  TestBed.inject(TranslocoService).setActiveLang(lang);
  const fixture = TestBed.createComponent(ArticleCard);
  fixture.componentRef.setInput('article', article);
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  return { http, root, $: (selector: string) => root.querySelector<HTMLElement>(selector) };
}

describe('ArticleCard', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http?.verify());

  it('shows the writer with the verified mark', async () => {
    const t = await render(testCard());
    http = t.http;
    expect(t.$('[data-card-author]')!.textContent).toContain('Karim Hassan');
    expect(t.$('[data-card-author] svg[aria-label="كاتب موثّق"]')).not.toBeNull();
    expect(t.$('[data-deleted-author]')).toBeNull();
  });

  it('a deleted account’s article says “Deleted user”: no name, @username or verified mark (SPEC §9.6)', async () => {
    const t = await render(testCard({ author: null }));
    http = t.http;
    expect(t.$('[data-deleted-author]')!.textContent!.trim()).toBe('مستخدم محذوف');
    expect(t.$('[data-card-author]')).toBeNull();
    expect(t.root.querySelector('[aria-label="كاتب موثّق"]')).toBeNull();
    expect(t.root.querySelector('a[href^="/@"]')).toBeNull();
    expect(t.root.textContent).not.toMatch(/undefined|null|@/);
    // The rest of the card is unchanged.
    expect(t.$('h3')!.textContent).toContain('Clean Architecture on one whiteboard');
    expect(t.$('[data-card-save]')).not.toBeNull();
  });

  it('says “Deleted user” in English', async () => {
    const t = await render(testCard({ author: null }), 'en');
    http = t.http;
    expect(t.$('[data-deleted-author]')!.textContent!.trim()).toBe('Deleted user');
  });
});
