import { Injectable, inject } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { isApiError } from '../api/api.config';

/**
 * Stable error codes from docs/api/contract-v1.md. Each one has an `errors.{code}` string in public/i18n/ar.json and
 * en.json (checked by error-messages.spec.ts), so new codes must be added here and translated in both languages.
 */
export const CONTRACT_ERROR_CODES = [
  'validation.failed',
  'auth.unauthorized',
  'auth.forbidden',
  'user.suspended',
  'user.not_synced',
  'user.not_found',
  'user.username_taken',
  'user.interests.min_three',
  'field.not_found',
  'article.not_found',
  'article.sources_required',
  'server.error',
  'media.purpose_invalid',
  'media.file_required',
  'media.too_large',
  'media.unsupported_type',
  'media.dimensions_too_large',
  'media.image_corrupted',
  'media.pdf_encrypted',
  'media.pdf_corrupted',
  'media.pdf_too_many_pages',
  'media.quota_daily',
  'media.quota_storage',
  'media.not_found',
  'media.in_use',
  'media.download_not_allowed',
  'media.processing_failed',
  'media.processing_timeout',
  'attachments.mixed_kinds',
  'attachments.too_many_images',
  'attachments.single_document',
  'attachments.alt_text_required',
  'attachments.alt_text_too_long',
  'attachments.caption_too_long',
  'attachments.title_required',
  'attachments.title_too_long',
  'attachments.asset_not_found',
  'attachments.asset_not_ready',
  'attachments.duplicate_asset',
] as const;

/** Translates stable API error codes (e.g. `user.suspended`) into the active UI language. */
@Injectable({ providedIn: 'root' })
export class ErrorMessages {
  private readonly transloco = inject(TranslocoService);

  forCode(code: string, fallback?: string | null): string {
    const key = `errors.${code}`;
    const text = this.transloco.translate(key);
    if (text && text !== key) return text;
    return fallback || this.transloco.translate('errors.unknown');
  }

  forError(error: unknown): string {
    return isApiError(error) ? this.forCode(error.code, error.problem?.title) : this.transloco.translate('errors.unknown');
  }
}
