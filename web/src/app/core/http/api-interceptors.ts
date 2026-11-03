import { HttpInterceptorFn } from '@angular/common/http';
import { authInterceptor } from './auth.interceptor';
import { errorInterceptor } from './error.interceptor';
import { languageInterceptor } from './language.interceptor';

/** Interceptor chain for every API call, shared by the app's HttpClient and the upload client (core/api/upload-http.ts). */
export const API_INTERCEPTORS: HttpInterceptorFn[] = [languageInterceptor, authInterceptor, errorInterceptor];
