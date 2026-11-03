import { DOCUMENT, Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { decode } from 'blurhash';

const BASE83 = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~';

function decode83(text: string): number | null {
  let value = 0;
  for (const ch of text) {
    const digit = BASE83.indexOf(ch);
    if (digit < 0) return null;
    value = value * 83 + digit;
  }
  return value;
}

/** True when `hash` has a valid BlurHash header and the length its component counts require. */
export function isValidBlurHash(hash: string | null | undefined): hash is string {
  if (!hash || hash.length < 6) return false;
  const sizeFlag = decode83(hash[0]);
  if (sizeFlag === null) return false;
  const componentsX = (sizeFlag % 9) + 1;
  const componentsY = Math.floor(sizeFlag / 9) + 1;
  return hash.length === 4 + 2 * componentsX * componentsY && decode83(hash) !== null;
}

/**
 * The average color of a BlurHash: its DC component, stored in characters 2–5 as a 24-bit sRGB integer.
 * Pure math (no canvas), so the server renders it as the image placeholder and the HTML stays stable through hydration.
 */
export function blurHashAverageColor(hash: string | null | undefined): string | null {
  if (!isValidBlurHash(hash)) return null;
  const value = decode83(hash.slice(2, 6))!;
  return `rgb(${value >> 16}, ${(value >> 8) & 255}, ${value & 255})`;
}

/** Size of the decoded placeholder; CSS scales it up (`background-size: cover`), which blurs it further. */
const PLACEHOLDER_SIZE = 32;
const CACHE_LIMIT = 300;

/** Decodes BlurHashes into tiny PNG data URLs, in the browser only (SSR uses {@link blurHashAverageColor}). */
@Injectable({ providedIn: 'root' })
export class BlurHashDecoder {
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly cache = new Map<string, string | null>();

  /** `null` on the server, for invalid hashes, or when canvas is unavailable. `ratio` is width / height. */
  toDataUrl(hash: string | null | undefined, ratio = 1): string | null {
    if (!this.isBrowser || !isValidBlurHash(hash)) return null;
    const width = ratio >= 1 ? PLACEHOLDER_SIZE : Math.max(4, Math.round(PLACEHOLDER_SIZE * ratio));
    const height = ratio >= 1 ? Math.max(4, Math.round(PLACEHOLDER_SIZE / ratio)) : PLACEHOLDER_SIZE;
    const key = `${hash}|${width}x${height}`;
    if (this.cache.has(key)) return this.cache.get(key)!;

    let url: string | null = null;
    try {
      const canvas = this.document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      const context = canvas.getContext('2d');
      if (context) {
        const image = context.createImageData(width, height);
        image.data.set(decode(hash, width, height));
        context.putImageData(image, 0, 0);
        url = canvas.toDataURL('image/png');
      }
    } catch {
      url = null;
    }
    if (this.cache.size >= CACHE_LIMIT) this.cache.delete(this.cache.keys().next().value!);
    this.cache.set(key, url);
    return url;
  }
}
