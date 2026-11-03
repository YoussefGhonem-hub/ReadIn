import { ImageLoader, ImageLoaderConfig } from '@angular/common';

/** One exact file per width (MediaVariantDto, or a PDF page's thumb/view rendition). */
export interface ImageVariant {
  width: number;
  url: string;
}

/**
 * `loaderParams` for `NgOptimizedImage` with {@link variantImageLoader}:
 * - `fit` (default): responsive — `ngSrcset` lists the available widths and the browser picks the smallest that fits.
 * - `largest`: the full-screen viewer always loads the largest rendition.
 */
export interface VariantLoaderParams {
  variants: readonly ImageVariant[];
  pick?: 'fit' | 'largest';
}

/** Width used for the plain `src` fallback (browsers with `srcset` support never use it). */
export const FALLBACK_SRC_WIDTH = 640;

/** Ascending by width, one entry per width. */
export function sortVariants(variants: readonly ImageVariant[]): ImageVariant[] {
  const byWidth = new Map<number, ImageVariant>();
  for (const v of variants) if (v.width > 0 && v.url && !byWidth.has(v.width)) byWidth.set(v.width, v);
  return [...byWidth.values()].sort((a, b) => a.width - b.width);
}

/**
 * The variant for a requested width: the exact one, else the smallest that is at least that wide, else the largest.
 * Variants are real files, so this never returns a width that does not exist.
 */
export function pickVariant(variants: readonly ImageVariant[], width?: number | null): ImageVariant | null {
  const sorted = sortVariants(variants);
  if (!sorted.length) return null;
  const largest = sorted[sorted.length - 1];
  if (!width || width <= 0) return largest;
  return sorted.find((v) => v.width >= width) ?? largest;
}

/** `ngSrcset` from the widths that exist, e.g. `"320w, 640w, 1080w, 1600w"`. Empty when there are no variants. */
export function variantSrcset(variants: readonly ImageVariant[]): string {
  return sortVariants(variants)
    .map((v) => `${v.width}w`)
    .join(', ');
}

export function sameVariants(a: readonly ImageVariant[], b: readonly ImageVariant[]): boolean {
  return a.length === b.length && a.every((v, i) => v.width === b[i].width && v.url === b[i].url);
}

/** `IMAGE_LOADER` for media assets: maps each srcset width to the matching variant URL (see {@link pickVariant}). */
export const variantImageLoader: ImageLoader = (config: ImageLoaderConfig) => {
  const params = config.loaderParams as VariantLoaderParams | undefined;
  const variants = params?.variants ?? [];
  if (!variants.length) return config.src;
  if (params?.pick === 'largest') return pickVariant(variants)!.url;
  return pickVariant(variants, config.width ?? FALLBACK_SRC_WIDTH)!.url;
};
