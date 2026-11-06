import { ChangeDetectionStrategy, Component, DOCUMENT, DestroyRef, PLATFORM_ID, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { Subscription, TimeoutError } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { QUOTE_CARD_SIZE, QuoteCardApi, QuoteCardFormat, QuoteCardTheme } from '../../core/api/quote-card.api';
import { ErrorMessages } from '../../core/i18n/error-messages';
import { LanguageService } from '../../core/i18n/language.service';
import { ThemeService } from '../../core/theme/theme.service';
import { BottomSheet } from '../../shared/ui/bottom-sheet';
import { SegmentOption, Segmented } from '../../shared/ui/segmented';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { QuoteCardSource } from './quote-card';
import { QUOTE_ICON } from './quote-card-icons';

/** Answers whose message offers «إعادة المحاولة»: the hourly limit, no drawing slot, a failed drawing (contract → Quote card). */
const RETRYABLE = new Set(['quote.limit', 'quote.busy', 'quote.failed']);

/** The object URL lives a little after the click, so every browser has started the download from it. */
const REVOKE_AFTER_MS = 10_000;

/** A failed card as the user sees it. */
export interface QuoteCardFailure {
  message: string;
  /** Shows «إعادة المحاولة» / "Try again", which asks again for the card on screen. */
  retry: boolean;
}

type Card = { status: 'loading' } | { status: 'ready'; file: File; url: string } | ({ status: 'error' } & QuoteCardFailure);

const LOADING: Card = { status: 'loading' };

/**
 * Share quote (F24): the reader's selection as a picture for social media, drawn by the server
 * (`POST /articles/{id}/quote-card`, ADR 0019). A dialog (a bottom sheet on narrow screens) with a live preview of the
 * card (a box of its shape with a spinner while it loads), Light / Dark (the app's theme first) and Square (1080 × 1080)
 * / Landscape (1200 × 630). Each card is asked for once while the dialog is open: switching back shows the one already
 * drawn, and Share / Download use the bytes on screen.
 *
 * **Share** hands the PNG (and the article's link as text) to the Web Share API when the browser can share files,
 * otherwise downloads it; **Download** saves it under the server's name (`readin-quote-{slug}.png`); **Copy link** copies
 * the article's web link. Failures show their message in the preview, with «إعادة المحاولة» where trying again can
 * help; without a connection it says the internet is needed and asks nothing; `quote.text_mismatch` also has the reader
 * load the article again (`textChanged`). A lazy chunk, loaded on the first Share quote.
 */
@Component({
  selector: 'rd-quote-card-dialog',
  imports: [TranslocoPipe, LucideDynamicIcon, BottomSheet, Segmented],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <rd-bottom-sheet [open]="!!source()" labelledBy="rd-quote-card-title" describedBy="rd-quote-card-hint" (closed)="close()">
      @if (source()) {
        <div class="mx-auto flex max-w-lg flex-col gap-4" data-quote-dialog>
          <div>
            <h2 id="rd-quote-card-title" class="m-0 pe-10 text-lg font-semibold">{{ 'quoteCard.title' | transloco }}</h2>
            <p id="rd-quote-card-hint" class="m-0 mt-1 text-sm text-text-secondary" data-quote-hint>{{ 'quoteCard.hint' | transloco }}</p>
          </div>

          <!-- The card, or a box of its shape while it loads (or failed) -->
          <div
            class="mx-auto grid max-w-full place-items-center overflow-hidden rounded-card border border-border bg-surface-variant"
            [style.aspect-ratio]="ratio()"
            [style.width]="format() === 'square' ? 'min(100%, 42vh)' : '100%'"
            [attr.data-quote-preview]="format()"
            [attr.data-state]="card().status"
            [attr.aria-busy]="card().status === 'loading'"
          >
            @if (ready(); as c) {
              <img
                [src]="c.url"
                [alt]="'quoteCard.alt' | transloco: { quote: quoteText() }"
                [attr.width]="size().width"
                [attr.height]="size().height"
                class="block h-full w-full object-contain"
                data-quote-image
              />
            } @else if (failure(); as f) {
              <div class="flex flex-col items-center gap-3 p-4 text-center" data-quote-error>
                <svg lucideIcon="CircleAlert" [size]="24" class="text-error" aria-hidden="true"></svg>
                <p class="m-0 max-w-sm text-sm" role="alert">{{ f.message }}</p>
                @if (f.retry) {
                  <button type="button" class="rd-btn rd-btn-outline min-h-10 gap-1.5 text-sm" data-quote-retry (click)="retry()">
                    <svg lucideIcon="RefreshCw" [size]="16" aria-hidden="true"></svg>
                    {{ 'quoteCard.retry' | transloco }}
                  </button>
                }
              </div>
            } @else {
              <div class="flex flex-col items-center gap-2 text-text-secondary" aria-hidden="true" data-quote-loading>
                <svg lucideIcon="LoaderCircle" [size]="28" class="animate-spin"></svg>
                <span class="text-sm">{{ 'quoteCard.preparing' | transloco }}</span>
              </div>
            }
          </div>

          <!-- Side by side in the dialog, one above the other in the phone's sheet (only utilities the app already has:
               Tailwind puts every one in the initial stylesheet) -->
          <div class="flex flex-wrap gap-2">
            <rd-segmented class="min-w-48 flex-1" [options]="themeOptions()" [(value)]="theme" [label]="'quoteCard.theme' | transloco" data-quote-theme />
            <rd-segmented class="min-w-48 flex-1" [options]="formatOptions()" [(value)]="format" [label]="'quoteCard.format' | transloco" data-quote-format />
          </div>

          <div class="flex flex-wrap gap-2">
            <button type="button" class="rd-btn rd-btn-primary flex-1 whitespace-nowrap" [disabled]="!ready()" data-quote-share (click)="share()">
              <svg lucideIcon="Share2" [size]="18" aria-hidden="true"></svg>
              {{ 'quoteCard.shareImage' | transloco }}
            </button>
            <button type="button" class="rd-btn rd-btn-outline flex-1 whitespace-nowrap" [disabled]="!ready()" data-quote-download (click)="download()">
              <svg lucideIcon="Download" [size]="18" aria-hidden="true"></svg>
              {{ 'quoteCard.download' | transloco }}
            </button>
            <button type="button" class="rd-btn rd-btn-ghost flex-1 whitespace-nowrap" data-quote-copy-link (click)="copyLink()">
              <svg [lucideIcon]="icons.Link" [size]="18" aria-hidden="true"></svg>
              {{ 'quoteCard.copyLink' | transloco }}
            </button>
          </div>
          <span class="sr-only" aria-live="polite" data-quote-status>{{ status() }}</span>
        </div>
      }
    </rd-bottom-sheet>
  `,
})
export class QuoteCardDialog {
  /** The quote to draw; null closes the dialog. */
  readonly source = input<QuoteCardSource | null>(null);
  /** Closes it (the reader sets `source` back to null). */
  readonly dismiss = input<() => void>(() => undefined);
  /** `quote.text_mismatch`: the article changed meanwhile, so the reader loads it and its highlights again. */
  readonly textChanged = input<() => void>(() => undefined);

  private readonly api = inject(QuoteCardApi);
  private readonly themes = inject(ThemeService);
  private readonly lang = inject(LanguageService).lang;
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);
  private readonly toasts = inject(ToastService);
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  protected readonly icons = QUOTE_ICON;

  protected readonly theme = signal<QuoteCardTheme>(this.themes.resolved());
  protected readonly format = signal<QuoteCardFormat>('square');
  /** The cards of the open dialog, by `{theme}|{format}`. */
  private readonly cards = signal<ReadonlyMap<string, Card>>(new Map());
  private readonly key = computed(() => keyOf(this.theme(), this.format()));
  protected readonly card = computed<Card>(() => this.cards().get(this.key()) ?? LOADING);
  protected readonly ready = computed(() => {
    const card = this.card();
    return card.status === 'ready' ? card : null;
  });
  protected readonly failure = computed(() => {
    const card = this.card();
    return card.status === 'error' ? card : null;
  });
  protected readonly size = computed(() => QUOTE_CARD_SIZE[this.format()]);
  protected readonly ratio = computed(() => `${this.size().width} / ${this.size().height}`);
  protected readonly quoteText = computed(() => this.source()?.range.text ?? '');
  /** Said to screen readers: preparing, then ready (failures are an alert in the preview). */
  protected readonly status = computed(() => {
    this.lang();
    const status = this.card().status;
    if (status === 'loading') return this.transloco.translate('quoteCard.preparing');
    return status === 'ready' ? this.transloco.translate('quoteCard.ready') : '';
  });

  protected readonly themeOptions = computed<SegmentOption<QuoteCardTheme>[]>(() => {
    this.lang();
    // The app's own words for its themes (Settings).
    return [
      { value: 'light', label: this.transloco.translate('settings.theme.light') },
      { value: 'dark', label: this.transloco.translate('settings.theme.dark') },
    ];
  });
  protected readonly formatOptions = computed<SegmentOption<QuoteCardFormat>[]>(() => {
    this.lang();
    return [
      { value: 'square', label: this.transloco.translate('quoteCard.square') },
      { value: 'landscape', label: this.transloco.translate('quoteCard.landscape') },
    ];
  });

  private readonly requests = new Map<string, Subscription>();
  private readonly urls = new Set<string>();
  /** The quote the cards belong to. */
  private shown: QuoteCardSource | null = null;

  constructor() {
    // A new quote starts over in the app's theme, square; then the card on screen is asked for once.
    effect(() => {
      const source = this.source();
      this.key();
      untracked(() => {
        if (source !== this.shown) {
          this.reset();
          this.shown = source;
          if (source) {
            this.theme.set(this.themes.resolved());
            this.format.set('square');
          }
        }
        if (source && this.isBrowser && !this.cards().has(this.key())) this.load(source, this.theme(), this.format());
      });
    });
    inject(DestroyRef).onDestroy(() => this.reset());
  }

  protected close(): void {
    this.dismiss()();
  }

  /** «إعادة المحاولة»: the card on screen again (offline: only once the connection is back). */
  protected retry(): void {
    const source = this.source();
    if (source) this.load(source, this.theme(), this.format());
  }

  /** The Web Share API with the PNG (and the article's link) when the browser can share files; a download otherwise. */
  protected async share(): Promise<void> {
    const card = this.ready();
    const source = this.source();
    if (!card || !source) return;
    const navigator = this.document.defaultView?.navigator;
    const files = [card.file];
    if (typeof navigator?.share !== 'function' || typeof navigator.canShare !== 'function' || !navigator.canShare({ files })) {
      this.save(card.file);
      return;
    }
    try {
      await navigator.share({ files, title: 'ReadIn', text: source.article.url });
    } catch (error) {
      // Dismissed: nothing to do. Refused (a policy, or a type the target doesn't take): the file is saved instead.
      if (!(error instanceof DOMException && error.name === 'AbortError')) this.save(card.file);
    }
  }

  protected download(): void {
    const card = this.ready();
    if (card) this.save(card.file);
  }

  protected async copyLink(): Promise<void> {
    const url = this.source()?.article.url;
    if (!url) return;
    try {
      await this.document.defaultView!.navigator.clipboard.writeText(url);
      this.toasts.success(this.transloco.translate('common.linkCopied'));
    } catch {
      this.toasts.error(this.transloco.translate('quoteCard.copyFailed'));
    }
  }

  /**
   * What a failure says (contract → Quote card (F24) → Errors; mobile's meaning, in Modern Standard Arabic, SPEC §14.4):
   * `quote.limit` / `quote.busy` / `quote.failed` with «إعادة المحاولة»; `article.not_found` → «المقال غير موجود.»;
   * `validation.failed` → the generic message; the other `quote.*` codes and any other known code with their message and
   * no retry; no connection → «تحتاج إلى اتصال بالإنترنت…» with retry; `server.error`, a timeout or anything unexpected →
   * «تعذّر تجهيز بطاقة الاقتباس» with retry.
   */
  failureOf(error: unknown): QuoteCardFailure {
    if (error instanceof TimeoutError || !isApiError(error)) return this.failed();
    if (error.code === 'network') return this.offline();
    if (error.code === 'article.not_found') return { message: this.transloco.translate('quoteCard.notFound'), retry: false };
    if (error.code === 'validation.failed') return { message: this.transloco.translate('errors.unknown'), retry: false };
    if (RETRYABLE.has(error.code)) return { message: this.errors.forCode(error.code), retry: true };
    if (error.code === 'server.error' || !this.isKnown(error.code)) return this.failed();
    return { message: this.errors.forError(error), retry: false };
  }

  private failed(): QuoteCardFailure {
    return { message: this.errors.forCode('quote.failed'), retry: true };
  }

  private offline(): QuoteCardFailure {
    return { message: this.transloco.translate('quoteCard.offline'), retry: true };
  }

  /** A code the app has a message for (`errors.{code}`); others count as a failed drawing. */
  private isKnown(code: string): boolean {
    const key = `errors.${code}`;
    const text: unknown = this.transloco.translate(key);
    return typeof text === 'string' && !!text && text !== key;
  }

  private load(source: QuoteCardSource, theme: QuoteCardTheme, format: QuoteCardFormat): void {
    const key = keyOf(theme, format);
    this.requests.get(key)?.unsubscribe();
    if (this.document.defaultView?.navigator.onLine === false) {
      this.set(key, { status: 'error', ...this.offline() });
      return;
    }
    this.set(key, LOADING);
    const { article, range } = source;
    const request = { language: article.language, blockId: range.blockId, startOffset: range.startOffset, endOffset: range.endOffset, text: range.text, theme, format };
    this.requests.set(
      key,
      this.api.card(article.id, request).subscribe({
        next: ({ blob, fileName }) => {
          const file = new File([blob], fileName, { type: 'image/png' });
          const url = URL.createObjectURL(file);
          this.urls.add(url);
          this.set(key, { status: 'ready', file, url });
        },
        error: (error: unknown) => {
          this.set(key, { status: 'error', ...this.failureOf(error) });
          // As after `highlight.text_mismatch`: the reader loads the article and its highlights again (the dialog stays).
          if (isApiError(error) && error.code === 'quote.text_mismatch') this.textChanged()();
        },
      }),
    );
  }

  private set(key: string, card: Card): void {
    this.cards.update((cards) => new Map(cards).set(key, card));
  }

  /** Cancels what is still loading and frees the pictures. */
  private reset(): void {
    for (const request of this.requests.values()) request.unsubscribe();
    this.requests.clear();
    for (const url of this.urls) URL.revokeObjectURL(url);
    this.urls.clear();
    this.cards.set(new Map());
  }

  /** A normal browser download: an object URL on `<a download="{name}">`, clicked, then revoked. */
  private save(file: File): void {
    const url = URL.createObjectURL(file);
    const link = this.document.createElement('a');
    link.href = url;
    link.download = file.name;
    link.rel = 'noopener';
    link.style.display = 'none';
    this.document.body.appendChild(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), REVOKE_AFTER_MS);
  }
}

function keyOf(theme: QuoteCardTheme, format: QuoteCardFormat): string {
  return `${theme}|${format}`;
}
