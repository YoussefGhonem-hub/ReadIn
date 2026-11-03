import { Injectable, inject } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { isApiError } from '../api/api.config';

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
