import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  Injector,
  PLATFORM_ID,
  Signal,
  afterNextRender,
  computed,
  effect,
  inject,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { DIALOG_DATA, DialogRef } from '@angular/cdk/dialog';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { DocumentDownloader } from './document-download';
import { MediaImage } from './media-image';
import { MediaSlide } from './media-slides';

export interface MediaViewerDocument {
  title: string;
  canDownload: boolean;
  downloadUrl: string;
}

/** What the full-screen viewer shows. `items` is a signal so a document opened from the feed can load its other pages. */
export interface MediaViewerData {
  kind: 'images' | 'document';
  /** Dialog name: the document title, or the post title for images. */
  title: string;
  items: Signal<MediaSlide[]>;
  /** Items in the set (a document's `pageCount`), which can exceed the items loaded so far. */
  total: number;
  startIndex: number;
  document: MediaViewerDocument | null;
  share: { title: string; url: string };
}

const MAX_ZOOM = 4;
const DOUBLE_TAP_ZOOM = 2.5;
const DOUBLE_TAP_MS = 300;
const SWIPE_PX = 60;
const CLOSE_SWIPE_PX = 110;
const NOTICE_MS = 2500;

interface Point {
  x: number;
  y: number;
}

interface Gesture {
  kind: 'swipe' | 'pan' | 'pinch';
  pointerType: string;
  start: Point;
  startTx: number;
  startTy: number;
  startScale: number;
  startDistance: number;
}

/**
 * Full-screen viewer for post images and PDF pages (F26), opened through `MediaViewerService` as a CDK dialog
 * (focus trap, Escape, focus restore). Swipe / arrows / arrow keys between items, pinch and double-tap or
 * double-click zoom, swipe down to close on touch, counter, PDF thumbnail strip, download (when allowed) and share.
 * The overlay uses the code-block surface, which is dark in both themes.
 */
@Component({
  selector: 'rd-media-viewer',
  imports: [TranslocoPipe, LucideDynamicIcon, MediaImage],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'rd-viewer relative flex h-full w-full flex-col bg-code-bg text-code-text',
    '[attr.dir]': 'dir()',
    '[style.opacity]': 'closeProgress()',
    '(keydown)': 'onKeydown($event)',
  },
  template: `
    <header class="flex items-center gap-2 px-2 py-2 sm:px-4">
      <button type="button" class="rd-viewer-btn" [attr.aria-label]="'common.close' | transloco" data-viewer-close (click)="close()">
        <svg lucideIcon="X" [size]="22" aria-hidden="true"></svg>
      </button>
      <h2 class="m-0 min-w-0 flex-1 truncate text-sm font-semibold" dir="auto">{{ data.title }}</h2>
      <span class="shrink-0 px-1 text-sm font-semibold tabular-nums" dir="ltr" aria-hidden="true" data-viewer-counter>{{ counter() }}</span>
      @if (data.document?.canDownload) {
        <button type="button" class="rd-viewer-btn gap-1.5 px-3" [disabled]="downloading()" data-viewer-download (click)="download()">
          <svg lucideIcon="Download" [size]="18" aria-hidden="true"></svg>
          <span class="hidden text-sm font-semibold sm:inline">{{
            (downloading() ? 'media.viewer.downloading' : 'media.viewer.download') | transloco
          }}</span>
          <span class="sr-only sm:hidden">{{ 'media.viewer.download' | transloco }}</span>
        </button>
      }
      <button type="button" class="rd-viewer-btn gap-1.5 px-3" data-viewer-share (click)="share()">
        <svg lucideIcon="Share2" [size]="18" aria-hidden="true"></svg>
        <span class="hidden text-sm font-semibold sm:inline">{{ 'media.viewer.share' | transloco }}</span>
        <span class="sr-only sm:hidden">{{ 'media.viewer.share' | transloco }}</span>
      </button>
    </header>

    <div
      #stage
      class="relative min-h-0 flex-1 cursor-grab touch-none select-none overflow-hidden [container-type:size]"
      data-viewer-stage
      (pointerdown)="onPointerDown($event)"
      (pointermove)="onPointerMove($event)"
      (pointerup)="onPointerUp($event)"
      (pointercancel)="onPointerUp($event)"
      (dblclick)="onDoubleClick($event)"
    >
      <div class="flex h-full" [class.rd-viewer-track-animated]="!dragging()" [style.transform]="trackTransform()" [attr.dir]="dir()">
        @for (item of slots(); track slotKey(item, i); let i = $index) {
          <div
            class="grid h-full w-full shrink-0 place-items-center overflow-hidden p-2"
            role="group"
            [attr.aria-roledescription]="'media.slide' | transloco"
            [attr.aria-label]="itemLabel(i)"
            [attr.aria-hidden]="i === index() ? null : 'true'"
            [attr.data-viewer-item]="i"
          >
            @if (item) {
              @if (isRendered(i)) {
                <div
                  class="relative"
                  [class.rd-viewer-zoom-animated]="!pinching()"
                  [style.aspect-ratio]="item.ratio"
                  [style.width]="fitWidth(item)"
                  [style.transform]="i === index() ? zoomTransform() : null"
                  [attr.data-viewer-current]="i === index() ? '' : null"
                >
                  <rd-media-image
                    class="absolute inset-0"
                    [variants]="item.viewVariants"
                    pick="largest"
                    fit="contain"
                    sizes="100vw"
                    [blurHash]="item.blurHash"
                    [ratio]="item.ratio"
                    [alt]="item.alt"
                  />
                </div>
              }
            } @else {
              <span class="inline-flex items-center gap-2 text-sm">
                <svg lucideIcon="LoaderCircle" [size]="18" class="animate-spin" aria-hidden="true"></svg>
                {{ 'media.viewer.loadingPage' | transloco }}
              </span>
            }
          </div>
        }
      </div>

      @if (index() > 0) {
        <button type="button" class="rd-viewer-arrow start-3" [attr.aria-label]="'media.previous' | transloco" data-viewer-prev (click)="goTo(index() - 1)">
          <svg lucideIcon="ChevronLeft" [size]="24" class="rd-flip-rtl" aria-hidden="true"></svg>
        </button>
      }
      @if (index() < data.total - 1) {
        <button type="button" class="rd-viewer-arrow end-3" [attr.aria-label]="'media.next' | transloco" data-viewer-next (click)="goTo(index() + 1)">
          <svg lucideIcon="ChevronRight" [size]="24" class="rd-flip-rtl" aria-hidden="true"></svg>
        </button>
      }
    </div>

    @if (current()?.caption; as caption) {
      <p class="m-0 px-4 py-2 text-center text-sm font-semibold" dir="auto">{{ caption }}</p>
    }

    @if (data.kind === 'document') {
      <nav
        #strip
        class="flex shrink-0 gap-2 overflow-x-auto px-3 pt-1 pb-[max(0.75rem,env(safe-area-inset-bottom))] [scrollbar-width:thin]"
        [attr.aria-label]="'media.viewer.thumbnails' | transloco"
        data-viewer-thumbnails
      >
        @for (page of data.items(); track page.key; let i = $index) {
          <button
            type="button"
            class="rd-viewer-thumb"
            [class.is-current]="i === index()"
            [style.aspect-ratio]="page.ratio"
            [attr.aria-label]="itemLabel(i)"
            [attr.aria-current]="i === index() ? 'true' : null"
            (click)="goTo(i)"
          >
            <rd-media-image class="h-full w-full" [variants]="page.variants" sizes="48px" [blurHash]="page.blurHash" [ratio]="page.ratio" />
          </button>
        }
      </nav>
    }

    <p class="sr-only" aria-live="polite" aria-atomic="true">{{ itemLabel(index()) }}</p>
    <p class="sr-only">{{ 'media.viewer.zoomHint' | transloco }}</p>
    @if (notice(); as message) {
      <p
        class="absolute inset-x-4 bottom-24 z-20 mx-auto max-w-sm rounded-md border border-border bg-surface-raised px-4 py-3 text-center text-sm text-text-primary shadow-raised"
        role="status"
        dir="auto"
        data-viewer-notice
      >
        {{ message }}
      </p>
    }
  `,
})
export class MediaViewer {
  protected readonly data = inject<MediaViewerData>(DIALOG_DATA);
  private readonly dialogRef = inject<DialogRef<void, MediaViewer>>(DialogRef);
  private readonly downloader = inject(DocumentDownloader);
  private readonly errors = inject(ErrorMessages);
  private readonly language = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);
  private readonly injector = inject(Injector);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  protected readonly dir = this.language.dir;
  readonly index = signal(Math.max(0, Math.min(this.data.total - 1, this.data.startIndex)));
  /** One slot per item in the set; `null` until that page is loaded. */
  protected readonly slots = computed<(MediaSlide | null)[]>(() =>
    Array.from({ length: this.data.total }, (_, i) => this.data.items()[i] ?? null),
  );
  protected readonly current = computed<MediaSlide | null>(() => this.slots()[this.index()] ?? null);
  protected readonly counter = computed(() => `${this.index() + 1} / ${this.data.total}`);

  protected readonly scale = signal(1);
  private readonly tx = signal(0);
  private readonly ty = signal(0);
  private readonly dragX = signal(0);
  private readonly dragY = signal(0);
  protected readonly dragging = signal(false);
  protected readonly pinching = signal(false);
  protected readonly downloading = signal(false);
  protected readonly notice = signal<string | null>(null);

  protected readonly zoomTransform = computed(() =>
    this.scale() === 1 && !this.tx() && !this.ty() ? null : `translate(${this.tx()}px, ${this.ty()}px) scale(${this.scale()})`,
  );
  protected readonly trackTransform = computed(() => {
    const offset = (this.dir() === 'rtl' ? 1 : -1) * this.index() * 100;
    return `translate3d(calc(${offset}% + ${this.dragX()}px), ${this.dragY()}px, 0)`;
  });
  /** Swiping down fades the viewer as feedback before it closes. */
  protected readonly closeProgress = computed(() => (this.dragY() > 0 ? Math.max(0.35, 1 - this.dragY() / 400) : null));

  private readonly stage = viewChild.required<ElementRef<HTMLElement>>('stage');
  private readonly strip = viewChild<ElementRef<HTMLElement>>('strip');
  private readonly pointers = new Map<number, Point>();
  private gesture: Gesture | null = null;
  private lastTap = { time: 0, x: 0, y: 0 };
  private lastZoomToggle = 0;
  private noticeTimer: ReturnType<typeof setTimeout> | undefined;

  constructor() {
    inject(DestroyRef).onDestroy(() => clearTimeout(this.noticeTimer));
    // New item: reset the zoom and keep its thumbnail in view.
    effect(() => {
      const index = this.index();
      untracked(() => this.resetZoom());
      afterNextRender(
        () => {
          const thumb = this.strip()?.nativeElement.children.item(index) as HTMLElement | null;
          thumb?.scrollIntoView?.({ block: 'nearest', inline: 'center', behavior: this.reducedMotion() ? 'auto' : 'smooth' });
        },
        { injector: this.injector },
      );
    });
  }

  close(): void {
    this.dialogRef.close();
  }

  goTo(target: number): void {
    this.index.set(Math.max(0, Math.min(this.data.total - 1, target)));
  }

  protected slotKey(item: MediaSlide | null, index: number): string {
    return item?.key ?? `slot-${index}`;
  }

  protected isRendered(index: number): boolean {
    return Math.abs(index - this.index()) <= 1;
  }

  /** Largest box with the item's ratio that fits the stage (container query units, no JS measuring). */
  protected fitWidth(item: MediaSlide): string {
    return `min(calc(100cqw - 1rem), calc((100cqh - 1rem) * ${item.ratio}))`;
  }

  protected itemLabel(index: number): string {
    const key = this.data.kind === 'document' ? 'media.pageOf' : 'media.imageOf';
    return this.transloco.translate(key, { current: index + 1, total: this.data.total }, this.language.lang());
  }

  // ── Keyboard ─────────────────────────────────────────────

  protected onKeydown(event: KeyboardEvent): void {
    const target = event.target as HTMLElement | null;
    if (target?.closest('[data-viewer-thumbnails]') && (event.key === 'Enter' || event.key === ' ')) return;
    switch (event.key) {
      case 'ArrowLeft':
      case 'ArrowRight': {
        const forward = (event.key === 'ArrowRight') === (this.dir() === 'ltr');
        this.goTo(this.index() + (forward ? 1 : -1));
        break;
      }
      case 'Home':
        this.goTo(0);
        break;
      case 'End':
        this.goTo(this.data.total - 1);
        break;
      case '+':
      case '=':
        this.zoomTo(Math.min(MAX_ZOOM, this.scale() + 0.5));
        break;
      case '-':
        this.zoomTo(Math.max(1, this.scale() - 0.5));
        break;
      case '0':
        this.resetZoom();
        break;
      default:
        return;
    }
    event.preventDefault();
  }

  // ── Pointer gestures: swipe, pan, pinch, double tap ─────────────

  protected onPointerDown(event: PointerEvent): void {
    if (event.pointerType === 'mouse' && event.button !== 0) return;
    if ((event.target as HTMLElement | null)?.closest('button')) return;
    this.stage().nativeElement.setPointerCapture?.(event.pointerId);
    this.pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
    if (this.pointers.size >= 2) {
      const [a, b] = [...this.pointers.values()];
      this.gesture = { ...this.gestureBase(event, a), kind: 'pinch', startDistance: distance(a, b) || 1 };
      this.pinching.set(true);
      this.dragX.set(0);
      this.dragY.set(0);
    } else {
      this.gesture = { ...this.gestureBase(event, { x: event.clientX, y: event.clientY }), kind: this.scale() > 1 ? 'pan' : 'swipe' };
    }
  }

  protected onPointerMove(event: PointerEvent): void {
    if (!this.pointers.has(event.pointerId) || !this.gesture) return;
    this.pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
    const gesture = this.gesture;
    const dx = event.clientX - gesture.start.x;
    const dy = event.clientY - gesture.start.y;

    if (gesture.kind === 'pinch' && this.pointers.size >= 2) {
      const [a, b] = [...this.pointers.values()];
      const scale = Math.min(MAX_ZOOM, Math.max(1, (gesture.startScale * distance(a, b)) / gesture.startDistance));
      this.scale.set(scale);
      this.clampPan(this.tx(), this.ty());
    } else if (gesture.kind === 'pan') {
      this.clampPan(gesture.startTx + dx, gesture.startTy + dy);
    } else if (gesture.kind === 'swipe') {
      this.dragging.set(true);
      if (Math.abs(dx) >= Math.abs(dy)) {
        const forward = (dx < 0) === (this.dir() === 'ltr');
        const atEnd = forward ? this.index() >= this.data.total - 1 : this.index() <= 0;
        this.dragX.set(atEnd ? dx / 3 : dx);
        this.dragY.set(0);
      } else if (dy > 0 && gesture.pointerType !== 'mouse') {
        this.dragY.set(dy);
        this.dragX.set(0);
      }
    }
  }

  protected onPointerUp(event: PointerEvent): void {
    if (!this.pointers.delete(event.pointerId)) return;
    const gesture = this.gesture;
    if (!gesture) return;

    if (gesture.kind === 'pinch') {
      if (this.pointers.size === 1) {
        // One finger left: continue as a pan from here.
        const [rest] = [...this.pointers.values()];
        this.gesture = { ...this.gestureBase(event, rest), kind: this.scale() > 1 ? 'pan' : 'swipe' };
      } else if (this.pointers.size === 0) {
        this.gesture = null;
        this.pinching.set(false);
        if (this.scale() <= 1.02) this.resetZoom();
      }
      return;
    }

    if (this.pointers.size > 0) return;
    this.gesture = null;
    const dx = event.clientX - gesture.start.x;
    const dy = event.clientY - gesture.start.y;

    if (gesture.kind === 'swipe') {
      this.dragging.set(false);
      this.dragX.set(0);
      this.dragY.set(0);
      if (Math.abs(dx) > SWIPE_PX && Math.abs(dx) > Math.abs(dy)) {
        const forward = (dx < 0) === (this.dir() === 'ltr');
        this.goTo(this.index() + (forward ? 1 : -1));
        return;
      }
      if (gesture.pointerType !== 'mouse' && dy > CLOSE_SWIPE_PX && dy > Math.abs(dx)) {
        this.close();
        return;
      }
    }

    // A tap: two in quick succession toggle zoom (touch; mice use dblclick).
    if (gesture.pointerType !== 'mouse' && Math.abs(dx) < 10 && Math.abs(dy) < 10) {
      const now = Date.now();
      if (now - this.lastTap.time < DOUBLE_TAP_MS && distance(this.lastTap, { x: event.clientX, y: event.clientY }) < 30) {
        this.lastTap = { time: 0, x: 0, y: 0 };
        this.toggleZoom(event.clientX, event.clientY);
      } else {
        this.lastTap = { time: now, x: event.clientX, y: event.clientY };
      }
    }
  }

  protected onDoubleClick(event: MouseEvent): void {
    if ((event.target as HTMLElement | null)?.closest('button')) return;
    this.toggleZoom(event.clientX, event.clientY);
  }

  private gestureBase(event: PointerEvent, start: Point): Omit<Gesture, 'kind'> {
    return {
      pointerType: event.pointerType,
      start,
      startTx: this.tx(),
      startTy: this.ty(),
      startScale: this.scale(),
      startDistance: 1,
    };
  }

  private toggleZoom(clientX: number, clientY: number): void {
    const now = Date.now();
    if (now - this.lastZoomToggle < 350) return; // a double tap can also produce a dblclick
    this.lastZoomToggle = now;
    if (this.scale() > 1) {
      this.resetZoom();
      return;
    }
    const rect = this.stage().nativeElement.getBoundingClientRect();
    const scale = DOUBLE_TAP_ZOOM;
    this.scale.set(scale);
    // Keep the tapped point under the finger: t = d * (1 - s), d = offset from the center.
    this.clampPan((clientX - (rect.left + rect.width / 2)) * (1 - scale), (clientY - (rect.top + rect.height / 2)) * (1 - scale));
  }

  private zoomTo(scale: number): void {
    this.scale.set(scale);
    if (scale <= 1) this.resetZoom();
    else this.clampPan(this.tx(), this.ty());
  }

  private resetZoom(): void {
    this.scale.set(1);
    this.tx.set(0);
    this.ty.set(0);
  }

  /** Pans within the zoomed image so it never leaves the stage. */
  private clampPan(x: number, y: number): void {
    const stage = this.stage().nativeElement;
    const item = stage.querySelector<HTMLElement>('[data-viewer-current]');
    const scale = this.scale();
    const maxX = item ? Math.max(0, (item.offsetWidth * scale - stage.clientWidth) / 2) : 0;
    const maxY = item ? Math.max(0, (item.offsetHeight * scale - stage.clientHeight) / 2) : 0;
    this.tx.set(Math.max(-maxX, Math.min(maxX, x)));
    this.ty.set(Math.max(-maxY, Math.min(maxY, y)));
  }

  // ── Actions ──────────────────────────────────────────────

  /** Downloads the original (bearer token included) and saves it under the document title. */
  protected async download(): Promise<void> {
    const doc = this.data.document;
    if (!doc?.canDownload || this.downloading()) return;
    this.downloading.set(true);
    try {
      await this.downloader.download(doc);
    } catch (error) {
      this.showNotice(this.errors.forError(error));
    } finally {
      this.downloading.set(false);
    }
  }

  /** Web Share API when available, otherwise copy the post link. */
  protected async share(): Promise<void> {
    if (!this.isBrowser) return;
    const { title, url } = this.data.share;
    try {
      if (typeof navigator.share === 'function') {
        await navigator.share({ title, url });
        return;
      }
      await navigator.clipboard.writeText(url);
      this.showNotice(this.transloco.translate('common.linkCopied'));
    } catch {
      /* share sheet dismissed or clipboard blocked */
    }
  }

  private showNotice(message: string): void {
    clearTimeout(this.noticeTimer);
    this.notice.set(message);
    this.noticeTimer = setTimeout(() => this.notice.set(null), NOTICE_MS);
  }

  private reducedMotion(): boolean {
    return this.isBrowser && typeof matchMedia === 'function' && matchMedia('(prefers-reduced-motion: reduce)').matches;
  }
}

function distance(a: Point, b: Point): number {
  return Math.hypot(a.x - b.x, a.y - b.y);
}
