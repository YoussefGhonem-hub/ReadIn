import { ChangeDetectionStrategy, Component, input } from '@angular/core';

/** Keeps the gradient ids unique when the mark is on a page more than once. */
let nextId = 0;

/**
 * The ReadIn logo mark: the Latin R and the Arabic ر on the brand green (the app icon and the favicon, drawn by
 * tools/app-store-assets/logo.html). Inline so it is sharp at any size and needs no request. The letters are the
 * outlines of IBM Plex Sans Bold and IBM Plex Sans Arabic Bold, so the mark looks the same before the fonts load.
 * Decorative: the link or the wordmark next to it names it.
 */
@Component({
  selector: 'rd-logo-mark',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'inline-block shrink-0 leading-none', 'aria-hidden': 'true' },
  template: `
    <svg viewBox="0 0 1024 1024" [attr.width]="size()" [attr.height]="size()" class="block" focusable="false" data-logo-mark>
      <defs>
        <radialGradient [attr.id]="bgId" cx="28%" cy="18%" r="95%">
          <stop offset="0" stop-color="#1C806A" />
          <stop offset=".55" stop-color="#0F5E52" />
          <stop offset="1" stop-color="#083F36" />
        </radialGradient>
        <linearGradient [attr.id]="raId" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="#F7C062" />
          <stop offset="1" stop-color="#E8962A" />
        </linearGradient>
      </defs>
      <rect width="1024" height="1024" rx="232" [attr.fill]="'url(#' + bgId + ')'" />
      <path
        fill="#FFFFFF"
        d="M350.2 581.4L350.2 735L259 735L259 316.2L457.6 316.2Q486.4 316.2 509.8 325.8Q533.2 335.4 549.7 353.1Q566.2 370.8 575.2 395.4Q584.2 420 584.2 450Q584.2 492.6 565.3 524.4Q546.4 556.2 508 570.6L590.2 735L488.8 735L415.6 581.4L350.2 581.4ZM350.2 504.6L446.2 504.6Q466.6 504.6 478.3 494.1Q490 483.6 490 463.2L490 436.8Q490 416.4 478.3 405.9Q466.6 395.4 446.2 395.4L350.2 395.4L350.2 504.6Z"
      />
      <path
        [attr.fill]="'url(#' + raId + ')'"
        d="M591.5 872.8L591.5 802.3L610.3 802.3Q653.1 802.3 673.1 784.9Q693.1 767.5 692.6 727.1Q692.6 716.3 691.2 704.3Q689.8 692.3 687.4 678.7L677.5 616.2L728.8 608.2L735.8 651.9Q739.6 674.5 741.7 693.5Q743.8 712.5 743.8 724.8Q743.8 758.6 735.4 785.9Q726.9 813.1 710.0 832.6Q693.1 852.1 668.1 862.5Q643.2 872.8 610.8 872.8L591.5 872.8Z"
      />
    </svg>
  `,
})
export class LogoMark {
  /** Width and height in CSS pixels. */
  readonly size = input(32);

  private readonly id = nextId++;
  protected readonly bgId = `rd-logo-bg-${this.id}`;
  protected readonly raId = `rd-logo-ra-${this.id}`;
}
