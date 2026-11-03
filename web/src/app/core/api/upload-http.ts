import { HttpClient, provideHttpClient, withInterceptors, withXhr } from '@angular/common/http';
import { EnvironmentInjector, InjectionToken, createEnvironmentInjector, inject } from '@angular/core';
import { API_INTERCEPTORS } from '../http/api-interceptors';

/**
 * HttpClient for uploads. The app uses the fetch backend, which cannot report upload progress, so uploads go through
 * XHR in a child injector with the same interceptors (Accept-Language, bearer token, ProblemDetails → ApiError).
 */
export const UPLOAD_HTTP = new InjectionToken<HttpClient>('UPLOAD_HTTP', {
  providedIn: 'root',
  factory: () =>
    createEnvironmentInjector([provideHttpClient(withXhr(), withInterceptors(API_INTERCEPTORS))], inject(EnvironmentInjector)).get(
      HttpClient,
    ),
});
