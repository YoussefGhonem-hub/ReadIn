import { ApplicationConfig, Provider, mergeApplicationConfig } from '@angular/core';
import { HTTP_TRANSFER_CACHE_ORIGIN_MAP } from '@angular/common/http';
import { provideServerRendering, withRoutes } from '@angular/ssr';
import { environment } from '../environments/environment';
import { appConfig } from './app.config';
import { serverRoutes } from './app.routes.server';
import { API_BASE_URL } from './core/api/api.config';

/**
 * During SSR the API can be reached over an internal address (e.g. `http://readin-api:8080/api/v1`) via
 * `READIN_API_INTERNAL_URL`. The origin map keeps the HTTP transfer cache valid, so the browser reuses those
 * responses instead of fetching them again from the public URL.
 */
function internalApiProviders(): Provider[] {
  const internal = process.env['READIN_API_INTERNAL_URL'];
  if (!internal) return [];
  return [
    { provide: API_BASE_URL, useValue: internal },
    { provide: HTTP_TRANSFER_CACHE_ORIGIN_MAP, useValue: { [new URL(internal).origin]: new URL(environment.apiBaseUrl).origin } },
  ];
}

const serverConfig: ApplicationConfig = {
  providers: [provideServerRendering(withRoutes(serverRoutes)), ...internalApiProviders()],
};

export const config = mergeApplicationConfig(appConfig, serverConfig);
