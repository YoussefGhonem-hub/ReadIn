import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { API_BASE_URL } from '../api/api.config';
import { LanguageService } from '../i18n/language.service';

/** `Accept-Language: ar | en` drives localized error messages and taxonomy names (SPEC §17.1). */
export const languageInterceptor: HttpInterceptorFn = (req, next) => {
  if (!req.url.startsWith(inject(API_BASE_URL))) return next(req);
  return next(req.clone({ setHeaders: { 'Accept-Language': inject(LanguageService).lang() } }));
};
