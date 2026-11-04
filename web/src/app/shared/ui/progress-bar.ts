import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

/**
 * Thin progress bar (F03 continue reading, F09 path progress). Fills from the inline start, so it mirrors in RTL.
 * `label` is its accessible name ("3 of 10 read"); without one it is decorative.
 */
@Component({
  selector: 'rd-progress-bar',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'block h-1.5 overflow-hidden rounded-chip bg-surface-variant',
    '[attr.role]': 'label() ? "progressbar" : null',
    '[attr.aria-label]': 'label()',
    '[attr.aria-valuemin]': 'label() ? 0 : null',
    '[attr.aria-valuemax]': 'label() ? 100 : null',
    '[attr.aria-valuenow]': 'label() ? percent() : null',
    '[attr.aria-hidden]': 'label() ? null : "true"',
  },
  template: `<span class="block h-full rounded-chip" [class]="tone() === 'success' ? 'bg-success' : 'bg-primary'" [style.width.%]="percent()"></span>`,
})
export class ProgressBar {
  /** 0–100; clamped. */
  readonly value = input(0);
  readonly label = input<string | null>(null);
  readonly tone = input<'primary' | 'success'>('primary');
  protected readonly percent = computed(() => Math.min(100, Math.max(0, Math.round(this.value() || 0))));
}
