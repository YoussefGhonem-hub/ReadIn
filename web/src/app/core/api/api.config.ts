import { HttpContextToken, HttpErrorResponse } from '@angular/common/http';
import { InjectionToken } from '@angular/core';
import { environment } from '../../../environments/environment';
import { ProblemDetails } from './models';

export const API_BASE_URL = new InjectionToken<string>('API_BASE_URL', {
  providedIn: 'root',
  factory: () => environment.apiBaseUrl,
});

/** Set on a request to stop the error interceptor from showing a toast (the caller renders its own error state). */
export const SILENT_ERRORS = new HttpContextToken<boolean>(() => false);

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
