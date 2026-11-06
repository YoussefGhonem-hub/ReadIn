import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  Injector,
  PLATFORM_ID,
  Type,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  signal,
  untracked,
  viewChild,
} from '@angular/core';
import { NgComponentOutlet, isPlatformBrowser } from '@angular/common';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { AuthPromptService } from '../../core/auth/auth-prompt.service';
import { SessionStore } from '../../core/auth/session.store';
import { HighlightRange, selectionToHighlight } from '../../shared/rdoc/selection-offsets';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { QuoteCardArticle, QuoteCardSource, quoteOffer } from '../quote-card/quote-card';
import { QUOTE_ICON } from '../quote-card/quote-card-icons';
import { ArticleHighlightsStore, isPendingHighlight } from './article-highlights.store';
import { HIGHLIGHT_ICON } from './highlight-icons';
import { HighlightsPrefs } from './highlights-prefs';

/** What the toolbar offers. */
interface ToolbarState {
  /** Over a selection, or over a tapped highlight. */
  kind: 'selection' | 'mark';
  /** The range Highlight would save; null when it can't be offered. */
  range: HighlightRange | null;
  /** Your highlight Remove would delete. */
  removeId: string | null;
  /** "N readers highlighted this". */
  count: number | null;
  /** More than 1,000 characters: said instead of Highlight. */
  tooLong: boolean;
  /** Share quote (F24): the range to draw, `too_long` (over 400: said when pressed, nothing is asked), or not offered. */
  quote: HighlightRange | 'too_long' | null;
}

/** The space between the text and the toolbar, and the top bar it must not hide under. */
const GAP = 8;
const TOP_BAR = 64;
/** A link to a block: `#b-{blockId}` (the Saved tab's highlights). */
const BLOCK_ANCHOR = /^#b-([A-Za-z0-9_-]{1,64})$/;

/**
 * The reader's highlights (F30): selecting text in a paragraph, heading, list item, quote, callout or summary shows a
 * small toolbar over it (below it on touch screens, where the system's own menu is above) with **Highlight**, or
 * **Remove** inside one of your highlights (also for fewer than 3 characters), and "N readers highlighted this" inside a
 * popular one (also said through the live region, as the toolbar takes no focus). Tapping a highlight shows the same
 * toolbar. Guests get the sign-in prompt from Highlight. While highlights are hidden nothing shows.
 *
 * Next to Highlight, **Share quote** (F24) opens the quote card dialog for the same range (3–400 characters; a longer
 * selection says so when pressed, without asking the server), for guests and for readers who can't highlight too. It
 * shows only while the page gives `quoteArticle` (not on an article hidden by moderators). The dialog is a lazy chunk.
 *
 * Keyboard: with a selection, Tab moves into the toolbar and Escape closes it; `Ctrl + /` (⌘ / on a Mac) shows or
 * hides every highlight, announced to screen readers. A link with `#b-{blockId}` scrolls to that block once the article
 * is on screen (the resume position is skipped for links with an anchor, F04).
 */
@Component({
  selector: 'rd-reader-highlights',
  imports: [TranslocoPipe, LucideDynamicIcon, NgComponentOutlet],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'contents' },
  styles: `
    .bar {
      position: fixed;
      z-index: 35;
      translate: -50% 0;
      display: flex;
      align-items: center;
      gap: 2px;
      /* Its own width, not what is left right of its center (it is fixed, with left at its center), so labels don't wrap. */
      width: max-content;
      max-width: calc(100vw - 16px);
      padding: 4px;
      border: 1px solid var(--rd-color-border);
      border-radius: var(--rd-radius-md);
      background: var(--rd-color-surface-raised);
      box-shadow: var(--rd-elevation-raised);
      color: var(--rd-color-text-primary);
    }
    .note {
      padding-inline: 10px 6px;
      font-size: var(--rd-text-meta-size);
      line-height: 1.4;
      color: var(--rd-color-text-secondary);
    }
  `,
  template: `
    @if (state(); as t) {
      <div
        #bar
        class="bar"
        role="toolbar"
        tabindex="-1"
        [attr.aria-label]="'highlights.toolbar' | transloco"
        [style.top.px]="position().top"
        [style.left.px]="position().left"
        [attr.data-kind]="t.kind"
        data-highlight-toolbar
        (mousedown)="$event.preventDefault()"
        (keydown.escape)="dismiss()"
      >
        @if (t.count !== null) {
          <span class="note" data-highlight-count>{{ 'highlights.popular' | transloco: { count: t.count } }}</span>
        }
        @if (t.tooLong) {
          <span class="note" role="status" data-highlight-too-long>{{ 'errors.highlight.too_long' | transloco }}</span>
        }
        @if (t.range) {
          <button type="button" class="rd-btn rd-btn-ghost min-h-11 gap-1.5 px-3 text-sm" data-highlight-create (click)="create(t.range)">
            <svg [lucideIcon]="icons.Highlighter" [size]="16" class="text-primary" aria-hidden="true"></svg>
            {{ 'highlights.create' | transloco }}
          </button>
        }
        @if (t.removeId; as id) {
          <button type="button" class="rd-btn rd-btn-ghost min-h-11 gap-1.5 px-3 text-sm" data-highlight-remove (click)="remove(id)">
            <svg [lucideIcon]="icons.Eraser" [size]="16" aria-hidden="true"></svg>
            {{ 'highlights.remove' | transloco }}
          </button>
        }
        @if (t.quote; as quote) {
          <button type="button" class="rd-btn rd-btn-ghost min-h-11 gap-1.5 px-3 text-sm" data-quote-share-open (click)="shareQuote(quote)">
            <svg [lucideIcon]="quoteIcons.Quote" [size]="16" class="shrink-0 text-primary" aria-hidden="true"></svg>
            {{ 'quoteCard.share' | transloco }}
          </button>
        }
      </div>
    }
    <span class="sr-only" aria-live="polite" data-highlights-status>{{ announcement() }}</span>
    @if (quoteDialog(); as dialog) {
      <ng-container *ngComponentOutlet="dialog; inputs: quoteInputs()" />
    }
  `,
})
export class ReaderHighlights {
  protected readonly store = inject(ArticleHighlightsStore);
  private readonly prefs = inject(HighlightsPrefs);
  private readonly session = inject(SessionStore);
  private readonly prompt = inject(AuthPromptService);
  private readonly transloco = inject(TranslocoService);
  private readonly toasts = inject(ToastService);
  private readonly injector = inject(Injector);
  protected readonly icons = HIGHLIGHT_ICON;
  protected readonly quoteIcons = QUOTE_ICON;

  /** The rendered article (`<rd-rdoc>`). */
  readonly content = input<HTMLElement | null>(null);
  /** The version quotes are shared from (F24); null: no Share quote (e.g. an article hidden by moderators). */
  readonly quoteArticle = input<QuoteCardArticle | null>(null);

  /** The quote card dialog, once its chunk has loaded, and the quote it shows (null: closed). */
  protected readonly quoteDialog = signal<Type<unknown> | null>(null);
  private readonly quoteSource = signal<QuoteCardSource | null>(null);
  protected readonly quoteInputs = computed(() => ({ source: this.quoteSource(), dismiss: this.closeQuote, textChanged: this.quoteTextChanged }));
  private readonly closeQuote = () => this.quoteSource.set(null);
  /** `quote.text_mismatch`: the article and its highlights load again, as after `highlight.text_mismatch`. */
  private readonly quoteTextChanged = () => this.store.textChanged();
  private quoteChunk: Promise<boolean> | null = null;

  protected readonly state = signal<ToolbarState | null>(null);
  protected readonly position = signal({ top: -9999, left: -9999 });
  protected readonly announcement = signal('');
  private readonly bar = viewChild<ElementRef<HTMLElement>>('bar');
  /** The version on screen. */
  private readonly version = computed(() => {
    const article = this.store.article();
    return article ? `${article.id}|${article.language}` : null;
  });
  /** Where the toolbar points (the selection or the tapped mark), read again on scroll. */
  private anchor: (() => DOMRect | null) | null = null;
  private pointerDown = false;
  private lastPointer = 'mouse';
  private timer: ReturnType<typeof setTimeout> | null = null;
  private frame = 0;
  /** The version a `#b-` link was followed in. */
  private anchoredFor: string | null = null;
  /** The popular count the live region is saying for the open toolbar. */
  private saidCount: string | null = null;

  constructor() {
    if (!isPlatformBrowser(inject(PLATFORM_ID))) return;
    const destroyRef = inject(DestroyRef);

    // Hidden: nothing to offer. Another version or article: the old toolbar means nothing.
    effect(() => {
      this.store.visible();
      this.version();
      untracked(() => this.close());
    });

    // Tapping a highlight.
    effect((onCleanup) => {
      const host = this.content();
      if (!host) return;
      const onClick = (event: MouseEvent) => this.onMarkClick(event, host);
      host.addEventListener('click', onClick);
      onCleanup(() => host.removeEventListener('click', onClick));
    });

    // Following a link to a block.
    effect(() => {
      const article = this.store.article();
      const host = this.content();
      if (!article || !host) return;
      const key = `${article.id}|${article.language}`;
      if (this.anchoredFor === key) return;
      this.anchoredFor = key;
      const blockId = BLOCK_ANCHOR.exec(window.location.hash)?.[1];
      if (blockId) untracked(() => this.scrollToBlock(host, blockId));
    });

    const onSelectionChange = () => this.schedule();
    const onPointerDown = (event: PointerEvent) => {
      if (this.bar()?.nativeElement.contains(event.target as Node)) return;
      this.pointerDown = true;
      this.lastPointer = event.pointerType || 'mouse';
      this.close();
    };
    const onPointerUp = () => {
      this.pointerDown = false;
      this.schedule();
    };
    const onKeydown = (event: KeyboardEvent) => this.onKeydown(event);
    const onMove = () => {
      if (this.state() && !this.frame) this.frame = requestAnimationFrame(() => ((this.frame = 0), this.place()));
    };
    document.addEventListener('selectionchange', onSelectionChange);
    document.addEventListener('pointerdown', onPointerDown, true);
    document.addEventListener('pointerup', onPointerUp, true);
    document.addEventListener('pointercancel', onPointerUp, true);
    document.addEventListener('keydown', onKeydown);
    window.addEventListener('scroll', onMove, { passive: true });
    window.addEventListener('resize', onMove, { passive: true });
    destroyRef.onDestroy(() => {
      document.removeEventListener('selectionchange', onSelectionChange);
      document.removeEventListener('pointerdown', onPointerDown, true);
      document.removeEventListener('pointerup', onPointerUp, true);
      document.removeEventListener('pointercancel', onPointerUp, true);
      document.removeEventListener('keydown', onKeydown);
      window.removeEventListener('scroll', onMove);
      window.removeEventListener('resize', onMove);
      if (this.timer) clearTimeout(this.timer);
      cancelAnimationFrame(this.frame);
    });
  }

  protected async create(range: HighlightRange): Promise<void> {
    this.close();
    if (!this.prompt.requireAuth()) return;
    document.getSelection()?.removeAllRanges();
    if (await this.store.create(range)) this.announcement.set(this.transloco.translate('highlights.created'));
  }

  protected async remove(id: string): Promise<void> {
    this.close();
    document.getSelection()?.removeAllRanges();
    if (await this.store.remove(id)) this.announcement.set(this.transloco.translate('highlights.removed'));
  }

  /**
   * Share quote (F24): opens the quote card dialog for the range (its chunk loads on the first press; offline it can't,
   * and says the internet is needed). Over 400 characters it only says so. The selection goes, so the toolbar doesn't
   * come back under the dialog. Focus moves to the quoted block first, so the dialog gives it back there when it closes
   * (the toolbar's button is gone by then), not to the top of the page (§26).
   */
  protected async shareQuote(quote: HighlightRange | 'too_long'): Promise<void> {
    const article = this.quoteArticle();
    this.close();
    if (!article) return;
    if (quote === 'too_long') {
      this.toasts.error(this.transloco.translate('errors.quote.too_long'));
      return;
    }
    document.getSelection()?.removeAllRanges();
    this.focusBlock(quote.blockId);
    this.quoteSource.set({ article, range: quote });
    if (!(await this.loadQuoteDialog())) {
      this.quoteSource.set(null);
      const retry = { label: this.transloco.translate('quoteCard.retry'), run: () => void this.shareQuote(quote) };
      this.toasts.error(this.transloco.translate('quoteCard.offline'), retry);
    }
  }

  /**
   * Focuses the block a quote comes from, else the article (`<rd-rdoc>`), without scrolling: focusable by script only
   * (`tabindex="-1"`) when it isn't focusable already.
   */
  private focusBlock(blockId: string): void {
    const host = this.content();
    if (!host) return;
    const target = host.querySelector<HTMLElement>(`[data-block-id="${blockId}"]`) ?? host;
    if (!target.hasAttribute('tabindex')) target.setAttribute('tabindex', '-1');
    target.focus({ preventScroll: true });
  }

  /** Resolves false when the dialog's chunk didn't load (offline); the next press tries again. */
  private loadQuoteDialog(): Promise<boolean> {
    this.quoteChunk ??= import('../quote-card/quote-card-dialog').then(
      ({ QuoteCardDialog }) => {
        this.quoteDialog.set(QuoteCardDialog);
        return true;
      },
      () => {
        this.quoteChunk = null;
        return false;
      },
    );
    return this.quoteChunk;
  }

  /** Escape: the toolbar goes, the selection stays. */
  protected dismiss(): void {
    const hadFocus = this.bar()?.nativeElement.contains(document.activeElement);
    this.close();
    if (hadFocus) (document.activeElement as HTMLElement | null)?.blur();
  }

  private close(): void {
    this.state.set(null);
    this.anchor = null;
    // The count goes with its toolbar, so the next toolbar's count is said again (another message stays).
    if (this.saidCount !== null && this.announcement() === this.saidCount) this.announcement.set('');
    this.saidCount = null;
  }

  /** Waits for the selection to settle (and for the pointer to lift) before reading it. */
  private schedule(): void {
    if (this.timer) clearTimeout(this.timer);
    if (this.pointerDown) return;
    this.timer = setTimeout(() => {
      this.timer = null;
      this.readSelection();
    }, 60);
  }

  private readSelection(): void {
    const host = this.content();
    const selection = document.getSelection();
    if (!host || !this.store.visible() || !selection || selection.rangeCount === 0 || selection.isCollapsed || this.quoteSource()) {
      // A tapped mark's toolbar stays until the next tap.
      if (this.state()?.kind !== 'mark') this.close();
      return;
    }
    const range = selection.getRangeAt(0).cloneRange();
    const result = selectionToHighlight(host, range);
    const anchor = () => (typeof range.getBoundingClientRect === 'function' ? range.getBoundingClientRect() : null);
    if (result.kind === 'too_long') {
      return this.open({ kind: 'selection', range: null, removeId: null, count: null, tooLong: true, quote: this.quoteFor(null, true) }, anchor);
    }
    if (result.kind === 'too_short') {
      // Too little for Highlight, but a word inside one of yours still offers Remove (as on mobile).
      const own = result.range && this.canWrite() ? this.store.mineContaining(result.range) : null;
      if (!own || !result.range) return this.close();
      return this.open({ kind: 'selection', range: null, removeId: own.id, count: this.store.popularCount(result.range), tooLong: false, quote: null }, anchor);
    }
    if (result.kind !== 'ok') return this.close();
    const mine = this.store.mineContaining(result.range);
    const count = this.store.popularCount(result.range);
    const canWrite = this.canWrite();
    const quote = this.quoteFor(result.range, false);
    if (!canWrite && count === null && !quote) return this.close();
    this.open(
      { kind: 'selection', range: canWrite && !mine ? result.range : null, removeId: canWrite && mine ? mine.id : null, count, tooLong: false, quote },
      anchor,
    );
  }

  /** What Share quote offers for the selection (F24): nothing while the page gives no article to quote from. */
  private quoteFor(range: HighlightRange | null, tooLongForHighlight: boolean): HighlightRange | 'too_long' | null {
    return this.quoteArticle() ? quoteOffer(range, tooLongForHighlight) : null;
  }

  private onMarkClick(event: MouseEvent, host: HTMLElement): void {
    const target = event.target instanceof Element ? event.target : null;
    const mark = target?.closest('.rd-hl');
    if (!mark || !host.contains(mark) || !this.store.visible() || target?.closest('a, button')) return;
    if (!(document.getSelection()?.isCollapsed ?? true)) return; // a selection's own toolbar
    const mine = mark.getAttribute('data-hl-mine');
    const count = mark.getAttribute('data-hl-count');
    const removeId = mine && !isPendingHighlight(mine) && this.session.isAuthenticated() && this.canWrite() ? mine : null;
    if (!removeId && count === null) return;
    this.open({ kind: 'mark', range: null, removeId, count: count === null ? null : Number(count), tooLong: false, quote: null }, () => mark.getBoundingClientRect());
  }

  private onKeydown(event: KeyboardEvent): void {
    if ((event.ctrlKey || event.metaKey) && !event.altKey && (event.key === '/' || event.code === 'Slash')) {
      if (isTyping(event.target)) return;
      event.preventDefault();
      void this.toggleVisible();
      return;
    }
    const bar = this.bar()?.nativeElement;
    if (!bar || !this.state()) return;
    if (event.key === 'Tab' && !event.shiftKey && !event.altKey && !bar.contains(document.activeElement)) {
      const first = bar.querySelector<HTMLElement>('button');
      if (!first) return;
      event.preventDefault();
      first.focus();
    } else if (event.key === 'Escape' && !bar.contains(document.activeElement)) {
      this.close();
    }
  }

  private async toggleVisible(): Promise<void> {
    const visible = !this.prefs.visible();
    await this.prefs.set(visible);
    this.announcement.set(this.transloco.translate(this.prefs.visible() ? 'highlights.shownStatus' : 'highlights.hiddenStatus'));
  }

  private canWrite(): boolean {
    return !this.session.isAuthenticated() || this.session.hasPermission('highlights.create');
  }

  private open(state: ToolbarState, anchor: () => DOMRect | null): void {
    this.anchor = anchor;
    this.state.set(state);
    // The toolbar appears without taking focus: "N readers highlighted this" is said through the live region (§26).
    if (state.count !== null) {
      const said: string = this.transloco.translate('highlights.popular', { count: state.count });
      this.saidCount = said;
      this.announcement.set(said);
    }
    // Placed once drawn, when its size is known.
    afterNextRender(() => this.place(), { injector: this.injector });
  }

  /** Over the text (centered, kept on screen), or below it on touch screens and when there's no room above. */
  private place(): void {
    const rect = this.anchor?.();
    const bar = this.bar()?.nativeElement;
    if (!rect || !bar) return;
    const width = bar.offsetWidth;
    const height = bar.offsetHeight;
    const below = this.lastPointer === 'touch' || rect.top - height - GAP < TOP_BAR;
    const viewport = document.documentElement.clientWidth;
    const half = width / 2;
    const center = rect.left + rect.width / 2;
    this.position.set({
      top: below ? rect.bottom + GAP : rect.top - height - GAP,
      left: Math.max(half + GAP, Math.min(viewport - half - GAP, center)),
    });
  }

  private scrollToBlock(host: HTMLElement, blockId: string): void {
    afterNextRender(
      () => {
        const go = () => {
          const block = host.querySelector(`[data-block-id="${blockId}"]`);
          block?.scrollIntoView({ block: 'center', behavior: 'instant' });
        };
        // Once web fonts have rewrapped the text, so the block stays where it lands.
        void (document.fonts?.ready ?? Promise.resolve()).then(() => requestAnimationFrame(go));
      },
      { injector: this.injector },
    );
  }
}

/** Keys typed into a field don't toggle anything. */
function isTyping(target: EventTarget | null): boolean {
  return target instanceof HTMLElement && (target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName));
}
