import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  PLATFORM_ID,
  ViewEncapsulation,
  afterNextRender,
  effect,
  inject,
  input,
  signal,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { LucideDynamicIcon } from '@lucide/angular';
import { LanguageService } from '../../core/i18n/language.service';

/** How much of the visible width one arrow press moves (the rest stays on screen for context). */
const PAGE_RATIO = 0.8;

/**
 * A row of chips that scrolls sideways (the field filters on Home, Paths and Saved). There is no scrollbar: the edges
 * fade where more chips are hidden, and on devices with a mouse round arrow buttons page through the row, in the
 * reading direction. Touch users swipe; keyboard and screen reader users move through the chips themselves, so the
 * arrows stay out of the tab order and the accessibility tree. A chip that gets focus while partly hidden scrolls
 * into view.
 */
@Component({
  selector: 'rd-scroll-row',
  imports: [LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  // Its classes' rules (not in the global stylesheet, so they stay out of the initial bundle).
  encapsulation: ViewEncapsulation.None,
  styleUrl: './scroll-row.css',
  host: { class: 'relative -mx-4 block' },
  template: `
    <div
      #track
      class="rd-scroll-row flex gap-2 overflow-x-auto overscroll-x-contain px-4"
      [class.py-1]="!flush()"
      [class.overflow-y-hidden]="flush()"
      [class.rd-scroll-row-fade-start]="canStart()"
      [class.rd-scroll-row-fade-end]="canEnd()"
      [attr.role]="role()"
      [attr.aria-label]="label()"
      data-scroll-track
      (scroll)="measure()"
      (focusin)="reveal($event)"
    >
      <ng-content />
    </div>
    @if (canStart()) {
      <button type="button" class="rd-scroll-arrow start-2" tabindex="-1" aria-hidden="true" data-scroll-start (click)="page(-1)">
        <svg lucideIcon="ChevronLeft" [size]="18" class="rd-flip-rtl" aria-hidden="true"></svg>
      </button>
    }
    @if (canEnd()) {
      <button type="button" class="rd-scroll-arrow end-2" tabindex="-1" aria-hidden="true" data-scroll-end (click)="page(1)">
        <svg lucideIcon="ChevronRight" [size]="18" class="rd-flip-rtl" aria-hidden="true"></svg>
      </button>
    }
  `,
})
export class ScrollRow {
  /** Accessible name of the row (e.g. "Filter by field"). */
  readonly label = input<string | null>(null);
  readonly role = input<string>('toolbar');
  /**
   * A row of tabs rather than chips (e.g. the profile's, `role="tablist"`): no padding above and below, so the tabs'
   * bottom line is the row's edge, and it never scrolls up and down.
   */
  readonly flush = input(false);

  /** More chips are hidden before the visible part (left in LTR, right in RTL). */
  protected readonly canStart = signal(false);
  /** More chips are hidden after the visible part. */
  protected readonly canEnd = signal(false);

  private readonly track = viewChild.required<ElementRef<HTMLElement>>('track');
  private readonly dir = inject(LanguageService).dir;
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  constructor() {
    const destroyRef = inject(DestroyRef);
    afterNextRender(() => {
      const track = this.track().nativeElement;
      this.measure();
      // Chips arrive after the first render (fields load) and the row resizes with the window: measure again.
      const mutations = new MutationObserver(() => this.measure());
      mutations.observe(track, { childList: true, subtree: true, characterData: true });
      destroyRef.onDestroy(() => mutations.disconnect());
      if (typeof ResizeObserver === 'function') {
        const resizes = new ResizeObserver(() => this.measure());
        resizes.observe(track);
        destroyRef.onDestroy(() => resizes.disconnect());
      }
    });
    // Switching the UI language flips the reading direction, so start and end swap.
    effect(() => {
      this.dir();
      if (this.isBrowser) queueMicrotask(() => this.measure());
    });
  }

  /** Scrolls one page towards the end (1) or the start (-1) of the row, in the reading direction. */
  page(towards: 1 | -1): void {
    const track = this.track().nativeElement;
    const step = Math.max(track.clientWidth * PAGE_RATIO, 1) * towards * (this.dir() === 'rtl' ? -1 : 1);
    if (typeof track.scrollBy === 'function') track.scrollBy({ left: step, behavior: this.behavior() });
    else track.scrollLeft += step;
    this.measure();
  }

  /** Re-reads how far the row is scrolled. In RTL `scrollLeft` runs from 0 down to minus the overflow. */
  protected measure(): void {
    const track = this.track().nativeElement;
    const overflow = track.scrollWidth - track.clientWidth;
    const position = Math.abs(track.scrollLeft);
    this.canStart.set(overflow > 1 && position > 1);
    this.canEnd.set(overflow > 1 && position < overflow - 1);
  }

  /** Brings the chip that just got focus (pressed or tabbed to) fully into view, e.g. a half-hidden chip at the edge. */
  protected reveal(event: FocusEvent): void {
    const chip = (event.target as Element | null)?.closest('button, a');
    if (chip instanceof HTMLElement && typeof chip.scrollIntoView === 'function') {
      chip.scrollIntoView({ block: 'nearest', inline: 'nearest', behavior: this.behavior() });
    }
  }

  private behavior(): ScrollBehavior {
    const reduced = this.isBrowser && typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches;
    return reduced ? 'auto' : 'smooth';
  }
}
