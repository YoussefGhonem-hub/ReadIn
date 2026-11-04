import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { CursorPage, NotificationDto, NotificationSettingsDto, UnreadNotificationsDto } from './models';

/**
 * The notification center and its settings (F17, SPEC §21.1). Every call is the signed-in user's own and silent:
 * callers show their own errors.
 */
@Injectable({ providedIn: 'root' })
export class NotificationsApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  /** Personal reads: the token goes out even while the page is hydrating. */
  private readonly context = () => new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true);

  /** `GET /me/notifications`, newest activity first, in cursor pages. */
  list(query: { cursor?: string | null; limit?: number } = {}): Observable<CursorPage<NotificationDto>> {
    let params = new HttpParams();
    if (query.cursor) params = params.set('cursor', query.cursor);
    if (query.limit) params = params.set('limit', String(query.limit));
    return this.http.get<CursorPage<NotificationDto>>(`${this.base}/me/notifications`, { params, context: this.context() });
  }

  /** `GET /me/notifications/unread-count`: the badge when the Realtime Database is unavailable. */
  unreadCount(): Observable<UnreadNotificationsDto> {
    return this.http.get<UnreadNotificationsDto>(`${this.base}/me/notifications/unread-count`, { context: this.context() });
  }

  /** `POST /me/notifications/seen`: the center was opened, so the badge goes to 0. Items stay unread. */
  markSeen(): Observable<void> {
    return this.http.post<void>(`${this.base}/me/notifications/seen`, null, { context: this.context() });
  }

  /** `POST /me/notifications/{id}/read` (idempotent): opened from the center or a push. `404 notification.not_found`. */
  markRead(id: string): Observable<void> {
    return this.http.post<void>(`${this.base}/me/notifications/${encodeURIComponent(id)}/read`, null, { context: this.context() });
  }

  /** `POST /me/notifications/read-all`. */
  markAllRead(): Observable<void> {
    return this.http.post<void>(`${this.base}/me/notifications/read-all`, null, { context: this.context() });
  }

  /** `GET /me/notification-settings`. */
  settings(): Observable<NotificationSettingsDto> {
    return this.http.get<NotificationSettingsDto>(`${this.base}/me/notification-settings`, { context: this.context() });
  }

  /**
   * `PUT /me/notification-settings` with the types that change only. `400 notification.type_invalid`,
   * `notification.mode_invalid`, `notification.quiet_hours_invalid`.
   */
  updateSettings(body: NotificationSettingsDto): Observable<void> {
    return this.http.put<void>(`${this.base}/me/notification-settings`, body, { context: this.context() });
  }
}
