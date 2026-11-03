import { HttpContext, HttpContextToken, HttpErrorResponse, HttpHeaders } from '@angular/common/http';
import { InjectionToken } from '@angular/core';
import { environment } from '../../../environments/environment';
import { ProblemDetails } from './models';

export const API_BASE_URL = new InjectionToken<string>('API_BASE_URL', {
  providedIn: 'root',
  factory: () => environment.apiBaseUrl,
});

/** Set on a request to stop the error interceptor from showing a toast (the caller renders its own error state). */
export const SILENT_ERRORS = new HttpContextToken<boolean>(() => false);

/**
 * Set on GETs that only make sense for the signed-in user (Following, Saved, collections, suggestions). SSR never makes
 * them, so they are never in its transfer cache: the token goes out even while the page is still hydrating.
 */
export const WITH_SESSION = new HttpContextToken<boolean>(() => false);

/** Marks the web's session calls; the API only reads (and sets) the refresh token cookie when it is present. */
export const CLIENT_HEADER = 'X-ReadIn-Client';

/**
 * Options for calls that read or rotate the session (SPEC §9.3, ADR 0007): every `/auth/*` call and
 * `PUT /me/password`, `PUT /me/phone`, `DELETE /me`. The API is another origin in development, so the HttpOnly
 * `readin_refresh` cookie only travels with `withCredentials`. Silent by default: these forms show their own errors.
 */
export function webSessionOptions(options: { silent?: boolean } = {}): {
  withCredentials: true;
  headers: HttpHeaders;
  context: HttpContext;
} {
  return {
    withCredentials: true,
    headers: new HttpHeaders({ [CLIENT_HEADER]: 'web' }),
    context: new HttpContext().set(SILENT_ERRORS, options.silent ?? true),
  };
}

/** Normalized API error thrown by the error interceptor. `code` is the stable, translatable error code. */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    readonly problem: ProblemDetails | null,
  ) {
    super(problem?.title ?? code);
    this.name = 'ApiError';
  }

  get validationErrors(): Record<string, string[]> {
    return this.problem?.errors ?? {};
  }

  static from(error: HttpErrorResponse): ApiError {
    const body = error.error;
    const problem: ProblemDetails | null = body && typeof body === 'object' ? (body as ProblemDetails) : null;
    return new ApiError(error.status, problem?.code ?? ApiError.codeForStatus(error.status), problem);
  }

  private static codeForStatus(status: number): string {
    if (status === 0) return 'network';
    if (status === 401) return 'auth.unauthorized';
    if (status === 403) return 'auth.forbidden';
    if (status >= 500) return 'server.error';
    return 'unknown';
  }
}

export function isApiError(error: unknown): error is ApiError {
  return error instanceof ApiError;
}
