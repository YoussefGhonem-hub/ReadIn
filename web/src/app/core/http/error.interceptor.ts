import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { catchError, throwError } from 'rxjs';
import { API_BASE_URL, ApiError, SILENT_ERRORS } from '../api/api.config';
import { ErrorMessages } from '../i18n/error-messages';
import { ToastService } from '../../shared/ui/toast/toast.service';

/**
 * Normalizes API failures to `ApiError` and, unless the request opted out with `SILENT_ERRORS`,
 * shows a toast translated from the ProblemDetails `code` (SPEC §6.5).
 */
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  if (!req.url.startsWith(inject(API_BASE_URL))) return next(req);
  const isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  const toasts = inject(ToastService);
  const messages = inject(ErrorMessages);

  return next(req).pipe(
    catchError((error: unknown) => {
      if (!(error instanceof HttpErrorResponse)) return throwError(() => error);
      const apiError = ApiError.from(error);
      if (isBrowser && !req.context.get(SILENT_ERRORS)) {
        toasts.error(messages.forError(apiError));
      }
      return throwError(() => apiError);
    }),
  );
};
