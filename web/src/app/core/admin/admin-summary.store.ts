import { HttpClient, HttpContext } from '@angular/common/http';
import { DOCUMENT, Injectable, PLATFORM_ID, computed, effect, inject, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { firstValueFrom } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from '../api/api.config';
import type { AdminSummaryDto } from '../api/models';
import { SessionStore } from '../auth/session.store';

export const ADMIN_PERMISSION = 'admin.access';
/** The badge refreshes this often while the tab is visible (SPEC F23). */
export const ADMIN_SUMMARY_INTERVAL_MS = 60_000;

/**
 * The admin console entry's badge (F23): open reports + open tickets + pending verification requests, from
 * `GET /admin/summary`. Only in the browser and only for accounts with `admin.access`: loaded when the session has the
 * permission, again when the tab becomes visible, every 60 seconds while it is visible, and whenever a screen asks
 * (the Me menu opening, an admin action). A failure keeps the last numbers. It calls HttpClient directly, so the Me
 * button's chunk doesn't pull in the console's API.
 */
@Injectable({ providedIn: 'root' })
export class AdminSummaryStore {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly session = inject(SessionStore);
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  private readonly _summary = signal<AdminSummaryDto | null>(null);
  /** The latest summary, or null until loaded (and for everyone without the permission). */
  readonly summary = this._summary.asReadonly();
  readonly total = computed(() => this._summary()?.total ?? 0);
  readonly canAccess = computed(() => this.session.permissions().has(ADMIN_PERMISSION));
  private requested = 0;

  constructor() {
    const userId = computed(() => (this.canAccess() ? (this.session.me()?.id ?? null) : null));
    effect((onCleanup) => {
      const id = userId();
      if (!id || !this.isBrowser) {
        untracked(() => this._summary.set(null));
        return;
      }
      untracked(() => void this.refresh());
      const visible = () => this.document.visibilityState !== 'hidden';
      const timer = setInterval(() => {
        if (visible()) void this.refresh();
      }, ADMIN_SUMMARY_INTERVAL_MS);
      const onVisibility = () => {
        if (visible()) void this.refresh();
      };
      this.document.addEventListener('visibilitychange', onVisibility);
      onCleanup(() => {
        clearInterval(timer);
        this.document.removeEventListener('visibilitychange', onVisibility);
      });
    });
  }

  /** Loads the counts again; a newer request wins over a slower older one. */
  async refresh(): Promise<void> {
    if (!this.isBrowser || !this.canAccess()) return;
    const request = ++this.requested;
    try {
      const summary = await firstValueFrom(
        this.http.get<AdminSummaryDto>(`${this.base}/admin/summary`, { context: new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true) }),
      );
      if (request === this.requested && this.canAccess()) this._summary.set(summary);
    } catch {
      /* the badge stays as it was */
    }
  }
}
