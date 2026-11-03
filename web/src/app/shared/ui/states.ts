import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';

/** Empty state (DoD: every screen has empty, loading and error states). */
@Component({
  selector: 'rd-empty-state',
  imports: [LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col items-center gap-2 px-6 py-12 text-center' },
  template: `
    <span class="mb-2 grid h-14 w-14 place-items-center rounded-card bg-primary-container text-on-primary-container" aria-hidden="true">
      <svg lucideIcon="Inbox" [size]="26"></svg>
    </span>
    <h3 class="m-0 text-lg font-semibold">{{ title() }}</h3>
    @if (message()) {
      <p class="m-0 max-w-sm text-sm text-text-secondary">{{ message() }}</p>
    }
    <ng-content />
  `,
})
export class EmptyState {
  readonly title = input.required<string>();
  readonly message = input<string | null>(null);
}

@Component({
  selector: 'rd-error-state',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex flex-col items-center gap-2 px-6 py-12 text-center', role: 'alert' },
  template: `
    <span class="mb-2 grid h-14 w-14 place-items-center rounded-card bg-callout-danger text-error" aria-hidden="true">
      <svg lucideIcon="CloudOff" [size]="26"></svg>
    </span>
    <h3 class="m-0 text-lg font-semibold">{{ title() ?? ('errors.loadFailed' | transloco) }}</h3>
    @if (message()) {
      <p class="m-0 max-w-sm text-sm text-text-secondary">{{ message() }}</p>
    }
    <button type="button" class="rd-btn rd-btn-outline mt-3" (click)="retry.emit()">
      <svg lucideIcon="RefreshCw" [size]="16"></svg>
      {{ 'common.retry' | transloco }}
    </button>
  `,
})
export class ErrorState {
  readonly title = input<string | null>(null);
  readonly message = input<string | null>(null);
  readonly retry = output<void>();
}
