import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, PLATFORM_ID, computed, effect, inject, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { firstValueFrom } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from '../api/api.config';
import type { ModerationSummaryDto } from '../api/models';
import { SessionStore } from '../auth/session.store';

export const MODERATION_PERMISSION = 'moderation.manage';

/**
 * Targets with open reports (`GET /moderation/summary`, F22) for the Moderation nav badge and the queue's type chips.
 * Loaded in the browser for accounts with `moderation.manage`, again after every moderator action. In the initial
 * bundle (the side nav), so it calls HttpClient directly instead of pulling in ModerationApi.
 */
@Injectable({ providedIn: 'root' })
export class ModerationSummaryStore {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly session = inject(SessionStore);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  private readonly _open = signal<ModerationSummaryDto['open'] | null>(null);
  /** Open targets per type, or null until loaded (and for everyone without the permission). */
  readonly open = this._open.asReadonly();
  readonly total = computed(() => this._open()?.total ?? 0);
  readonly canModerate = computed(() => this.session.permissions().has(MODERATION_PERMISSION));
  private requested = 0;

  constructor() {
    const userId = computed(() => (this.canModerate() ? (this.session.me()?.id ?? null) : null));
    effect(() => {
      const id = userId();
      untracked(() => {
        if (id) void this.refresh();
        else this._open.set(null);
      });
    });
  }

  /** Loads the counts again (a failure keeps the last ones). */
  async refresh(): Promise<void> {
    if (!this.isBrowser || !this.canModerate()) return;
    const request = ++this.requested;
    try {
      const summary = await firstValueFrom(
        this.http.get<ModerationSummaryDto>(`${this.base}/moderation/summary`, { context: new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true) }),
      );
      if (request === this.requested && this.canModerate()) this._open.set(summary.open);
    } catch {
      /* the badge just stays as it was */
    }
  }
}
