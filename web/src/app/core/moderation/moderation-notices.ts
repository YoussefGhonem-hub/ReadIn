import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, PLATFORM_ID, Type, computed, effect, inject, signal, untracked } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { firstValueFrom } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION, isApiError } from '../api/api.config';
import type { ModerationNoticeDto } from '../api/models';
import { SessionStore } from '../auth/session.store';
import { appIconsReady } from '../../shared/ui/app-icons';

/**
 * Warnings and "your article was hidden" notices (F22) for the signed-in user. Once the session is restored (and the
 * account's setup steps are done), `GET /me/moderation-notices` loads them, oldest first; when there are any, the
 * dialog's code loads and the app shows them one at a time until each is acknowledged ("فهمت"). In the initial bundle,
 * so it is small and calls HttpClient directly; the dialog itself is a lazy chunk.
 */
@Injectable({ providedIn: 'root' })
export class ModerationNotices {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly session = inject(SessionStore);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly context = () => new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true);

  private readonly _notices = signal<ModerationNoticeDto[]>([]);
  /** Unacknowledged notices, oldest first. */
  readonly notices = this._notices.asReadonly();
  /** The one on screen. */
  readonly current = computed(() => this._notices()[0] ?? null);
  /** The dialog component, once its chunk has loaded (the app root renders it). */
  readonly dialog = signal<Type<unknown> | null>(null);
  private loadedFor: string | null = null;

  /** The signed-in account, once its setup steps are done. */
  private readonly userId = computed(() => (this.session.isAuthenticated() && !this.session.setupStep() ? (this.session.me()?.id ?? null) : null));

  constructor() {
    effect(() => {
      const id = this.userId();
      untracked(() => {
        if (!this.isBrowser) return;
        if (!id) {
          this.loadedFor = null;
          this._notices.set([]);
        } else if (id !== this.loadedFor) {
          this.loadedFor = id;
          void this.load(id);
        }
      });
    });
  }

  /** Loads the notices again: a `moderation_notice` push arrived while the app was open. */
  reload(): void {
    const id = this.userId();
    if (!this.isBrowser || !id) return;
    this.loadedFor = id;
    void this.load(id);
  }

  /** `POST /me/moderation-notices/{id}/acknowledge` (idempotent), then the next notice. Rejects with the API error. */
  async acknowledge(noticeId: string): Promise<void> {
    try {
      await firstValueFrom(this.http.post<void>(`${this.base}/me/moderation-notices/${encodeURIComponent(noticeId)}/acknowledge`, null, { context: this.context() }));
    } catch (error) {
      // Someone else's or an unknown id: nothing to acknowledge any more.
      if (!isApiError(error) || error.code !== 'moderation.notice_not_found') throw error;
    }
    this._notices.update((list) => list.filter((n) => n.id !== noticeId));
  }

  private async load(userId: string): Promise<void> {
    try {
      const { items } = await firstValueFrom(this.http.get<{ items: ModerationNoticeDto[] }>(`${this.base}/me/moderation-notices`, { context: this.context() }));
      if (this.loadedFor !== userId) return; // signed out or switched accounts meanwhile
      this._notices.set(items ?? []);
      if (items?.length && !this.dialog()) {
        const [{ ModerationNoticeDialog }] = await Promise.all([import('../../features/moderation/notice-dialog'), appIconsReady()]);
        this.dialog.set(ModerationNoticeDialog);
      }
    } catch {
      this.loadedFor = null; // offline: try again on the next session change
    }
  }
}
