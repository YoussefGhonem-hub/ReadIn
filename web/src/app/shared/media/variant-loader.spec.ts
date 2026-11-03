import { ImageLoaderConfig } from '@angular/common';
import { FALLBACK_SRC_WIDTH, ImageVariant, pickVariant, sortVariants, variantImageLoader, variantSrcset } from './variant-loader';

/** Post image widths (ADR 0011): 320/640/1080/1600, never upscaled. */
const variants: ImageVariant[] = [
  { width: 1080, url: 'https://api.test/uploads/a/1080.webp' },
  { width: 320, url: 'https://api.test/uploads/a/320.webp' },
  { width: 1600, url: 'https://api.test/uploads/a/1600.webp' },
  { width: 640, url: 'https://api.test/uploads/a/640.webp' },
];
const urls = new Set(variants.map((v) => v.url));

function load(config: Partial<ImageLoaderConfig>): string {
  return variantImageLoader({ src: 'https://api.test/uploads/a/1600.webp', ...config } as ImageLoaderConfig);
}

describe('variant image loader (NgOptimizedImage IMAGE_LOADER)', () => {
  it('builds ngSrcset from the widths that exist, ascending', () => {
    expect(variantSrcset(variants)).toBe('320w, 640w, 1080w, 1600w');
    expect(variantSrcset([{ width: 480, url: 'x' }])).toBe('480w');
    expect(variantSrcset([])).toBe('');
  });

  it('returns the exact variant for every srcset width', () => {
    for (const v of sortVariants(variants)) {
      expect(load({ width: v.width, loaderParams: { variants } })).toBe(v.url);
    }
  });

  it('picks the smallest variant that is at least as wide as requested', () => {
    expect(load({ width: 400, loaderParams: { variants } })).toBe('https://api.test/uploads/a/640.webp');
    expect(load({ width: 641, loaderParams: { variants } })).toBe('https://api.test/uploads/a/1080.webp');
    expect(load({ width: 1, loaderParams: { variants } })).toBe('https://api.test/uploads/a/320.webp');
  });

  it('never requests a width that is not in variants (falls back to the largest)', () => {
    for (let width = 1; width <= 4000; width += 37) {
      expect(urls.has(load({ width, loaderParams: { variants } }))).toBe(true);
    }
    expect(load({ width: 3840, loaderParams: { variants } })).toBe('https://api.test/uploads/a/1600.webp');
  });

  it('uses a mid-size variant for the plain src fallback', () => {
    expect(load({ loaderParams: { variants } })).toBe(pickVariant(variants, FALLBACK_SRC_WIDTH)!.url);
    expect(load({ loaderParams: { variants } })).toBe('https://api.test/uploads/a/640.webp');
  });

  it('loads the largest file in the full-screen viewer', () => {
    expect(load({ loaderParams: { variants, pick: 'largest' } })).toBe('https://api.test/uploads/a/1600.webp');
    expect(load({ width: 320, loaderParams: { variants, pick: 'largest' } })).toBe('https://api.test/uploads/a/1600.webp');
  });

  it('only knows the widths a small original produced (no upscaling)', () => {
    const small = [
      { width: 320, url: 'https://api.test/uploads/b/320.webp' },
      { width: 500, url: 'https://api.test/uploads/b/500.webp' },
    ];
    expect(variantSrcset(small)).toBe('320w, 500w');
    expect(load({ width: 1080, loaderParams: { variants: small } })).toBe('https://api.test/uploads/b/500.webp');
  });

  it('falls back to ngSrc when there are no variants', () => {
    expect(load({ width: 640, loaderParams: { variants: [] } })).toBe('https://api.test/uploads/a/1600.webp');
    expect(load({ width: 640 })).toBe('https://api.test/uploads/a/1600.webp');
  });

  it('ignores duplicate and invalid widths', () => {
    expect(sortVariants([...variants, { width: 640, url: 'dup' }, { width: 0, url: 'zero' }]).map((v) => v.width)).toEqual([320, 640, 1080, 1600]);
  });
});
