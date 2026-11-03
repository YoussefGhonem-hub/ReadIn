import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  PLATFORM_ID,
  effect,
  inject,
  input,
  output,
  viewChild,
} from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';

/**
 * Bottom sheet on narrow screens, centered dialog on wide ones. Closes on scrim click and Escape,
 * and moves focus into the panel when opened.
 */
@Component({
  selector: 'rd-bottom-sheet',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { '(document:keydown.escape)': 'open() && closed.emit()' },
  template: `
    @if (open()) {
      <div class="fixed inset-0 z-40 bg-scrim" (click)="closed.emit()" aria-hidden="true"></div>
      <section
        #panel
        role="dialog"
        aria-modal="true"
        [attr.aria-label]="label()"
        tabindex="-1"
        class="fixed inset-x-0 bottom-0 z-50 max-h-[85vh] overflow-y-auto rounded-t-sheet border border-border bg-surface-raised p-5 pb-8 shadow-raised outline-none lg:inset-x-auto lg:start-1/2 lg:bottom-auto lg:top-1/2 lg:w-[480px] lg:-translate-y-1/2 lg:rounded-sheet lg:pb-5 ltr:lg:-translate-x-1/2 rtl:lg:translate-x-1/2"
      >
        <div class="mx-auto mb-4 h-1 w-9 rounded-chip bg-border lg:hidden" aria-hidden="true"></div>
        <button
          type="button"
          class="rd-icon-btn absolute end-4 top-4 h-9 w-9"
          [attr.aria-label]="'common.close' | transloco"
          (click)="closed.emit()"
        >
          <svg lucideIcon="X" [size]="18"></svg>
        </button>
        <ng-content />
      </section>
    }
  `,
})
export class BottomSheet {
  readonly open = input(false);
  readonly label = input<string>('');
  readonly closed = output<void>();

  private readonly panel = viewChild<ElementRef<HTMLElement>>('panel');

  constructor() {
    const isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
    effect(() => {
      const panel = this.panel();
      if (isBrowser && this.open() && panel) queueMicrotask(() => panel.nativeElement.focus());
    });
  }
}
