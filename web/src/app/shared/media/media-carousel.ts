import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  Injector,
  PLATFORM_ID,
  afterNextRender,
  computed,
  inject,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { LanguageService } from '../../core/i18n/language.service';
import { translatePlural } from '../pipes/format.pipes';
import { blurHashAverageColor } from './blurhash';
import { MediaImage } from './media-image';
import { MediaSlide } from './media-slides';

/** Slides with a real `<img>`: the current one and its neighbours; the rest show their BlurHash color. */
const RENDER_RADIUS = 1;
/** Scroll events are ignored while a programmatic scroll is on its way to its target (or until this delay). */
const PROGRAMMATIC_SCROLL_MS = 800;

/**
 * LinkedIn-style carousel (F26) for post images and PDF pages: CSS scroll-snap, the next slide peeks from the edge,
 * counter badge, arrows on hover-capable pointers (hidden at the ends), arrow keys, and native swipe on touch.
 * In RTL it starts from the right and every direction is mirrored (Chromium/Firefox report a negative `scrollLeft`).
 */
@Component({
  selector: 'rd-media-carousel',
  imports: [TranslocoPipe, LucideDynamicIcon, MediaImage],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'rd-carousel relative block' },
  template: `
    <div
      #track
      class="flex snap-x snap-mandatory gap-2 overflow-x-auto overscroll-x-contain [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
      role="region"
      [attr.aria-roledescription]="'media.carousel' | transloco"
      [attr.aria-label]="label()"
      [attr.dir]="dir()"
      data-track
      (keydown)="onKeydown($event)"
      (scroll)="onScroll()"
    >
      @for (slide of slides(); track slide.key; let i = $index) {
        <div
          class="shrink-0 snap-start snap-always"
          [style.width]="slideWidth()"
          role="group"
          [attr.aria-roledescription]="'media.slide' | transloco"
          [attr.aria-label]="slideLabel(slide, i)"
          [attr.aria-current]="i === index() ? 'true' : null"
          data-slide
        >
          <button
            type="button"
            class="block w-full cursor-zoom-in overflow-hidden rounded-md border border-border bg-surface p-0 text-start"
            [attr.tabindex]="i === index() ? 0 : -1"
            [attr.aria-label]="openLabel(slide, i)"
            (click)="select(i)"
            (focus)="onSlideFocus(i)"
          >
            <span class="relative block w-full" [style.aspect-ratio]="aspectRatio()">
              @if (slide.kind === 'more') {
                <span
                  class="absolute inset-0 grid place-items-center bg-primary-container p-4 text-center text-base font-semibold text-on-primary-container"
                  data-more
                  >{{ moreLabel(slide) }}</span
                >
              } @else if (isRendered(i)) {
                <rd-media-image
                  class="absolute inset-0"
                  [variants]="slide.variants"
                  [alt]="slide.alt"
                  [sizes]="sizes()"
                  [blurHash]="slide.blurHash"
                  [ratio]="aspectRatio()"
                  [priority]="priority() && i === 0"
                />
              } @else {
                <span class="absolute inset-0 bg-surface-variant" [style.background-color]="averageColor(slide)" data-placeholder></span>
              }
            </span>
            @if (slide.caption) {
              <span class="block truncate px-3 py-2 text-sm font-semibold text-text-primary" dir="auto">{{ slide.caption }}</span>
            }
          </button>
        </div>
      }
    </div>

    @if (count() > 1) {
      @if (index() > 0) {
        <button type="button" class="rd-carousel-arrow start-2" [attr.aria-label]="'media.previous' | transloco" data-prev (click)="previous()">
          <svg lucideIcon="ChevronLeft" [size]="20" class="rd-flip-rtl" aria-hidden="true"></svg>
        </button>
      }
      @if (index() < count() - 1) {
        <button type="button" class="rd-carousel-arrow end-2" [attr.aria-label]="'media.next' | transloco" data-next (click)="next()">
          <svg lucideIcon="ChevronRight" [size]="20" class="rd-flip-rtl" aria-hidden="true"></svg>
        </button>
      }
      <!-- Top-start corner of the current slide (mirrored in RTL); the digits themselves always read "3 / 12". -->
      <span
        class="pointer-events-none absolute start-2 top-2 z-10 rounded-chip bg-code-bg/80 px-2 py-0.5 text-xs font-semibold text-code-text"
        aria-hidden="true"
        ><bdi dir="ltr" data-counter>{{ counter() }}</bdi></span
      >
    }
  `,
})
export class MediaCarousel {
  private readonly language = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);
  private readonly injector = inject(Injector);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  readonly slides = input.required<MediaSlide[]>();
  /** Width / height shared by every slide. */
  readonly aspectRatio = input(1);
  /** Accessible name of the carousel region. */
  readonly label = input('');
  /** Total items for the counter and slide labels (a PDF's `pageCount` can exceed the slides it carries). */
  readonly total = input<number | null>(null);
  readonly sizes = input('(min-width: 768px) 600px, 85vw');
  /** Loads the first slide eagerly (first visible image of the page). */
  readonly priority = input(false);
  readonly opened = output<number>();

  readonly index = signal(0);
  readonly dir = this.language.dir;
  protected readonly count = computed(() => this.slides().length);
  private readonly itemTotal = computed(() => this.total() ?? this.count());
  protected readonly counter = computed(() => `${Math.min(this.index() + 1, this.itemTotal())} / ${this.itemTotal()}`);
  /** About 15% of the next slide peeks from the edge. */
  protected readonly slideWidth = computed(() => (this.count() > 1 ? 'calc(85% - 8px)' : '100%'));

  private readonly track = viewChild.required<ElementRef<HTMLElement>>('track');
  private scrollTarget: number | null = null;
  private targetTimer: ReturnType<typeof setTimeout> | undefined;
  private frame = 0;

  constructor() {
    const destroyRef = inject(DestroyRef);
    destroyRef.onDestroy(() => {
      clearTimeout(this.targetTimer);
      if (this.frame) cancelAnimationFrame(this.frame);
    });
    afterNextRender(() => {
      const track = this.track().nativeElement;
      const onScrollEnd = () => this.syncFromScroll(true);
      track.addEventListener('scrollend', onScrollEnd);
      destroyRef.onDestroy(() => track.removeEventListener('scrollend', onScrollEnd));
    });
  }

  next(): void {
    this.goTo(this.index() + 1);
  }

  previous(): void {
    this.goTo(this.index() - 1);
  }

  /** Moves to slide `target` (clamped) and scrolls it to the inline start of the track. */
  goTo(target: number, focus = false): void {
    const index = Math.max(0, Math.min(this.count() - 1, target));
    this.index.set(index);
    this.scrollTarget = index;
    clearTimeout(this.targetTimer);
    this.targetTimer = setTimeout(() => (this.scrollTarget = null), PROGRAMMATIC_SCROLL_MS);

    const track = this.track().nativeElement;
    const metrics = this.metrics();
    if (metrics && typeof track.scrollTo === 'function') {
      const left = Math.min(index * metrics.step, metrics.max);
      track.scrollTo({ left: this.dir() === 'rtl' ? -left : left, behavior: this.reducedMotion() ? 'auto' : 'smooth' });
    }
    if (focus) {
      afterNextRender(() => track.querySelectorAll<HTMLElement>('[data-slide] > button')[index]?.focus({ preventScroll: true }), {
        injector: this.injector,
      });
    }
  }

  protected onKeydown(event: KeyboardEvent): void {
    let target: number | null = null;
    if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') {
      // ArrowLeft means "next" when the UI reads right-to-left.
      const forward = (event.key === 'ArrowRight') === (this.dir() === 'ltr');
      target = this.index() + (forward ? 1 : -1);
    } else if (event.key === 'Home') {
      target = 0;
    } else if (event.key === 'End') {
      target = this.count() - 1;
    }
    if (target === null) return;
    event.preventDefault();
    this.goTo(target, true);
  }

  protected onScroll(): void {
    if (this.frame || !this.isBrowser) return;
    this.frame = requestAnimationFrame(() => {
      this.frame = 0;
      this.syncFromScroll(false);
    });
  }

  /** Swipes and wheel scrolling move the index; a programmatic scroll only settles it once it arrives. */
  private syncFromScroll(ended: boolean): void {
    const current = this.indexFromScroll();
    if (current === null) return;
    if (this.scrollTarget !== null && !ended) {
      if (current !== this.scrollTarget) return;
      this.scrollTarget = null;
    }
    if (ended) this.scrollTarget = null;
    this.index.set(current);
  }

  protected onSlideFocus(index: number): void {
    // Keeps the roving tab stop on the slide that actually has focus.
    if (index !== this.index() && this.scrollTarget === null) this.index.set(index);
  }

  protected select(index: number): void {
    if (index !== this.index()) this.goTo(index);
    this.opened.emit(index);
  }

  protected isRendered(index: number): boolean {
    return Math.abs(index - this.index()) <= RENDER_RADIUS;
  }

  protected averageColor(slide: MediaSlide): string | null {
    return blurHashAverageColor(slide.blurHash);
  }

  protected slideLabel(slide: MediaSlide, index: number): string {
    if (slide.kind === 'more') return this.moreLabel(slide);
    const key = slide.kind === 'page' ? 'media.pageOf' : 'media.imageOf';
    return this.transloco.translate(key, { current: index + 1, total: this.itemTotal() }, this.language.lang());
  }

  protected openLabel(slide: MediaSlide, index: number): string {
    if (slide.kind === 'more') return this.moreLabel(slide);
    const label = slide.kind === 'image' && slide.alt ? slide.alt : this.slideLabel(slide, index);
    return this.transloco.translate('media.open', { label }, this.language.lang());
  }

  protected moreLabel(slide: MediaSlide): string {
    return translatePlural(this.transloco, 'media.morePages', slide.moreCount ?? 0, this.language.lang());
  }

  private metrics(): { step: number; position: number; max: number } | null {
    const track = this.track().nativeElement;
    const slides = track.querySelectorAll<HTMLElement>('[data-slide]');
    if (slides.length < 2) return null;
    const step = Math.abs(slides[1].getBoundingClientRect().left - slides[0].getBoundingClientRect().left);
    if (!step) return null;
    return { step, position: Math.abs(track.scrollLeft), max: Math.max(0, track.scrollWidth - track.clientWidth) };
  }

  private indexFromScroll(): number | null {
    const metrics = this.metrics();
    if (!metrics) return null;
    if (metrics.max > 0 && metrics.position >= metrics.max - 2) return this.count() - 1;
    return Math.max(0, Math.min(this.count() - 1, Math.round(metrics.position / metrics.step)));
  }

  private reducedMotion(): boolean {
    return this.isBrowser && typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches;
  }
}
