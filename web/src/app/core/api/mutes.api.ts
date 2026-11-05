import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ContentMutesDto, MutesDto, UserMuteStateDto } from './models';

/**
 * Mute & feedback (F28, docs/api/contract-v1.md "Mute & feedback"): mute writers, fields and topics, "Show less" on an
 * article, and the list Settings → Muted shows. Bearer on every route (guests get the sign-in prompt instead of a
 * call); writes are idempotent and need `follows.manage`. Silent: callers show their own errors.
 */
@Injectable({ providedIn: 'root' })
export class MutesApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  private readonly id = encodeURIComponent;

  /** `PUT /users/{id}/mute`: also ends your follow (`followRemoved`). `400 mute.self` / `mute.system_account` / `mute.limit`. */
  muteUser(userId: string): Observable<UserMuteStateDto> {
    return this.http.put<UserMuteStateDto>(`${this.base}/users/${this.id(userId)}/mute`, null, { context: this.silent() });
  }

  /** `DELETE /users/{id}/mute`; `restoreFollow` (the toast's Undo after a mute that ended a follow) follows again. */
  unmuteUser(userId: string, restoreFollow = false): Observable<UserMuteStateDto> {
    const params = restoreFollow ? new HttpParams().set('restoreFollow', 'true') : undefined;
    return this.http.delete<UserMuteStateDto>(`${this.base}/users/${this.id(userId)}/mute`, { params, context: this.silent() });
  }

  /** `PUT` / `DELETE /me/mutes/fields/{id}`. */
  setFieldMuted(fieldId: string, muted: boolean): Observable<ContentMutesDto> {
    return this.content('fields', fieldId, muted);
  }

  /** `PUT` / `DELETE /me/mutes/topics/{id}`. */
  setTopicMuted(topicId: string, muted: boolean): Observable<ContentMutesDto> {
    return this.content('topics', topicId, muted);
  }

  /** `GET /me/mutes`: Settings → Muted. */
  mutes(): Observable<MutesDto> {
    return this.http.get<MutesDto>(`${this.base}/me/mutes`, { context: this.silent().set(WITH_SESSION, true) });
  }

  /** `PUT /articles/{id}/show-less` → 204. `400 mute.own_article`, `404 article.not_found`. */
  showLess(articleId: string): Observable<void> {
    return this.http.put<void>(`${this.base}/articles/${this.id(articleId)}/show-less`, null, { context: this.silent() });
  }

  /** `DELETE /articles/{id}/show-less` → 204: the toast's Undo. */
  undoShowLess(articleId: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/articles/${this.id(articleId)}/show-less`, { context: this.silent() });
  }

  private content(kind: 'fields' | 'topics', id: string, muted: boolean): Observable<ContentMutesDto> {
    const url = `${this.base}/me/mutes/${kind}/${this.id(id)}`;
    return muted ? this.http.put<ContentMutesDto>(url, null, { context: this.silent() }) : this.http.delete<ContentMutesDto>(url, { context: this.silent() });
  }
}
