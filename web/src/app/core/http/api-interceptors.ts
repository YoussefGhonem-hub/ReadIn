import { HttpInterceptorFn } from '@angular/common/http';
import { authInterceptor } from './auth.interceptor';
import { errorInterceptor } from './error.interceptor';
import { languageInterceptor } from './language.interceptor';

/**
 * Interceptor chain for every API call, shared by the app's HttpClient and the upload client (core/api/upload-http.ts).
 * The error interceptor wraps the auth interceptor, so it only sees (and toasts) what is left after a token refresh
 * and retry.
 */
export const API_INTERCEPTORS: HttpInterceptorFn[] = [languageInterceptor, errorInterceptor, authInterceptor];
