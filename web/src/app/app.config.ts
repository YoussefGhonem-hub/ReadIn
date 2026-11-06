import { ApplicationConfig, Injector, PLATFORM_ID, inject, provideAppInitializer, provideBrowserGlobalErrorListeners } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { provideHttpClient, withFetch, withInterceptors } from '@angular/common/http';
import { provideClientHydration, withEventReplay, withHttpTransferCacheOptions } from '@angular/platform-browser';
import { RouteReuseStrategy, TitleStrategy, provideRouter, withComponentInputBinding, withInMemoryScrolling, withRouterConfig } from '@angular/router';
import { routes } from './app.routes';
import { AuthService } from './core/auth/auth.service';
import { API_INTERCEPTORS } from './core/http/api-interceptors';
import { PageTitleStrategy } from './core/i18n/page-title.strategy';
import { provideI18n } from './core/i18n/transloco.providers';
import { AppHistory } from './core/platform/app-history';
import { TappedNotification } from './core/push/tapped-notification';
import { FeedRouteReuse } from './features/feed/feed-route-reuse';
import { provideMediaViewerHistory } from './shared/media/viewer-history';
import { startAppIcons, withAppIcons } from './shared/ui/app-icons';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(
      // Each lazy page also waits for the app's icons, which load in parallel (shared/ui/app-icons.ts).
      withAppIcons(routes),
      withComponentInputBinding(),
      withInMemoryScrolling({ scrollPositionRestoration: 'enabled', anchorScrolling: 'enabled' }),
      withRouterConfig({ paramsInheritanceStrategy: 'always' }),
    ),
    // Home stays alive while you read and comes back as you left it on Back (F34).
    { provide: RouteReuseStrategy, useExisting: FeedRouteReuse },
    // The full-screen viewer's own history entry never reaches the router, so closing it keeps the scroll (F26).
    provideMediaViewerHistory(),
    // Route titles are i18n keys and follow the UI language.
    { provide: TitleStrategy, useExisting: PageTitleStrategy },
    provideHttpClient(withFetch(), withInterceptors(API_INTERCEPTORS)),
    // GETs made during SSR are replayed on hydration; requests carrying a user token always go to the network.
    provideClientHydration(withEventReplay(), withHttpTransferCacheOptions({ includeRequestsWithAuthHeaders: false })),
    ...provideI18n(),
    // Tracks the tab's history from the first navigation, for in-app Back buttons (the reader's, F04).
    provideAppInitializer(() => {
      inject(AppHistory);
    }),
    // Restore the session (POST /auth/refresh) in the browser without blocking bootstrap; a no-op during SSR.
    provideAppInitializer(() => inject(AuthService).init()),
    // In the browser: the app's icons start loading at once; the live badge and web push (SPEC §21) follow the
    // session from their own chunks, after the first page. A tapped push's `?notification=` leaves the address first.
    provideAppInitializer(() => {
      if (!isPlatformBrowser(inject(PLATFORM_ID))) return;
      const injector = inject(Injector);
      startAppIcons(injector);
      inject(TappedNotification).capture();
      import('./core/realtime/realtime.service').then(({ RealtimeService }) => injector.get(RealtimeService).init()).catch(() => undefined);
      import('./core/push/push.service').then(({ PushService }) => injector.get(PushService).init()).catch(() => undefined);
    }),
  ],
};
