import { Injector } from '@angular/core';
import { Route, Routes } from '@angular/router';
import { Observable, firstValueFrom, isObservable } from 'rxjs';

/**
 * The app's Lucide icons (shared/ui/icons.ts, `<svg lucideIcon>`) are a chunk of their own, so neither they nor the
 * `@lucide/angular` runtime are in the initial bundle; the shell draws its few icons itself (shell-icon.ts). In the
 * browser they start loading at bootstrap and are in the root registry before anything that uses them renders: every
 * lazy route waits for them alongside its own chunk ({@link withAppIcons}), and so do the panels the app root and the
 * top bar load themselves ({@link appIconsReady}). The server renders with the whole set (app.config.server.ts).
 */
let root: Injector | null = null;
let loading: Promise<void> | null = null;

/** Starts loading the icons into this browser app's root registry. Called once from an app initializer. */
export function startAppIcons(injector: Injector): void {
  root = injector;
  appIconsReady().catch(() => undefined); // offline: the next page or panel asks again
}

/** Resolves once the icons are registered. Resolves at once where nothing loads them (SSR, unit tests). */
export function appIconsReady(): Promise<void> {
  const injector = root;
  if (!injector) return Promise.resolve();
  loading ??= import('./icons').then(
    ({ registerAppIcons }) => registerAppIcons(injector),
    (error: unknown) => {
      loading = null;
      throw error;
    },
  );
  return loading;
}

/** The routes with every `loadComponent` and `loadChildren` also waiting for the icons (fetched in parallel). */
export function withAppIcons(routes: Routes): Routes {
  return routes.map((route): Route => {
    const { loadComponent, loadChildren, children } = route;
    return {
      ...route,
      ...(loadComponent && { loadComponent: () => withIcons(loadComponent()) }),
      ...(loadChildren && { loadChildren: () => withIcons(loadChildren()) }),
      ...(children && { children: withAppIcons(children) }),
    };
  });
}

function withIcons<T>(load: T | Promise<T> | Observable<T>): Promise<T> {
  return Promise.all([isObservable(load) ? firstValueFrom(load) : load, appIconsReady()]).then(([loaded]) => loaded);
}
