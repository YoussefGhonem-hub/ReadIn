import { Injectable, inject } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { isApiError } from '../api/api.config';

/**
 * Stable error codes from docs/api/contract-v1.md. Each one has an `errors.{code}` string in public/i18n/ar.json and
 * en.json (checked by error-messages.spec.ts), so new codes must be added here and translated in both languages.
 */
export const CONTRACT_ERROR_CODES = [
  'validation.failed',
  'rate_limited',
  'auth.unauthorized',
  'auth.forbidden',
  // Phone + password sign in and recovery (SPEC §9, ADR 0007, ADR 0009)
  'auth.invalid_credentials',
  'auth.locked_out',
  'auth.phone_taken',
  'auth.refresh_invalid',
  'auth.recovery_invalid',
  'auth.recovery_locked',
  'auth.recovery_disabled',
  'auth.reset_token_invalid',
  'auth.wrong_password',
  'auth.pin_already_set',
  'auth.phone_unchanged',
  // Google and Apple (ADR 0012)
  'auth.external_invalid',
  'auth.provider_disabled',
  'auth.external_not_linked',
  'auth.external_in_use',
  'auth.external_conflict',
  'auth.external_login_not_found',
  'auth.last_sign_in_method',
  'auth.phone_sign_in_exists',
  'auth.confirmation_required',
  'auth.external_mismatch',
  'provider.invalid',
  'phone.invalid',
  'password.too_short',
  'password.too_long',
  'password.letter_required',
  'password.digit_required',
  'password.too_common',
  'password.contains_phone',
  'pin.length',
  'pin.digits_only',
  'pin.weak',
  'user.suspended',
  'user.not_found',
  'user.username_taken',
  'user.username_invalid',
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
  // Reactions, saved and follow (F10, F12, F13)
  'reaction.invalid',
  'collection.name_taken',
  'collection.limit',
  'collection.not_found',
  'follow.self',
  // Comments, reports and moderation (F11, F22 hooks)
  'comment.not_found',
  'comment.not_owner',
  'comment.not_available',
  'comment.pin_reply',
  'comment.pin_not_author',
  'comment.pin_conflict',
  'comment.article_limit',
  'comment.duplicate',
  'comment.empty',
  'comment.too_long',
  'report.target_not_found',
  'report.own_content',
  'report.target_not_supported',
  'report.target_invalid',
  'report.reason_invalid',
  'moderation.action_invalid',
  // Profile (F14)
  'profile.stats_private',
  'profile.avatar_invalid',
  'profile.expertise_invalid',
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
