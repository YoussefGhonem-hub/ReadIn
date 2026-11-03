import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';

let nextId = 0;

/**
 * An on/off setting (`role="switch"`) with its label and an optional hint. The label toggles it too, the target is
 * 44 px, and the thumb moves toward the inline end in both directions. Its look is in component styles, so only the
 * lazy pages that use it carry them.
 */
@Component({
  selector: 'rd-switch',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'flex items-center justify-between gap-3' },
  styles: `
    .track {
      position: relative;
      display: block;
      width: 44px;
      height: 24px;
      border-radius: 999px;
      background: var(--rd-color-surface-variant);
      box-shadow: inset 0 0 0 1px var(--rd-color-text-secondary);
      /* Longhands: the shorthand reads like a Tailwind class and would add one to the global stylesheet. */
      transition-property: background-color;
      transition-duration: var(--rd-motion-fast);
    }
    .thumb {
      position: absolute;
      inset-inline-start: 3px;
      top: 3px;
      width: 18px;
      height: 18px;
      border-radius: 999px;
      background: var(--rd-color-text-secondary);
      transition-property: transform;
      transition-duration: var(--rd-motion-fast);
    }
    [aria-checked='true'] .track {
      background: var(--rd-color-primary);
      box-shadow: inset 0 0 0 1px var(--rd-color-primary);
    }
    [aria-checked='true'] .thumb {
      background: var(--rd-color-on-primary);
      transform: translateX(20px);
    }
    :host-context([dir='rtl']) [aria-checked='true'] .thumb {
      transform: translateX(-20px);
    }
    button:disabled {
      cursor: not-allowed;
    }
  `,
  template: `
    <span class="min-w-0 flex-1">
      <label [for]="id" class="block cursor-pointer text-sm font-semibold">{{ label() }}</label>
      @if (hint()) {
        <span [id]="id + '-hint'" class="mt-1 block text-xs text-text-secondary">{{ hint() }}</span>
      }
    </span>
    <button
      type="button"
      role="switch"
      [id]="id"
      class="inline-grid h-11 w-14 shrink-0 cursor-pointer place-items-center rounded-full disabled:opacity-60"
      [attr.aria-checked]="checked()"
      [attr.aria-describedby]="hint() ? id + '-hint' : null"
      [attr.aria-busy]="busy() || null"
      [disabled]="disabled()"
      (click)="changed.emit(!checked())"
    >
      <span class="track" aria-hidden="true"><span class="thumb"></span></span>
    </button>
  `,
})
export class Switch {
  readonly checked = input.required<boolean>();
  readonly label = input.required<string>();
  readonly hint = input<string | null>(null);
  readonly disabled = input(false);
  /** A save is running: announced, and the caller usually disables it too. */
  readonly busy = input(false);
  readonly changed = output<boolean>();

  protected readonly id = `rd-switch-${nextId++}`;
}
