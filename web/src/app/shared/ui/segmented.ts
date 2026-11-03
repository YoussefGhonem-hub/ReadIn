import { ChangeDetectionStrategy, Component, input, model } from '@angular/core';

export interface SegmentOption<T extends string> {
  value: T;
  label: string;
  /** Renders the label LTR (e.g. "English only" in the Arabic UI). */
  ltr?: boolean;
}

/** Segmented control (radio group) used for theme, languages and font size. */
@Component({
  selector: 'rd-segmented',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { role: 'radiogroup', '[attr.aria-label]': 'label()', class: 'flex rounded-md bg-surface-variant p-1' },
  template: `
    @for (option of options(); track option.value) {
      <button
        type="button"
        role="radio"
        [attr.aria-checked]="value() === option.value"
        [disabled]="disabled()"
        class="min-h-10 flex-1 whitespace-nowrap rounded-sm px-2 text-sm transition-colors"
        [class]="
          value() === option.value
            ? 'bg-surface font-semibold text-primary shadow-card'
            : 'text-text-secondary hover:text-text-primary'
        "
        (click)="value.set(option.value)"
      >
        @if (option.ltr) {
          <bdi dir="ltr">{{ option.label }}</bdi>
        } @else {
          {{ option.label }}
        }
      </button>
    }
  `,
})
export class Segmented<T extends string> {
  readonly options = input.required<SegmentOption<T>[]>();
  readonly value = model.required<T>();
  readonly label = input('');
  readonly disabled = input(false);
}
