import { HttpErrorResponse, HttpInterceptorFn, HttpRequest } from '@angular/common/http';
import { PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { catchError, from, switchMap, throwError } from 'rxjs';
import { API_BASE_URL } from '../api/api.config';
import { AuthService } from '../auth/auth.service';
import { HydrationWindow } from './hydration-window';

/**
 * `/auth/*` calls that authenticate with the refresh cookie or a credential, never with the access token (only
 * `/auth/logout-all` needs a Bearer). They are never retried after a refresh, so a failing refresh can't loop.
 */
export function isSessionCall(path: string): boolean {
  return path.startsWith('/auth/') && !path.startsWith('/auth/logout-all');
}

function withBearer<T>(req: HttpRequest<T>, token: string): HttpRequest<T> {
  return req.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
}

/**
 * Adds `Authorization: Bearer <access token>` to API calls when signed in (SPEC §9.3). On a 401 it refreshes once —
 * single-flight, shared by every request that failed with the same token — and retries; if the session can't be
 * renewed AuthService signs out locally and the original error goes on to the error interceptor.
 * While hydrating, GETs go out anonymously so they are answered from the SSR transfer cache; pages that personalize
 * (e.g. Home) refresh once the session is known. The server never sends a token (SSR is anonymous).
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const base = inject(API_BASE_URL);
  if (!req.url.startsWith(base) || req.headers.has('Authorization')) return next(req);
  if (!isPlatformBrowser(inject(PLATFORM_ID))) return next(req);
  if (isSessionCall(req.url.slice(base.length))) return next(req);
  if (req.method === 'GET' && inject(HydrationWindow).isOpen) return next(req);

  const auth = inject(AuthService);
  return from(auth.tokenForRequest()).pipe(
    switchMap((token) => {
      if (!token) return next(req);
      return next(withBearer(req, token)).pipe(
        catchError((error: unknown) => {
          if (!(error instanceof HttpErrorResponse) || error.status !== 401) return throwError(() => error);
          return from(auth.renewAfterUnauthorized(token)).pipe(
            switchMap((fresh) => (fresh ? next(withBearer(req, fresh)) : throwError(() => error))),
          );
        }),
      );
    }),
  );
};
