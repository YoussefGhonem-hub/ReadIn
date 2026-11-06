import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { LanguageService } from '../../core/i18n/language.service';
import { ArticleSocialStore } from '../../core/social/article-social.store';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { RepostButton } from './repost-button';

const REPOST_URL = `${TEST_API}/articles/a1/repost`;

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
  const button = root.querySelector<HTMLButtonElement>('[data-repost]')!;
  /** Opens the menu (a CDK overlay on the document) and lists its items with their labels. */
  const openMenu = async () => {
    button.click();
    await stable();
    return [...document.querySelectorAll('[data-repost-menu] [data-repost-action]')].map((el) => [el.getAttribute('data-repost-action'), el.textContent!.trim()]);
  };
  const pick = async (action: string) => {
    document.querySelector<HTMLElement>(`[data-repost-menu] [data-repost-action="${action}"]`)!.click();
    await stable();
  };
  /** Waits for the dialog's lazy chunk to render. */
  const waitFor = async (selector: string) => {
    for (let i = 0; i < 50 && !root.querySelector(selector); i++) {
      await new Promise((resolve) => setTimeout(resolve, 10));
      await stable();
    }
    return root.querySelector<HTMLElement>(selector);
  };
  return { fixture, root, http, stable, button, openMenu, pick, waitFor, count: () => root.querySelector('[data-repost-count]') };
}

describe('RepostButton (F29)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    http?.verify();
    http = null;
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));
  });

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
    // No menu for guests.
    expect(t.button.getAttribute('aria-haspopup')).toBeNull();
    expect(document.querySelector('[data-repost-menu]')).toBeNull();
  });

  it('not reposted: a menu with "Repost" (at once, optimistic, no body) and "Repost with your thoughts"; reposted: "Edit your thoughts" and "Undo repost"', async () => {
    const t = await render(testCard({ repostCount: 3 }));
    http = t.http;
    expect(t.button.getAttribute('aria-haspopup')).toBe('menu');
    expect(t.button.getAttribute('aria-expanded')).toBe('false');
    expect(await t.openMenu()).toEqual([
      ['repost', 'Repost'],
      ['thoughts', 'Repost with your thoughts'],
    ]);
    expect(t.button.getAttribute('aria-expanded')).toBe('true');

    await t.pick('repost');
    expect(document.querySelector('[data-repost-menu]')).toBeNull();
    expect(t.button.getAttribute('aria-pressed')).toBe('true');
    expect(t.count()!.textContent!.trim()).toBe('4');
    expect(t.button.getAttribute('aria-label')).toBe('Repost, 4');
    const put = t.http.expectOne(REPOST_URL);
    expect(put.request.method).toBe('PUT');
    expect(put.request.body).toBeNull();
    put.flush({ repostCount: 4, isReposted: true, caption: null });
    await t.stable();

    expect(await t.openMenu()).toEqual([
      ['edit', 'Edit your thoughts'],
      ['undo', 'Undo repost'],
    ]);
    await t.pick('undo');
    expect(t.button.getAttribute('aria-pressed')).toBe('false');
    expect(t.count()!.textContent!.trim()).toBe('3');
    const del = t.http.expectOne(REPOST_URL);
    expect(del.request.method).toBe('DELETE');
    del.flush({ repostCount: 3, isReposted: false, caption: null });
    await t.stable();
    expect(t.button.getAttribute('aria-pressed')).toBe('false');
  });

  it('the menu in Arabic', async () => {
    const t = await render(testCard(), { lang: 'ar' });
    http = t.http;
    expect((await t.openMenu()).map(([, label]) => label)).toEqual(['إعادة النشر', 'إعادة النشر مع رأيك']);
    document.querySelectorAll('.cdk-overlay-container').forEach((el) => (el.innerHTML = ''));

    TestBed.resetTestingModule();
    const reposted = await render(testCard({ isReposted: true, repostCount: 1 }), { lang: 'ar' });
    http = reposted.http;
    expect((await reposted.openMenu()).map(([, label]) => label)).toEqual(['تعديل رأيك', 'إلغاء إعادة النشر']);
  });

  it('"Repost with your thoughts" opens the caption dialog; nothing is sent until you submit', async () => {
    const t = await render(testCard());
    http = t.http;
    await t.openMenu();
    await t.pick('thoughts');
    const dialog = await t.waitFor('[data-repost-dialog]');
    expect(dialog).not.toBeNull();
    expect(dialog!.getAttribute('data-mode')).toBe('new');
    expect(dialog!.querySelector('[data-repost-submit]')!.textContent!.trim()).toBe('Repost');
    t.http.expectNone(REPOST_URL);
    expect(t.button.getAttribute('aria-pressed')).toBe('false');

    // Cancel closes it; still nothing sent.
    dialog!.querySelector<HTMLButtonElement>('[data-repost-cancel]')!.click();
    await t.stable();
    expect(t.root.querySelector('[data-repost-dialog]')).toBeNull();
    t.http.expectNone(REPOST_URL);
  });

  it('"Edit your thoughts" opens the dialog prefilled from GET', async () => {
    const t = await render(testCard({ isReposted: true, repostCount: 2 }));
    http = t.http;
    await t.openMenu();
    await t.pick('edit');
    const dialog = await t.waitFor('[data-repost-dialog]');
    expect(dialog!.getAttribute('data-state')).toBe('loading');
    const get = t.http.expectOne(REPOST_URL);
    expect(get.request.method).toBe('GET');
    get.flush({ repostCount: 2, isReposted: true, caption: 'Worth a read.' });
    await t.stable();
    expect(dialog!.getAttribute('data-state')).toBe('ready');
    expect(dialog!.getAttribute('data-mode')).toBe('edit');
    expect(dialog!.querySelector<HTMLTextAreaElement>('[data-repost-caption]')!.value).toBe('Worth a read.');
    expect(dialog!.querySelector('[data-repost-submit]')!.textContent!.trim()).toBe('Save');
  });

  it('your own article: no menu, the hint as a toast, nothing sent', async () => {
    const t = await render(testCard({ author: { id: 'user-1', displayName: 'Mona Adel', username: 'mona', avatarUrl: null, isVerified: false } }));
    http = t.http;
    expect(t.button.getAttribute('aria-disabled')).toBe('true');
    expect(t.button.getAttribute('aria-haspopup')).toBeNull();
    expect(t.button.getAttribute('aria-pressed')).toBeNull();
    expect(t.button.getAttribute('title')).toBe("You can't repost your own article");
    t.button.click();
    await t.stable();
    expect(document.querySelector('[data-repost-menu]')).toBeNull();
    expect(TestBed.inject(ToastService).toasts().map((toast) => toast.message)).toEqual(["You can't repost your own article"]);
    t.http.expectNone(REPOST_URL);
  });
});
