import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';
import { setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto } from '../../core/api/models';
import { TodayHero } from './today-hero';

function render(article: ArticleCardDto, lang: 'ar' | 'en' = 'ar') {
  setupSocialTesting({ guest: true });
  TestBed.inject(TranslocoService).setActiveLang(lang);
  const fixture = TestBed.createComponent(TodayHero);
  fixture.componentRef.setInput('article', article);
  fixture.detectChanges();
  return fixture.nativeElement as HTMLElement;
}

describe('TodayHero', () => {
  beforeEach(() => TestBed.resetTestingModule());

  it('shows the writer with their initial and the verified mark', () => {
    const root = render(testCard());
    const author = root.querySelector('[data-hero-author]')!;
    expect(author.textContent).toContain('Karim Hassan');
    expect(author.querySelector('rd-avatar')!.textContent!.trim()).toBe('K');
    expect(author.querySelector('svg[aria-label="كاتب موثّق"]')).not.toBeNull();
  });

  it('a deleted account’s article says “Deleted user” with a neutral avatar (SPEC §9.6)', () => {
    const root = render(testCard({ author: null }), 'en');
    const author = root.querySelector('[data-deleted-author]')!;
    expect(author.textContent!.trim()).toBe('Deleted user');
    expect(author.querySelector('rd-avatar')!.hasAttribute('data-generic-avatar')).toBe(true);
    expect(author.querySelector('rd-avatar')!.textContent!.trim()).toBe('');
    expect(root.querySelector('[data-hero-author]')).toBeNull();
    expect(root.querySelector('[aria-label="Verified writer"]')).toBeNull();
    expect(root.textContent).not.toMatch(/undefined|null|@/);
  });
});
