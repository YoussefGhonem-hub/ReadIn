import { ApplicationConfig, inject, provideAppInitializer, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { provideClientHydration, withEventReplay, withHttpTransferCacheOptions } from '@angular/platform-browser';
import { TitleStrategy, provideRouter, withComponentInputBinding, withInMemoryScrolling, withRouterConfig } from '@angular/router';
import { routes } from './app.routes';
import { AuthService } from './core/auth/auth.service';
import { API_INTERCEPTORS } from './core/http/api-interceptors';
import { PageTitleStrategy } from './core/i18n/page-title.strategy';
import { provideI18n } from './core/i18n/transloco.providers';
import { AppHistory } from './core/platform/app-history';
import { PushService } from './core/push/push.service';
import { RealtimeService } from './core/realtime/realtime.service';
import { provideAppIcons } from './shared/ui/icons';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(
      routes,
      withComponentInputBinding(),
      withInMemoryScrolling({ scrollPositionRestoration: 'enabled', anchorScrolling: 'enabled' }),
      withRouterConfig({ paramsInheritanceStrategy: 'always' }),
    ),
    // Route titles are i18n keys and follow the UI language.
    { provide: TitleStrategy, useExisting: PageTitleStrategy },
    provideHttpClient(withFetch(), withInterceptors(API_INTERCEPTORS)),
    // GETs made during SSR are replayed on hydration; requests carrying a user token always go to the network.
    provideClientHydration(withEventReplay(), withHttpTransferCacheOptions({ includeRequestsWithAuthHeaders: false })),
    ...provideI18n(),
    provideAppIcons(),
    // Tracks the tab's history from the first navigation, for in-app Back buttons (the reader's, F04).
    provideAppInitializer(() => {
      inject(AppHistory);
    }),
    // Restore the session (POST /auth/refresh) in the browser without blocking bootstrap; a no-op during SSR.
    provideAppInitializer(() => inject(AuthService).init()),
    // Live badge and web push follow the session; both are no-ops during SSR (SPEC §21).
    provideAppInitializer(() => {
      inject(RealtimeService).init();
      void inject(PushService).init();
    }),
  ],
};
