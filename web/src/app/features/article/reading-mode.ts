import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Injectable,
  Injector,
  Provider,
  ViewEncapsulation,
  afterNextRender,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LUCIDE_ICONS, LucideDynamicIcon, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import BookOpenText from 'lucide/dist/esm/icons/book-open-text.mjs';
import Minimize2 from 'lucide/dist/esm/icons/minimize-2.mjs';
import { CookieService } from '../../core/platform/cookie.service';

/** The device's choice (F04), a cookie so the server renders the reader already in reading mode (no flash). */
export const READING_MODE_COOKIE = 'reading_mode';

/** What else takes an Escape first: an open dialog or sheet, a menu or list, a field, a selection (the highlights bar). */
const ESCAPE_OWNERS =
  '[role="dialog"], [role="alertdialog"], [role="menu"], [role="listbox"], [role="combobox"], [role="toolbar"], input, textarea, select, [contenteditable]:not([contenteditable="false"])';

/**
 * Reading mode (F04): on, the reader keeps the article and its reading progress bar while the app's chrome hides (the
 * top bar, the reader's floating action bar, the bottom nav and the docked Following panel). Remembered on this
 * device only (not synced), in the {@link READING_MODE_COOKIE} cookie, which SSR reads like `theme` and `lang`.
 */
@Injectable({ providedIn: 'root' })
export class ReadingModeService {
  private readonly cookies = inject(CookieService);
  private readonly state = signal(this.cookies.get(READING_MODE_COOKIE) === '1');
  readonly on = this.state.asReadonly();

  set(on: boolean): void {
    this.state.set(on);
    this.cookies.set(READING_MODE_COOKIE, on ? '1' : '0');
  }
}

/** Icons only reading mode uses, registered for its tree so they stay in the reader's lazy chunk. */
function provideReadingModeIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap({ BookOpenText, Minimize2 })) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}

/**
 * The reader's reading mode (F04): a toggle button for the reader's toolbar (`aria-pressed`, the same name on and off)
 * and, while on, a small floating "Exit reading mode" control at the bottom end corner; Escape turns it off too, unless
 * something else owns that Escape (a sheet, a menu, a field, a text selection).
 *
 * The chrome is hidden by this component's global style while its host says `data-reading-mode`, so the shell needs no
 * code: the server renders it hidden, it comes back by itself when the reader goes, and this code stays in the reader's
 * lazy chunk. Switching keeps the text where it was on screen (the top bar's height comes back as scroll). The floating
 * control only fades in, and not with reduced motion; screen readers hear "Reading mode is on/off".
 */
@Component({
  selector: 'rd-reading-mode',
  imports: [TranslocoPipe, LucideDynamicIcon],
  providers: [provideReadingModeIcons()],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  host: {
    class: 'contents',
    '[attr.data-reading-mode]': "mode.on() ? 'on' : null",
    '(document:keydown.escape)': 'onEscape($event)',
  },
  styles: `
    body:has(rd-reading-mode[data-reading-mode]) :is(rd-top-bar, rd-bottom-nav, rd-article-action-bar, rd-following-dock) {
      display: none !important;
    }
    @keyframes rd-reading-exit-in {
      from {
        opacity: 0;
        transform: translateY(6px);
      }
    }
    @media (prefers-reduced-motion: no-preference) {
      .rd-reading-exit {
        animation: rd-reading-exit-in 180ms ease-out;
      }
    }
  `,
  template: `
    <button
      #toggleButton
      type="button"
      class="rd-icon-btn"
      [class]="mode.on() ? 'border-primary bg-primary-container text-on-primary-container' : ''"
      [attr.aria-pressed]="mode.on()"
      [attr.aria-label]="'article.readingMode.toggle' | transloco"
      (click)="set(!mode.on())"
      data-reading-mode-toggle
    >
      <svg lucideIcon="BookOpenText" [size]="18"></svg>
    </button>
    @if (mode.on()) {
      <button
        type="button"
        class="rd-reading-exit fixed bottom-[calc(1rem+env(safe-area-inset-bottom))] end-4 z-30 inline-flex min-h-11 items-center gap-1.5 rounded-chip border border-border bg-surface px-4 text-sm font-semibold text-text-primary shadow-raised hover:border-primary hover:text-primary"
        aria-keyshortcuts="Escape"
        (click)="exit()"
        data-reading-mode-exit
      >
        <svg lucideIcon="Minimize2" [size]="16"></svg>
        {{ 'article.readingMode.exit' | transloco }}
      </button>
    }
    <span class="sr-only" role="status" data-reading-mode-status>{{ announcement() }}</span>
  `,
})
export class ReadingMode {
  protected readonly mode = inject(ReadingModeService);
  private readonly transloco = inject(TranslocoService);
  private readonly injector = inject(Injector);
  private readonly toggleButton = viewChild.required<ElementRef<HTMLButtonElement>>('toggleButton');
  /** Said once you switch (not when the reader opens in reading mode). */
  protected readonly announcement = signal('');

  /** The floating control: off, and the focus goes to the toggle it came from (the control is gone). */
  protected exit(): void {
    this.set(false);
    afterNextRender(() => this.toggleButton().nativeElement.focus({ preventScroll: true }), { injector: this.injector });
  }

  protected onEscape(event: Event): void {
    if (!this.mode.on() || event.defaultPrevented || ownsEscape(event.target)) return;
    const focusWasOnControl = (event.target as Element | null)?.closest?.('[data-reading-mode-exit]');
    if (focusWasOnControl) this.exit();
    else this.set(false);
  }

  /** Switches, keeping the text where it was on screen: the chrome's height comes back as scroll. */
  protected set(on: boolean): void {
    const anchor = this.toggleButton().nativeElement;
    const before = anchor.getBoundingClientRect().top;
    this.mode.set(on);
    this.announcement.set(this.transloco.translate(on ? 'article.readingMode.on' : 'article.readingMode.off'));
    afterNextRender(
      () => {
        const shift = anchor.getBoundingClientRect().top - before;
        if (shift) window.scrollBy({ top: shift, behavior: 'instant' });
      },
      { injector: this.injector },
    );
  }
}

/** Something else takes this Escape first (see {@link ESCAPE_OWNERS}), or a modal is open. */
function ownsEscape(target: EventTarget | null): boolean {
  if (typeof document === 'undefined') return true;
  if (document.querySelector('[aria-modal="true"], dialog[open]')) return true;
  if (target instanceof Element && target.closest(ESCAPE_OWNERS)) return true;
  const selection = typeof window.getSelection === 'function' ? window.getSelection() : null;
  return !!selection && !selection.isCollapsed;
}
