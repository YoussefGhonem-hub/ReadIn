import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { LogoMark } from './logo-mark';

/** "ReadIn" wordmark — always written in English and LTR, also in the Arabic UI (SPEC §15.1). `withIcon` puts the logo mark before it. */
@Component({
  selector: 'rd-wordmark',
  imports: [LogoMark],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { dir: 'ltr', class: 'inline-flex items-center font-latin font-bold tracking-tight select-none' },
  template: `
    @if (withIcon()) {
      <rd-logo-mark class="me-2" [size]="32" />
    }
    <span class="text-text-primary" [style.font-size.px]="size()">Read</span><span class="text-primary" [style.font-size.px]="size()">In</span>
  `,
})
export class Wordmark {
  readonly size = input(24);
  readonly withIcon = input(false);
}
