import { Injectable, inject } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { isApiError } from '../../core/api/api.config';
import { ErrorMessages } from '../../core/i18n/error-messages';

/**
 * The translation key for a failed comment, like, pin, report or moderation request. Contract codes map to
 * `errors.{code}` (translated in ar/en, see CONTRACT_ERROR_CODES); a plain `429` from the 10-a-minute limit gets a
 * comment-specific message; a validation failure uses its first field code (e.g. `report.reason_invalid`).
 */
export function commentErrorKey(error: unknown): string {
  if (!isApiError(error)) return 'errors.unknown';
  if (error.code === 'validation.failed') {
    const first = Object.values(error.validationErrors).flat()[0];
    return first && (first.startsWith('comment.') || first.startsWith('report.')) ? `errors.${first}` : 'errors.validation.failed';
  }
  if (error.status === 429 && !error.code.startsWith('comment.')) return 'comments.errors.tooFast';
  return `errors.${error.code}`;
}

/**
 * Translates {@link commentErrorKey}; unknown codes fall back to the API's title, then to "something went wrong". A
 * suspended account's message says until when.
 */
@Injectable({ providedIn: 'root' })
export class CommentErrors {
  private readonly transloco = inject(TranslocoService);
  private readonly errors = inject(ErrorMessages);

  message(error: unknown): string {
    if (isApiError(error) && error.code === 'user.suspended') return this.errors.forError(error); // says until when
    const key = commentErrorKey(error);
    if (key.startsWith('errors.')) return this.errors.forCode(key.slice('errors.'.length), isApiError(error) ? error.problem?.title : null);
    return this.transloco.translate(key);
  }
}
