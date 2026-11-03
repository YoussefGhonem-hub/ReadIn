import { DOCUMENT, Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

/** Longest edge after client-side resizing (F26: "max 2048px, quality 85, orientation fixed"). */
export const MAX_IMAGE_EDGE = 2048;
export const IMAGE_QUALITY = 0.85;
/**
 * browser-image-compression runs in a Web Worker that `importScripts` the library. It defaults to a CDN; we serve our
 * own copy instead (angular.json copies it from node_modules to `/vendor/`).
 */
export const COMPRESSION_WORKER_LIB = 'vendor/browser-image-compression.js';

/**
 * Resizes and re-encodes images in the browser before upload (spec 1.1), so phones don't upload 12 MP originals.
 * Any failure (e.g. HEIC that the browser can't decode) returns the original file: the server re-processes every
 * upload anyway and never trusts the client.
 */
@Injectable({ providedIn: 'root' })
export class ImageCompressor {
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  /** Rejects only when `signal` aborts (upload canceled). */
  async compress(file: File, signal?: AbortSignal): Promise<Blob> {
    if (!this.isBrowser) return file;
    try {
      const { default: imageCompression } = await import('browser-image-compression');
      const compressed = await imageCompression(file, {
        maxWidthOrHeight: MAX_IMAGE_EDGE,
        initialQuality: IMAGE_QUALITY,
        useWebWorker: true,
        libURL: new URL(COMPRESSION_WORKER_LIB, this.document.baseURI).href,
        preserveExif: false, // orientation is applied to the pixels; location and camera data are dropped
        signal,
      });
      // Already-optimized files can grow when re-encoded (or the browser can't encode the type): keep the original.
      return compressed.size > 0 && compressed.size <= file.size ? compressed : file;
    } catch (error) {
      if (signal?.aborted) throw error;
      return file;
    }
  }
}
