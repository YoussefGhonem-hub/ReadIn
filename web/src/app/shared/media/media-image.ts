import { ChangeDetectionStrategy, Component, afterRenderEffect, computed, inject, input, signal } from '@angular/core';
import { IMAGE_LOADER, NgOptimizedImage } from '@angular/common';
import { BlurHashDecoder, blurHashAverageColor } from './blurhash';
import { ImageVariant, VariantLoaderParams, pickVariant, sameVariants, sortVariants, variantImageLoader, variantSrcset } from './variant-loader';

/**
 * A media asset image (F26 "Image optimization"): `NgOptimizedImage` in `fill` mode with the variant loader, so the
 * browser only ever requests widths that exist. The host reserves the space (the parent gives it a size or an
 * `aspect-ratio`, so CLS stays 0) and paints the BlurHash: its average color during SSR, the decoded blur after
 * hydration.
 */
@Component({
  selector: 'rd-media-image',
  imports: [NgOptimizedImage],
  providers: [{ provide: IMAGE_LOADER, useValue: variantImageLoader }],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    // Positioned + block by default (styles/media.css, components layer) so callers can override with utilities.
    class: 'rd-media-image bg-surface-variant',
    '[style.background-color]': 'averageColor()',
    '[style.background-image]': 'placeholder()',
    '[style.background-size]': 'placeholder() ? "cover" : null',
    '[style.background-position]': 'placeholder() ? "center" : null',
  },
  template: `
    @for (key of srcKey(); track key) {
      @if (loaderParams().pick === 'largest') {
        <img
          [ngSrc]="key"
          fill
          disableOptimizedSrcset
          [sizes]="sizes()"
          [loaderParams]="loaderParams()"
          [priority]="priority()"
          [alt]="alt()"
          [style.object-fit]="fit()"
          draggable="false"
        />
      } @else {
        <img
          [ngSrc]="key"
          fill
          [ngSrcset]="srcset()"
          [sizes]="sizes()"
          [loaderParams]="loaderParams()"
          [priority]="priority()"
          [alt]="alt()"
          [style.object-fit]="fit()"
          draggable="false"
        />
      }
    }
  `,
})
export class MediaImage {
  private readonly decoder = inject(BlurHashDecoder);

  readonly variants = input.required<readonly ImageVariant[]>();
  readonly alt = input('');
  /** CSS `sizes`, e.g. `(min-width: 768px) 600px, 85vw`. */
  readonly sizes = input('100vw');
  readonly blurHash = input<string | null | undefined>(null);
  /** Width / height, used to decode the placeholder at the right shape. */
  readonly ratio = input(1);
  readonly fit = input<'cover' | 'contain'>('cover');
  readonly pick = input<'fit' | 'largest'>('fit');
  /** Eager + high fetch priority (+ preload link during SSR) for the first visible image only. */
  readonly priority = input(false);

  private readonly sorted = computed(() => sortVariants(this.variants()), { equal: sameVariants });
  /** Keyed by the largest file, so a different asset recreates the `<img>` (NgOptimizedImage inputs are init-only). */
  protected readonly srcKey = computed(() => {
    const largest = pickVariant(this.sorted());
    return largest ? [largest.url] : [];
  });
  protected readonly srcset = computed(() => variantSrcset(this.sorted()));
  protected readonly loaderParams = computed<VariantLoaderParams>(() => ({ variants: this.sorted(), pick: this.pick() }), {
    equal: (a, b) => a.pick === b.pick && sameVariants(a.variants, b.variants),
  });

  protected readonly averageColor = computed(() => blurHashAverageColor(this.blurHash()));
  protected readonly placeholder = signal<string | null>(null);

  constructor() {
    // Browser only, after hydration: upgrade the flat average color to the decoded blur.
    afterRenderEffect(() => {
      const url = this.decoder.toDataUrl(this.blurHash(), this.ratio());
      this.placeholder.set(url ? `url("${url}")` : null);
    });
  }
}
