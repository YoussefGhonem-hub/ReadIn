import { ChangeDetectionStrategy, Component, input } from '@angular/core';

/** "ReadIn" wordmark — always written in English and LTR, also in the Arabic UI (SPEC §15.1). */
@Component({
  selector: 'rd-wordmark',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { dir: 'ltr', class: 'inline-flex items-center font-latin font-bold tracking-tight select-none' },
  template: `
    @if (withIcon()) {
      <span
        class="me-2 inline-grid h-8 w-8 place-items-center rounded-md bg-primary text-[18px] text-on-primary"
        aria-hidden="true"
        >R</span
      >
    }
    <span class="text-text-primary" [style.font-size.px]="size()">Read</span><span class="text-primary" [style.font-size.px]="size()">In</span>
  `,
})
export class Wordmark {
  readonly size = input(24);
  readonly withIcon = input(false);
}
