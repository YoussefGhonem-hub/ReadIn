import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { TEST_API, flushMicrotasks, setupSocialTesting, testCard } from '../../../testing/social-testing';
import { ArticleCardDto } from '../../core/api/models';
import { LanguageService } from '../../core/i18n/language.service';
import { PICK_ANIMATION_MS, ReactionButton, STAGGER_MS } from './reaction-button';

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

async function render(article: ArticleCardDto = testCard(), variant: 'card' | 'bar' = 'card', lang: 'ar' | 'en' = 'ar') {
  const { http } = setupSocialTesting();
  await TestBed.inject(LanguageService).setLanguage(lang);
  const fixture = TestBed.createComponent(ReactionButton);
  fixture.componentRef.setInput('article', article);
  fixture.componentRef.setInput('variant', variant);
  fixture.detectChanges();
  await fixture.whenStable();
  const root = fixture.nativeElement as HTMLElement;
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root.querySelector<T>(selector);
  const stable = async () => {
    await flushMicrotasks();
    fixture.detectChanges();
    await fixture.whenStable();
  };
  return { fixture, root, $, http, stable, wrapper: root.firstElementChild as HTMLElement };
}

function pointer(target: Element, type: string, pointerType: 'mouse' | 'touch'): void {
  target.dispatchEvent(new PointerEvent(type, { pointerType, bubbles: type !== 'pointerenter' && type !== 'pointerleave' }));
}

describe('ReactionButton: the floating reactions bar (F10)', () => {
  let http: HttpTestingController | null = null;

  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => {
    http?.verify();
    vi.unstubAllGlobals();
  });

  it('on the card: the 💡 line icon until you react, then your reaction, with the count beside it', async () => {
    const t = await render(testCard({ myReaction: 'fire' }), 'card', 'en');
    http = t.http;
    const trigger = t.$('[data-react]')!;
    expect(trigger.querySelector('[data-react-icon]')!.textContent!.trim()).toBe('🔥');
    expect(trigger.getAttribute('aria-pressed')).toBe('true');
    expect(trigger.getAttribute('aria-label')).toBe('Reacted: Fire, 12');
    expect(t.$('[data-react-count]')!.textContent!.trim()).toBe('12');
    expect(trigger.textContent).not.toContain('Fire'); // icons only
  });

  it('hovering with a mouse opens the bar after a moment; leaving it closes it', async () => {
    const t = await render();
    http = t.http;
    pointer(t.wrapper, 'pointerenter', 'mouse');
    await t.stable();
    expect(t.$('[data-reaction-picker]')).toBeNull(); // not at once: passing over the button doesn't open it
    await wait(450);
    await t.stable();
    expect(t.$('[data-reaction-picker]')).not.toBeNull();
    // Opened by hover, the focus stays where it was.
    expect(document.activeElement?.hasAttribute('data-reaction')).toBe(false);

    pointer(t.wrapper, 'pointerleave', 'mouse');
    await wait(350);
    await t.stable();
    expect(t.$('[data-reaction-picker]')).toBeNull();
  });

  it('a touch hold opens the bar, and its click is not a tap', async () => {
    const t = await render();
    http = t.http;
    const trigger = t.$('[data-react]')!;
    pointer(trigger, 'pointerdown', 'touch');
    await wait(500);
    await t.stable();
    expect(t.$('[data-reaction-picker]')).not.toBeNull();
    pointer(trigger, 'pointerup', 'touch');
    trigger.click();
    await t.stable();
    t.http.expectNone(`${TEST_API}/articles/a1/reaction`);
    expect(t.$('[data-reaction-picker]')).not.toBeNull();
  });

  it('a hold with no click after it (most phones) doesn’t swallow the next tap', async () => {
    const t = await render();
    http = t.http;
    const trigger = t.$('[data-react]')!;
    pointer(trigger, 'pointerdown', 'touch');
    await wait(500);
    pointer(trigger, 'pointerup', 'touch');
    await t.stable();
    t.$('[data-reaction="love"]')!.click(); // picked from the bar: no click on React
    await wait(PICK_ANIMATION_MS + 20);
    await t.stable();
    t.http.expectOne(`${TEST_API}/articles/a1/reaction`).flush({ reactions: { insightful: 6, love: 4, fire: 2, mindBlown: 1 }, total: 13, myReaction: 'love' });
    await t.stable();

    pointer(trigger, 'pointerdown', 'mouse');
    trigger.click();
    await t.stable();
    expect(trigger.hasAttribute('data-my-reaction')).toBe(false);
    t.http.expectOne(`${TEST_API}/articles/a1/reaction`).flush({ reactions: { insightful: 6, love: 3, fire: 2, mindBlown: 1 }, total: 12, myReaction: null });
    await flushMicrotasks();
  });

  it('a pick plays its animation, then the bar closes and the icon pops', async () => {
    const t = await render();
    http = t.http;
    t.$('[data-react]')!.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowUp', bubbles: true }));
    await t.stable();
    t.$('[data-reaction="love"]')!.click();
    await t.stable();
    expect(t.$('[data-reaction-picker]')!.getAttribute('data-picked')).toBe('love');
    // The choice is made at once (optimistic); only the bar waits for the animation.
    expect(t.$('[data-react]')!.getAttribute('data-my-reaction')).toBe('love');
    t.http.expectOne(`${TEST_API}/articles/a1/reaction`).flush({ reactions: { insightful: 6, love: 4, fire: 2, mindBlown: 1 }, total: 13, myReaction: 'love' });
    // A second pick while it plays is ignored.
    t.$('[data-reaction="fire"]')!.click();
    await wait(PICK_ANIMATION_MS + 20);
    await t.stable();
    expect(t.$('[data-reaction-picker]')).toBeNull();
    expect(t.$('[data-react-icon]')!.classList).toContain('is-popping');
    expect(t.$('[data-react]')!.getAttribute('data-my-reaction')).toBe('love');
    t.http.expectNone(`${TEST_API}/articles/a1/reaction`);
  });

  it('with reduce motion the pick is instant: no animation, the bar closes at once', async () => {
    vi.stubGlobal('matchMedia', (query: string) => ({ matches: query.includes('reduce'), media: query, addEventListener: () => undefined, removeEventListener: () => undefined }));
    const t = await render();
    http = t.http;
    t.$('[data-react]')!.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowUp', bubbles: true }));
    await t.stable();
    t.$('[data-reaction="mindBlown"]')!.click();
    await t.stable();
    expect(t.$('[data-reaction-picker]')).toBeNull();
    expect(t.$('[data-react-icon]')!.classList).not.toContain('is-popping');
    t.http.expectOne(`${TEST_API}/articles/a1/reaction`).flush({ reactions: { insightful: 6, love: 3, fire: 2, mindBlown: 2 }, total: 13, myReaction: 'mindBlown' });
    await flushMicrotasks();
  });

  it('the bar’s own styles: staggered entry, grow and lift under the pointer, all off with reduce motion', async () => {
    const t = await render();
    http = t.http;
    t.$('[data-react]')!.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowUp', bubbles: true }));
    await t.stable();
    const delays = [...t.root.querySelectorAll<HTMLElement>('[data-reaction]')].map((b) => b.style.animationDelay);
    expect(delays).toEqual([0, 1, 2, 3].map((i) => `${i * STAGGER_MS}ms`));
    const styles = (ReactionButton as unknown as { ɵcmp: { styles: string[] } }).ɵcmp.styles.join('\n');
    expect(styles).toMatch(/\.reaction\[[^{]*\{[^}]*animation:\s*\S*reaction-in/); // keyframe names are scoped by Angular
    expect(styles).toMatch(/:hover[^{]*\{[^}]*translateY\(-8px\)\s*scale\(1\.45\)/);
    expect(styles).toMatch(/prefers-reduced-motion:\s*reduce/);
  });
});
