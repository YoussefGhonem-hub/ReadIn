import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { RepostButton } from './repost-button';

async function render(article: ArticleCardDto, options: { guest?: boolean; lang?: 'ar' | 'en'; variant?: 'card' | 'bar' } = {}) {
  const { http } = setupSocialTesting({ guest: options.guest });
  await TestBed.inject(LanguageService).setLanguage(options.lang ?? 'en');
  const fixture = TestBed.createComponent(RepostButton);
  fixture.componentRef.setInput('article', article);
  if (options.variant) fixture.componentRef.setInput('variant', options.variant);
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  return { fixture, http, stable, button: root.querySelector<HTMLButtonElement>('[data-repost]')!, count: () => root.querySelector('[data-repost-count]') };
}

describe('RepostButton (F29)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => http?.verify());

  it('the icon with its count; named "Repost, 3"; pressed once you reposted', async () => {
    const t = await render(testCard({ repostCount: 3, isReposted: true }), { variant: 'bar' });
    http = t.http;
    expect(t.button.getAttribute('aria-label')).toBe('Repost, 3');
    expect(t.button.getAttribute('aria-pressed')).toBe('true');
    expect(t.button.getAttribute('data-reposted')).toBe('true');
    expect(t.count()!.textContent!.trim()).toBe('3');
    expect(t.button.querySelector('svg')).not.toBeNull();
  });

  it('large counts are compact, with Western digits in Arabic too', async () => {
    const t = await render(testCard({ repostCount: 1250 }), { lang: 'ar' });
    http = t.http;
    expect(t.count()!.textContent!.trim()).toMatch(/^1[.,]?\d?\s?(K|ألف)$/);
    expect(t.button.getAttribute('aria-label')).toBe('إعادة نشر، 1250');
  });

  it('the live count replaces the number (F27)', async () => {
    const article = testCard({ repostCount: 1 });
    const t = await render(article);
    http = t.http;
    TestBed.inject(ArticleSocialStore).applyLive(article, { reactions: null, reactionCount: null, commentCount: null, saveCount: null, repostCount: 6 });
    await t.stable();
    expect(t.count()!.textContent!.trim()).toBe('6');
    expect(t.button.getAttribute('aria-label')).toBe('Repost, 6');
  });

  it('guests get the sign-in prompt and nothing is sent', async () => {
    const t = await render(testCard(), { guest: true });
    http = t.http;
    t.button.click();
    await t.stable();
    expect(TestBed.inject(AuthPromptService).isOpen()).toBe(true);
    t.http.expectNone(`${TEST_API}/articles/a1/repost`);
    expect(t.button.getAttribute('aria-pressed')).toBe('false');
  });
});
