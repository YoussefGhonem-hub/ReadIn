import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  afterNextRender,
  inject,
  viewChild,
} from '@angular/core';

/** Resting on an element this long shows its tooltip (the browser's own takes about a second). */
export const TOOLTIP_DELAY_MS = 450;
/** Moving to another element this soon after a tooltip closed shows the next one at once (toolbars, icon rows). */
export const TOOLTIP_WARM_MS = 400;
/** Space between the element and the tooltip, and the least space kept from the window's edges, in px. */
const GAP = 8;
const EDGE = 8;
/** The tooltip's id, for the element's `aria-describedby`. */
export const TOOLTIP_ID = 'rd-tooltip';
/** Keys that move the focus (Shift+Tab comes as Shift, then Tab). */
const NAVIGATION_KEYS = new Set([
  'Tab',
  'ArrowUp',
  'ArrowDown',
  'ArrowLeft',
  'ArrowRight',
  'Home',
  'End',
  'PageUp',
  'PageDown',
]);

interface Active {
  el: Element;
  text: string;
  /** Put the `title` back when the tooltip closes (false once the app removed it, or the element left the page). */
  restore: boolean;
  /** We named the element with `aria-label`, because its title was its only name. */
  labelled: boolean;
  /** The element's own `aria-describedby` before the tooltip joined it; undefined while not added. */
  describedBy?: string | null;
  observer: MutationObserver | null;
}

/**
 * The site's tooltip (one design for every page). Elements keep the plain `title` attribute, and this shows it as a
 * styled tooltip instead of the browser's: after a short rest of the mouse or pen on the element, or at once when the
 * keyboard focuses it. It closes on leave, blur, click, scroll and Escape.
 *
 * While the pointer or focus is on the element, its `title` comes off (or the browser would show its own as well) and
 * goes back afterwards. The tooltip describes the element meanwhile (`aria-describedby`), and an element named only
 * by its title gets that text as `aria-label`, so screen readers lose nothing. Touch has no hover: taps show nothing,
 * as before. `data-rd-tip="off"` keeps the browser's tooltip on an element.
 */
@Component({
  selector: 'rd-tooltip-host',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: `
    .tip {
      position: fixed;
      z-index: 100;
      top: 0;
      left: 0;
      max-width: min(280px, calc(100vw - 16px));
      padding: 6px 10px;
      border-radius: var(--rd-radius-sm);
      background: var(--rd-color-text-primary);
      color: var(--rd-color-surface);
      box-shadow:
        0 6px 18px rgb(0 0 0 / 0.18),
        0 1px 3px rgb(0 0 0 / 0.12);
      font-family: var(--rd-font-ui);
      font-size: var(--rd-text-caption-size);
      font-weight: 500;
      line-height: 1.45;
      overflow-wrap: anywhere;
      white-space: pre-line;
      pointer-events: none;
      opacity: 0;
      transform: translateY(var(--rd-tip-shift, 3px));
      transition:
        opacity 120ms ease-out,
        transform 120ms ease-out;
    }
    .tip[data-side='below'] {
      --rd-tip-shift: -3px;
    }
    .tip.shown {
      opacity: 1;
      transform: none;
    }
    /* The arrow: a small square turned 45°, under the text, pointing at the element's centre. */
    .tip::after {
      content: '';
      position: absolute;
      left: var(--rd-tip-arrow, 50%);
      width: 8px;
      height: 8px;
      margin-left: -4px;
      background: inherit;
      transform: rotate(45deg);
    }
    .tip[data-side='above']::after {
      bottom: -4px;
      border-bottom-right-radius: 2px;
    }
    .tip[data-side='below']::after {
      top: -4px;
      border-top-left-radius: 2px;
    }
    @media (prefers-reduced-motion: reduce) {
      .tip {
        transition: none;
        transform: none;
      }
    }
  `,
  template: `<div #tip [id]="id" role="tooltip" class="tip" dir="auto" hidden data-tooltip></div>`,
})
export class TooltipHost {
  protected readonly id = TOOLTIP_ID;
  private readonly tip = viewChild<ElementRef<HTMLElement>>('tip');

  private active: Active | null = null;
  private showTimer: ReturnType<typeof setTimeout> | undefined;
  private watch: ReturnType<typeof setInterval> | undefined;
  private shown = false;
  private closedAt = 0;
  /** The element just clicked: no tooltip again until the pointer leaves it. */
  private quiet: Element | null = null;
  /** The last input was a navigation key (focus from Tab or the arrows shows the tooltip; from a click it doesn't). */
  private keyboard = false;

  constructor() {
    const destroyRef = inject(DestroyRef);
    afterNextRender(() => {
      const listeners: [string, (event: Event) => void][] = [
        ['pointerover', (e) => this.pointerOver(e as PointerEvent)],
        ['pointerout', (e) => this.pointerOut(e as PointerEvent)],
        ['pointerdown', (e) => this.pointerDown(e as PointerEvent)],
        ['keydown', (e) => this.keyDown(e as KeyboardEvent)],
        ['focusin', (e) => this.focusIn(e)],
        [
          'focusout',
          (e) => {
            if (this.inside(e.target)) this.close();
          },
        ],
        ['scroll', () => this.close()],
      ];
      for (const [type, listener] of listeners) document.addEventListener(type, listener, true);
      const blur = () => this.close();
      window.addEventListener('blur', blur);
      window.addEventListener('resize', blur);
      destroyRef.onDestroy(() => {
        for (const [type, listener] of listeners)
          document.removeEventListener(type, listener, true);
        window.removeEventListener('blur', blur);
        window.removeEventListener('resize', blur);
        this.close();
      });
    });
  }

  private pointerOver(event: PointerEvent): void {
    if (event.pointerType === 'touch' || this.inside(event.target)) return;
    const el = triggerOf(event.target);
    if (!el || el === this.active?.el || el === this.quiet) return;
    this.open(el, Date.now() - this.closedAt < TOOLTIP_WARM_MS ? 0 : TOOLTIP_DELAY_MS);
  }

  private pointerOut(event: PointerEvent): void {
    const to = event.relatedTarget as Node | null;
    if (this.quiet && !(to && this.quiet.contains(to))) this.quiet = null;
    const active = this.active;
    if (active && !(to && active.el.contains(to)) && !active.el.contains(document.activeElement))
      this.close();
  }

  private pointerDown(event: PointerEvent): void {
    this.keyboard = false;
    const el = this.active?.el;
    if (el) {
      this.close();
      if (event.target instanceof Node && el.contains(event.target)) this.quiet = el;
    }
  }

  private keyDown(event: KeyboardEvent): void {
    // Only keys that move the focus: after typing, Enter or Escape, focus the app moves itself (a menu giving it back
    // to its button) shows nothing.
    this.keyboard = NAVIGATION_KEYS.has(event.key);
    if (event.key === 'Escape' && this.shown) this.close();
  }

  private focusIn(event: Event): void {
    if (!this.keyboard || this.inside(event.target)) return;
    const el = triggerOf(event.target);
    if (el && el !== this.active?.el) this.open(el, 0);
  }

  /** Still on the element whose title we hold (its title is off, so `closest` would look past it). */
  private inside(target: EventTarget | null): boolean {
    return !!this.active && target instanceof Node && this.active.el.contains(target);
  }

  /** Takes the element's title right away (so the browser never shows its own) and shows ours after `delay`. */
  private open(el: Element, delay: number): void {
    this.close();
    const text = el.getAttribute('title');
    if (!text?.trim()) return;
    el.removeAttribute('title');

    const named =
      el.hasAttribute('aria-label') ||
      el.hasAttribute('aria-labelledby') ||
      !!el.textContent?.trim();
    if (!named) el.setAttribute('aria-label', text);
    const active: Active = { el, text, restore: true, labelled: !named, observer: null };
    this.active = active;

    // The app may change or remove the title while we hold it (a binding that updates): follow it.
    if (typeof MutationObserver === 'function') {
      active.observer = new MutationObserver(() => this.titleChanged(active));
      active.observer.observe(el, { attributes: true, attributeFilter: ['title'] });
    }
    this.showTimer = setTimeout(() => this.show(), delay);
  }

  private titleChanged(active: Active): void {
    if (this.active !== active) return;
    const title = active.el.getAttribute('title');
    if (title === null) return; // our own removal
    active.el.removeAttribute('title');
    active.observer?.takeRecords();
    if (!title.trim()) {
      active.restore = false;
      this.close();
      return;
    }
    active.text = title;
    if (active.labelled) active.el.setAttribute('aria-label', title);
    if (this.shown) this.show();
  }

  private show(): void {
    const active = this.active;
    if (!active) return;
    if (!active.el.isConnected) {
      active.restore = false;
      this.close();
      return;
    }
    const tip = this.tip()?.nativeElement;
    if (!tip) return;
    tip.textContent = active.text;
    tip.hidden = false;
    this.place(active.el, tip);

    // Describe the element by the tooltip, unless the tooltip only repeats the element's name.
    const name = (active.el.getAttribute('aria-label') ?? active.el.textContent ?? '').trim();
    if (active.describedBy === undefined && name !== active.text.trim()) {
      active.describedBy = active.el.getAttribute('aria-describedby');
      active.el.setAttribute(
        'aria-describedby',
        active.describedBy ? `${active.describedBy} ${TOOLTIP_ID}` : TOOLTIP_ID,
      );
    }
    this.shown = true;
    // The element can leave the page without any event (a list re-rendered under the pointer).
    this.watch ??= setInterval(() => {
      if (this.active && !this.active.el.isConnected) {
        this.active.restore = false;
        this.close();
      }
    }, 300);
  }

  /** Above the element, or below it when there's no room; centred on it, inside the window. */
  private place(el: Element, tip: HTMLElement): void {
    tip.classList.remove('shown');
    const rect = el.getBoundingClientRect();
    const width = tip.offsetWidth;
    const height = tip.offsetHeight;
    const viewportWidth = document.documentElement.clientWidth || window.innerWidth;
    const centre = rect.left + rect.width / 2;
    const left = Math.round(
      Math.min(Math.max(centre - width / 2, EDGE), Math.max(EDGE, viewportWidth - width - EDGE)),
    );
    const below = rect.top - height - GAP < EDGE;
    const top = Math.round(below ? rect.bottom + GAP : rect.top - height - GAP);
    tip.style.left = `${left}px`;
    tip.style.top = `${top}px`;
    tip.style.setProperty(
      '--rd-tip-arrow',
      `${Math.round(Math.min(Math.max(centre - left, 12), Math.max(12, width - 12)))}px`,
    );
    tip.dataset['side'] = below ? 'below' : 'above';
    // Next frame, so the fade starts from the new place.
    const fadeIn = () => {
      if (this.shown && !tip.hidden) tip.classList.add('shown');
    };
    if (typeof requestAnimationFrame === 'function') requestAnimationFrame(fadeIn);
    else setTimeout(fadeIn);
  }

  /** Hides the tooltip and gives the element back its title and attributes. */
  private close(): void {
    clearTimeout(this.showTimer);
    clearInterval(this.watch);
    this.watch = undefined;
    const active = this.active;
    this.active = null;
    if (this.shown) this.closedAt = Date.now();
    this.shown = false;
    const tip = this.tip()?.nativeElement;
    if (tip) {
      tip.classList.remove('shown');
      tip.hidden = true;
    }
    if (!active) return;

    active.observer?.disconnect();
    const { el } = active;
    if (active.describedBy !== undefined) {
      if (active.describedBy) el.setAttribute('aria-describedby', active.describedBy);
      else el.removeAttribute('aria-describedby');
    }
    if (active.labelled && el.getAttribute('aria-label') === active.text)
      el.removeAttribute('aria-label');
    if (active.restore && el.isConnected && !el.hasAttribute('title'))
      el.setAttribute('title', active.text);
  }
}

/** The element whose title the event is about: the nearest one with a title, unless it opted out. */
function triggerOf(target: EventTarget | null): Element | null {
  if (!(target instanceof Element)) return null;
  const el = target.closest('[title]');
  if (!el || el instanceof HTMLIFrameElement || el.closest('[data-rd-tip="off"]')) return null;
  return el;
}
