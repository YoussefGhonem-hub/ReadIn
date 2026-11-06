import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { ShellIcon } from './shell-icon';

/**
 * User avatar: photo when available, otherwise the first letter on a soft primary background. `generic` shows a
 * neutral person icon instead, with no photo or initial (a deleted account, SPEC §9.6).
 */
@Component({
  selector: 'rd-avatar',
  imports: [ShellIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'rd-photo inline-grid shrink-0 place-items-center overflow-hidden rounded-full font-bold',
    '[class]': "generic() ? 'bg-surface-variant text-text-secondary' : 'bg-primary-container text-on-primary-container'",
    '[attr.data-generic-avatar]': 'generic() || null',
    '[style.width.px]': 'size()',
    '[style.height.px]': 'size()',
    '[style.font-size.px]': 'size() * 0.42',
    '[attr.aria-hidden]': '!label()',
    '[attr.role]': 'label() ? "img" : null',
    '[attr.aria-label]': 'label()',
  },
  template: `
    @if (generic()) {
      <svg rdIcon="UserRound" [size]="size() * 0.55" aria-hidden="true"></svg>
    } @else if (src()) {
      <img [src]="src()" alt="" class="h-full w-full object-cover" loading="lazy" referrerpolicy="no-referrer" />
    } @else {
      {{ initial() }}
    }
  `,
})
export class Avatar {
  readonly name = input<string | null>('');
  readonly src = input<string | null>(null);
  readonly size = input(32);
  readonly label = input<string | null>(null);
  /** Neutral icon instead of a photo or an initial. */
  readonly generic = input(false);

  protected readonly initial = computed(() => (this.name()?.trim()?.[0] ?? '?').toUpperCase());
}
