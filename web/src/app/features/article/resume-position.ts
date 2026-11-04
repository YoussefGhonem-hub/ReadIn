import { DOCUMENT, DestroyRef, Injector, PLATFORM_ID, Signal, afterNextRender, computed, effect, inject, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoService } from '@jsverse/transloco';
import { ArticleLanguage, MyProgressDto } from '../../core/api/models';
import { ToastService } from '../../shared/ui/toast/toast.service';

/** The reader scrolls back only to a position between these (contract "Resume (F04)"): not the very top or end. */
export const RESUME_MIN = 0.05;
export const RESUME_MAX = 0.95;
/** Still "at the top" within this many pixels (some browsers settle a fraction of a pixel below 0). */
const TOP_SLACK_PX = 2;
/** Keys that scroll the page: pressing one counts as having scrolled. */
const SCROLL_KEYS = new Set(['ArrowDown', 'ArrowUp', 'PageDown', 'PageUp', 'Home', 'End', ' ']);
const KEY_CONSUMERS = 'input, textarea, select, button, [contenteditable], [role="radio"], [role="tab"]';

export interface ResumableArticle {
  id: string;
  language: ArticleLanguage;
  myProgress: MyProgressDto | null;
}

export interface ResumePosition {
  /**
   * True from the moment an article opens until the reader is placed (scrolled back, or nothing to resume). The
   * reading tracker waits for it: its first report would otherwise save the top of the article over your position.
   */
  readonly pending: Signal<boolean>;
}

/**
 * The scroll fraction to resume at when `article` opens, or null (contract "Resume (F04)"): progress recorded on the
 * version being shown, not read to the end yet, no anchor in the link, and a position from 5% to 95%.
 */
export function resumeFraction(article: ResumableArticle, hasAnchor: boolean): number | null {
  const progress = article.myProgress;
  if (!progress?.lastPosition || progress.completedAt || progress.language !== article.language || hasAnchor) return null;
  const fraction = Number(progress.lastPosition);
  return Number.isFinite(fraction) && fraction >= RESUME_MIN && fraction <= RESUME_MAX ? fraction : null;
}

/**
 * The window scroll offset where the reading tracker's `scrollFraction(el)` reads `fraction`: its inverse, since the
 * tracker measures `-rect.top / (rect.height - viewportHeight)`. Null when the article fits the viewport.
 */
export function scrollTopFor(fraction: number, el: HTMLElement, scrollY: number, viewportHeight: number): number | null {
  const rect = el.getBoundingClientRect();
  const total = rect.height - viewportHeight;
  return total <= 0 ? null : rect.top + scrollY + fraction * total;
}

/**
 * Puts a signed-in reader back where they left off (F04): once the article is rendered and its layout settled, scrolls
 * to `myProgress.lastPosition` and offers "Start over" in a toast. Never during SSR, never after the reader scrolled
 * themselves (or the browser restored a position), never with an anchor in the link. Browser only.
 *
 * Must run in the reader's injection context. `element` is the article the tracker measures; `ownCopy` is false while
 * the page still shows the anonymous copy from SSR and your own (which carries `myProgress`) is on its way.
 */
export function injectResumePosition(
  article: () => ResumableArticle | null,
  element: () => HTMLElement | undefined,
  ownCopy: () => boolean,
): ResumePosition {
  const window = isPlatformBrowser(inject(PLATFORM_ID)) ? inject(DOCUMENT).defaultView : null;
  if (!window) return { pending: signal(false) };
  const toasts = inject(ToastService);
  const transloco = inject(TranslocoService);
  const injector = inject(Injector);

  const opened = computed(() => {
    const current = article();
    return current ? `${current.id}|${current.language}` : null;
  });
  /** The article (and version) the reader has been placed in. */
  const placed = signal<string | null>(null);
  let restoring: string | null = null;

  // Scrolling yourself (wheel, touch, keys; a dragged scrollbar moves `scrollY`) wins over resuming.
  let scrolled = false;
  const markScrolled = () => (scrolled = true);
  const onKey = (event: KeyboardEvent) => {
    // In a field or on a control, those keys type, press or pick rather than scroll.
    const target = event.target instanceof Element ? event.target : null;
    if (SCROLL_KEYS.has(event.key) && !target?.closest(KEY_CONSUMERS)) scrolled = true;
  };
  const options = { capture: true, passive: true } as const;
  window.addEventListener('wheel', markScrolled, options);
  window.addEventListener('touchmove', markScrolled, options);
  window.addEventListener('keydown', onKey, options);
  inject(DestroyRef).onDestroy(() => {
    window.removeEventListener('wheel', markScrolled, options);
    window.removeEventListener('touchmove', markScrolled, options);
    window.removeEventListener('keydown', onKey, options);
  });

  // Another article or version is a new open: scrolling the previous one doesn't count.
  effect(() => {
    opened();
    scrolled = false;
  });

  const restore = async (key: string, fraction: number): Promise<void> => {
    await layoutSettled(window, injector);
    const el = element();
    if (opened() === key && el && !scrolled && window.scrollY <= TOP_SLACK_PX && !window.location.hash) {
      const top = scrollTopFor(fraction, el, window.scrollY, window.innerHeight);
      if (top !== null) {
        window.scrollTo({ top, behavior: 'instant' });
        toasts.info(transloco.translate('article.resume.toast'), null, {
          label: transloco.translate('article.resume.startOver'),
          run: () => startOver(window),
        });
        // The jump's scroll event fires before the next frame, so the tracker (it starts once placed) never sees it.
        await nextFrame(window);
      }
    }
    if (restoring === key) restoring = null;
    if (opened() === key) placed.set(key);
  };

  effect(() => {
    const current = article();
    const key = opened();
    if (!current || !key || placed() === key || restoring === key || !ownCopy()) return;
    const fraction = resumeFraction(current, !!window.location.hash);
    if (fraction === null) {
      placed.set(key);
      return;
    }
    restoring = key;
    untracked(() => void restore(key, fraction));
  });

  return { pending: computed(() => opened() !== null && placed() !== opened()) };
}

/** Resolves once the article has rendered and its layout is final: web fonts loaded (they rewrap text), two frames. */
async function layoutSettled(window: Window, injector: Injector): Promise<void> {
  await new Promise<void>((resolve) => afterNextRender(() => resolve(), { injector }));
  await window.document.fonts?.ready;
  await nextFrame(window);
  await nextFrame(window);
}

function nextFrame(window: Window): Promise<void> {
  return new Promise((resolve) => window.requestAnimationFrame(() => resolve()));
}

function startOver(window: Window): void {
  const reduce = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
  window.scrollTo({ top: 0, behavior: reduce ? 'instant' : 'smooth' });
}
