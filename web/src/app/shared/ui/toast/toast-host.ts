import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { TranslocoPipe } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { ToastService } from './toast.service';

@Component({
  selector: 'rd-toast-host',
  imports: [TranslocoPipe, LucideDynamicIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'pointer-events-none fixed inset-x-0 bottom-20 z-50 flex flex-col items-center gap-2 px-4 lg:bottom-6',
    'aria-live': 'polite',
    role: 'status',
  },
  template: `
    @for (toast of toasts.toasts(); track toast.id) {
      <div
        class="pointer-events-auto flex max-w-md items-start gap-3 rounded-md border border-border bg-surface-raised px-4 py-3 text-sm text-text-primary shadow-raised"
      >
        @switch (toast.kind) {
          @case ('error') {
            <svg lucideIcon="CircleAlert" class="mt-0.5 shrink-0 text-error" [size]="18"></svg>
          }
          @case ('success') {
            <svg lucideIcon="CircleCheck" class="mt-0.5 shrink-0 text-success" [size]="18"></svg>
          }
          @default {
            <svg lucideIcon="Info" class="mt-0.5 shrink-0 text-primary" [size]="18"></svg>
          }
        }
        <p class="m-0 flex-1" dir="auto">{{ toast.message }}</p>
        <button
          type="button"
          class="text-text-secondary hover:text-text-primary"
          [attr.aria-label]="'common.close' | transloco"
          (click)="toasts.dismiss(toast.id)"
        >
          <svg lucideIcon="X" [size]="16"></svg>
        </button>
      </div>
    }
  `,
})
export class ToastHost {
  protected readonly toasts = inject(ToastService);
}
