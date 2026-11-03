import {
  ChangeDetectionStrategy,
  Component,
  DOCUMENT,
  ElementRef,
  PLATFORM_ID,
  effect,
  inject,
  input,
  output,
  untracked,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';

const FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

/**
 * Bottom sheet on narrow screens, centered dialog on wide ones. Closes on scrim click and Escape (unless
 * `dismissible` is off, e.g. while a request is running), keeps focus inside while open and gives it back to the
 * element that opened it.
 */
@Component({
  selector: 'rd-bottom-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { '(document:keydown.escape)': 'open() && dismiss()' },
  template: `
    @if (open()) {
      <div class="fixed inset-0 z-40 bg-scrim" (click)="dismiss()" aria-hidden="true"></div>
      <section
        #panel
        [attr.role]="role()"
        aria-modal="true"
        [attr.aria-label]="labelledBy() ? null : label()"
        [attr.aria-labelledby]="labelledBy()"
        [attr.aria-describedby]="describedBy()"
        tabindex="-1"
        (keydown.tab)="trapFocus($event)"
        (keydown.shift.tab)="trapFocus($event)"
        class="fixed inset-x-0 bottom-0 z-50 max-h-[85vh] overflow-y-auto rounded-t-sheet border border-border bg-surface-raised p-5 pb-8 shadow-raised outline-none lg:inset-x-auto lg:start-1/2 lg:bottom-auto lg:top-1/2 lg:w-[480px] lg:-translate-y-1/2 lg:rounded-sheet lg:pb-5 ltr:lg:-translate-x-1/2 rtl:lg:translate-x-1/2"
      >
        <div class="mx-auto mb-4 h-1 w-9 rounded-chip bg-border lg:hidden" aria-hidden="true"></div>
        @if (dismissible()) {
          <button
            type="button"
            class="rd-icon-btn absolute end-4 top-4 h-9 w-9"
            [attr.aria-label]="'common.close' | transloco"
            (click)="dismiss()"
          >
            <svg lucideIcon="X" [size]="18"></svg>
          </button>
        }
        <ng-content />
      </section>
    }
  `,
})
export class BottomSheet {
  readonly open = input(false);
  readonly label = input<string>('');
  /** Id of the sheet's heading; preferred over `label`. */
  readonly labelledBy = input<string | null>(null);
  readonly describedBy = input<string | null>(null);
  /** `alertdialog` for confirmations that interrupt a flow. */
  readonly role = input<'dialog' | 'alertdialog'>('dialog');
  readonly dismissible = input(true);
  readonly closed = output<void>();

  private readonly panel = viewChild<ElementRef<HTMLElement>>('panel');
  private readonly document = inject(DOCUMENT);
  private opener: HTMLElement | null = null;

  constructor() {
    const isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
    effect(() => {
      const open = this.open();
      const panel = this.panel();
      if (!isBrowser) return;
      untracked(() => {
        if (open && panel) {
          const active = this.document.activeElement;
          this.opener ??= active instanceof HTMLElement && !panel.nativeElement.contains(active) ? active : null;
          queueMicrotask(() => {
            if (!panel.nativeElement.contains(this.document.activeElement)) panel.nativeElement.focus();
          });
        } else if (!open && this.opener) {
          const opener = this.opener;
          this.opener = null;
          queueMicrotask(() => opener.isConnected && opener.focus());
        }
      });
    });
  }

  protected dismiss(): void {
    if (this.dismissible()) this.closed.emit();
  }

  /** Keeps Tab inside the open sheet (it is modal). Small on purpose: this component is in the initial bundle. */
  protected trapFocus(event: Event): void {
    const panel = this.panel()?.nativeElement;
    if (!panel) return;
    const focusable = [...panel.querySelectorAll<HTMLElement>(FOCUSABLE)].filter((el) => el.offsetParent !== null || el === this.document.activeElement);
    if (focusable.length === 0) return;
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    const backwards = (event as KeyboardEvent).shiftKey;
    const active = this.document.activeElement;
    if (backwards && (active === first || active === panel)) {
      event.preventDefault();
      last.focus();
    } else if (!backwards && active === last) {
      event.preventDefault();
      first.focus();
    }
  }
}
