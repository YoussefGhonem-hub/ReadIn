import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { from, switchMap } from 'rxjs';
import { API_BASE_URL } from '../api/api.config';
import { AuthService } from '../auth/auth.service';
import { HydrationWindow } from './hydration-window';

/**
 * Adds `Authorization: Bearer <Firebase ID token>` to API calls when signed in (SPEC §9.2).
 * While hydrating, GETs go out anonymously so they are answered from the SSR transfer cache; pages that personalize
 * (e.g. Home) refresh once the session is known.
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  if (!req.url.startsWith(inject(API_BASE_URL)) || req.headers.has('Authorization')) return next(req);
  if (req.method === 'GET' && inject(HydrationWindow).isOpen) return next(req);
  const auth = inject(AuthService);
  return from(auth.getIdToken()).pipe(
    switchMap((token) => next(token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req)),
  );
};
