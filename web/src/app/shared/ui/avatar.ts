import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

/** User avatar: photo when available, otherwise the first letter on a soft primary background. */
@Component({
  selector: 'rd-avatar',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'rd-photo inline-grid shrink-0 place-items-center overflow-hidden rounded-full bg-primary-container font-bold text-on-primary-container',
    '[style.width.px]': 'size()',
    '[style.height.px]': 'size()',
    '[style.font-size.px]': 'size() * 0.42',
    '[attr.aria-hidden]': '!label()',
    '[attr.role]': 'label() ? "img" : null',
    '[attr.aria-label]': 'label()',
  },
  template: `
    @if (src()) {
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

  protected readonly initial = computed(() => (this.name()?.trim()?.[0] ?? '?').toUpperCase());
}
