import { Injectable, inject } from '@angular/core';
import { isApiError } from '../../core/api/api.config';
import { ErrorMessages } from '../../core/i18n/error-messages';

/**
 * The message for a failed report or moderation request (F22). Contract codes translate as `errors.{code}`; a
 * validation failure uses its first `report.*` / `moderation.*` field code (e.g. `moderation.note_required`); a
 * suspended account says until when.
 */
@Injectable({ providedIn: 'root' })
export class ModerationErrors {
  private readonly errors = inject(ErrorMessages);

  message(error: unknown): string {
    if (isApiError(error) && error.code === 'validation.failed') {
      const first = Object.values(error.validationErrors).flat()[0];
      if (first && (first.startsWith('report.') || first.startsWith('moderation.'))) return this.errors.forCode(first);
    }
    return this.errors.forError(error);
  }
}
