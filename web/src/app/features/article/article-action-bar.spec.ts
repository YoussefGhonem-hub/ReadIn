import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto } from '../../core/api/models';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { ArticleActionBar } from './article-action-bar';
import { PICK_ANIMATION_MS } from './reaction-button';

async function render(article: ArticleCardDto = testCard(), options: { guest?: boolean } = {}) {
  const { http } = setupSocialTesting(options);
  const fixture = TestBed.createComponent(ArticleActionBar);
  fixture.componentRef.setInput('article', article);
  fixture.componentRef.setInput('url', 'https://readin.test/en/a/clean-architecture');
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  const stable = async () => {
    fixture.detectChanges();
    await fixture.whenStable();
  };
  return { fixture, root, $, http, stable };
}

function key(target: Element, key: string): void {
  target.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true }));
}

/** jsdom has no matchMedia: "reduce motion" is whatever the test says. */
function stubReducedMotion(reduce: boolean): void {
  vi.stubGlobal('matchMedia', (query: string) => ({ matches: query.includes('reduce') ? reduce : false, media: query, addEventListener: () => undefined, removeEventListener: () => undefined }));
}

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

describe('ArticleActionBar (F10, F13, F29)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    http?.verify();
    vi.unstubAllGlobals();
  });

  it('shows the total, the top reactions and the comment count', async () => {
    const t = await render();
    http = t.http;
    expect(t.$('[data-reaction-total]')!.textContent!.trim()).toBe('12');
    expect(t.$('[data-reactions-summary]')!.textContent).toContain('💡❤️🔥');
    expect(t.$('[data-reactions-summary]')!.getAttribute('aria-label')).toBe('12 تفاعل، شوف مين اتفاعل');
    expect(t.$('[data-comment-count]')!.textContent).toContain('3');
    expect(t.$('[data-react]')!.getAttribute('aria-label')).toBe('تفاعل');
    expect(t.$('[data-react]')!.getAttribute('aria-pressed')).toBe('false');
  });

  it('a tap reacts 💡; tapping your reaction removes it', async () => {
    const t = await render();
    http = t.http;
    t.$('[data-react]')!.click();
    await t.stable();
    expect(t.$('[data-react]')!.getAttribute('data-my-reaction')).toBe('insightful');
    expect(t.$('[data-react]')!.getAttribute('aria-label')).toBe('تفاعلت: مفيد');
    expect(t.$('[data-react]')!.getAttribute('aria-pressed')).toBe('true');
    expect(t.$('[data-reaction-total]')!.textContent!.trim()).toBe('13');
    t.http.expectOne(`${TEST_API}/articles/a1/reaction`).flush({ reactions: { insightful: 7, love: 3, fire: 2, mindBlown: 1 }, total: 13, myReaction: 'insightful' });
    await flushMicrotasks();

    t.$('[data-react]')!.click();
    await t.stable();
    expect(t.$('[data-react]')!.hasAttribute('data-my-reaction')).toBe(false);
    const req = t.http.expectOne(`${TEST_API}/articles/a1/reaction`);
    expect(req.request.method).toBe('DELETE');
    req.flush({ reactions: { insightful: 6, love: 3, fire: 2, mindBlown: 1 }, total: 12, myReaction: null });
    await flushMicrotasks();
  });

  it('the picker opens from the keyboard, follows the reading direction and picks with Enter', async () => {
    const t = await render();
    http = t.http;
    const trigger = t.$('[data-react]')!;
    trigger.focus();
    key(trigger, 'ArrowUp');
    await t.stable();
    const picker = t.$('[data-reaction-picker]')!;
    expect(picker.getAttribute('role')).toBe('menu');
    expect(t.$('[data-reaction-picker-toggle]')!.getAttribute('aria-expanded')).toBe('true');
    expect(document.activeElement?.getAttribute('data-reaction')).toBe('insightful');
    // LinkedIn-style: no numbers or text in the bar; each reaction is named for screen readers.
    expect(picker.textContent!.replace(/s/g, '')).toBe('💡❤️🔥🤯');
    expect([...picker.querySelectorAll('[role="menuitemradio"]')].map((b) => b.getAttribute('aria-label'))).toEqual(['مفيد', 'حبيته', 'نار', 'مبهر']);
    // They enter one after another.
    expect([...picker.querySelectorAll<HTMLElement>('[role="menuitemradio"]')].map((b) => b.style.animationDelay)).toEqual(['0ms', '50ms', '100ms', '150ms']);

    // Arabic UI (RTL): ArrowLeft moves forward.
    key(document.activeElement!, 'ArrowLeft');
    await t.stable();
    expect(document.activeElement?.getAttribute('data-reaction')).toBe('love');
    key(document.activeElement!, 'End');
    await t.stable();
    expect(document.activeElement?.getAttribute('data-reaction')).toBe('mindBlown');

    (document.activeElement as HTMLElement).click(); // Enter on a button
    await t.stable();
    // The pick plays its short animation, then the bar closes.
    expect(t.$('[data-reaction-picker]')!.getAttribute('data-picked')).toBe('mindBlown');
    expect(t.$('[data-reaction="mindBlown"]')!.classList).toContain('is-picked');
    await wait(PICK_ANIMATION_MS + 20);
    await t.stable();
    expect(t.$('[data-reaction-picker]')).toBeNull();
    expect(document.activeElement).toBe(trigger);
    expect(t.$('[data-react]')!.getAttribute('data-my-reaction')).toBe('mindBlown');
    const req = t.http.expectOne(`${TEST_API}/articles/a1/reaction`);
    expect(req.request.body).toEqual({ type: 'mindBlown' });
    req.flush({ reactions: { insightful: 6, love: 3, fire: 2, mindBlown: 2 }, total: 13, myReaction: 'mindBlown' });
    await flushMicrotasks();
  });

  it('with reduce motion a pick closes the bar at once, with no animation', async () => {
    stubReducedMotion(true);
    const t = await render();
    http = t.http;
    t.$('[data-reaction-picker-toggle]')!.click();
    await t.stable();
    t.$('[data-reaction="fire"]')!.click();
    await t.stable();
    expect(t.$('[data-reaction-picker]')).toBeNull();
    expect(document.activeElement).toBe(t.$('[data-react]'));
    expect(t.$('[data-react]')!.getAttribute('data-my-reaction')).toBe('fire');
    t.http.expectOne(`${TEST_API}/articles/a1/reaction`).flush({ reactions: { insightful: 6, love: 3, fire: 3, mindBlown: 1 }, total: 13, myReaction: 'fire' });
    await flushMicrotasks();
  });

  it('Escape closes the picker and gives focus back', async () => {
    const t = await render();
    http = t.http;
    t.$('[data-reaction-picker-toggle]')!.click();
    await t.stable();
    expect(t.$('[data-reaction-picker]')).not.toBeNull();
    key(document.activeElement!, 'Escape');
    await t.stable();
    expect(t.$('[data-reaction-picker]')).toBeNull();
    expect(document.activeElement).toBe(t.$('[data-react]'));
  });

  it('save toggles with aria-pressed', async () => {
    const t = await render();
    http = t.http;
    t.$('[data-save]')!.click();
    await t.stable();
    expect(t.$('[data-save]')!.getAttribute('aria-pressed')).toBe('true');
    t.http.expectOne(`${TEST_API}/me/saved/a1`).flush({ isSaved: true, saveCount: 5 });
    await flushMicrotasks();
  });

  it('guests get the sign-in prompt and nothing is sent', async () => {
    const t = await render(testCard(), { guest: true });
    http = t.http;
    const prompt = TestBed.inject(AuthPromptService);
    t.$('[data-react]')!.click();
    expect(prompt.isOpen()).toBe(true);
    prompt.close();
    t.$('[data-save]')!.click();
    expect(prompt.isOpen()).toBe(true);
    await t.stable();
    expect(t.$('[data-react]')!.hasAttribute('data-my-reaction')).toBe(false);
  });

  it('"who reacted" is disabled without reactions', async () => {
    const t = await render(testCard({ reactionCount: 0, reactions: { insightful: 0, love: 0, fire: 0, mindBlown: 0 } }));
    http = t.http;
    expect(t.$<HTMLButtonElement>('[data-reactions-summary]')!.disabled).toBe(true);
  });

  it('Repost sits next to the comments, with its count (F29)', async () => {
    const t = await render(testCard({ repostCount: 3 }));
    http = t.http;
    const repost = t.$('[data-repost]')!;
    expect(t.$('[data-comment-count]')!.nextElementSibling).toBe(repost.closest('rd-repost-button'));
    expect(repost.getAttribute('aria-label')).toBe('إعادة نشر، 3');
    expect(t.$('[data-repost-count]')!.textContent!.trim()).toBe('3');
    repost.click();
    await t.stable();
    expect(repost.getAttribute('aria-pressed')).toBe('true');
    expect(t.$('[data-repost-count]')!.textContent!.trim()).toBe('4');
    t.http.expectOne(`${TEST_API}/articles/a1/repost`).flush({ repostCount: 4, isReposted: true });
    await flushMicrotasks();
  });

  it('the comment count is a button that takes you to the comments (F11)', async () => {
    const t = await render();
    http = t.http;
    const opened = vi.fn();
    t.fixture.componentInstance.commentsOpen.subscribe(opened);
    const button = t.$<HTMLButtonElement>('[data-comment-count]')!;
    expect(button.tagName).toBe('BUTTON');
    expect(button.getAttribute('aria-controls')).toBe('comments');
    expect(button.textContent).toContain('التعليقات');
    button.click();
    expect(opened).toHaveBeenCalledTimes(1);
  });
});
