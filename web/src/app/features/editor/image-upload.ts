import { HttpEventType } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { from, switchMap } from 'rxjs';
import { isApiError } from '../../core/api/api.config';
import { ImageUploadPurpose, MediaApi } from '../../core/api/media.api';
import { MediaAssetDto, MediaVariantDto } from '../../core/api/models';
import { ImageCompressor } from '../../shared/media/image-compressor';
import { MAX_IMAGE_BYTES, isImageFile } from './attachment-draft';

/** The rendition an RDoc image or the cover points at: the widest one (variants are ascending). */
export function largestVariant(asset: MediaAssetDto): MediaVariantDto | null {
  return asset.variants.length ? asset.variants[asset.variants.length - 1] : null;
}

/**
 * Image uploads of the editor (cover and image blocks): compressed on the device (F26: max 2048 px, quality 85), then
 * `POST /uploads/images` with progress. Rejects with a stable error code (string); aborting cancels.
 */
@Injectable({ providedIn: 'root' })
export class ImageUploader {
  private readonly media = inject(MediaApi);
  private readonly compressor = inject(ImageCompressor);

  upload(file: File, purpose: ImageUploadPurpose, onProgress: (fraction: number) => void, signal: AbortSignal): Promise<MediaAssetDto> {
    return new Promise<MediaAssetDto>((resolve, reject) => {
      if (!isImageFile(file)) {
        reject('media.unsupported_type');
        return;
      }
      const subscription = from(this.compressor.compress(file, signal))
        .pipe(
          switchMap((blob) => {
            if (blob.size > MAX_IMAGE_BYTES) throw { code: 'media.too_large' };
            return this.media.uploadImage(blob, file.name, purpose);
          }),
        )
        .subscribe({
          next: (event) => {
            if (event.type === HttpEventType.UploadProgress) onProgress(event.total ? event.loaded / event.total : 0);
            else if (event.type === HttpEventType.Response && event.body) {
              const asset = event.body;
              if (asset.status === 'failed' || !largestVariant(asset)) reject(asset.failureReason ?? 'media.processing_failed');
              else resolve(asset);
            }
          },
          error: (error: unknown) => reject(isApiError(error) ? error.code : ((error as { code?: string } | null)?.code ?? 'unknown')),
        });
      signal.addEventListener('abort', () => {
        subscription.unsubscribe();
        reject('canceled');
      });
    });
  }
}
