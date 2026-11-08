import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { BlockedUserDto, UserBlockStateDto } from './models';

/**
 * Block (F36, docs/api/contract-v1.md "Block (F36)"): block and unblock a person, and the list Settings → Blocked
 * accounts shows. Bearer on every route (guests get the sign-in prompt instead of a call); writes are idempotent and
 * need `users.block`. Silent: callers show their own errors. Only lazy code imports it.
 */
@Injectable({ providedIn: 'root' })
export class BlocksApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  private readonly id = encodeURIComponent;

  /** `PUT /users/{id}/block`: also ends the follows both ways (`followRemoved`). `400 block.self` / `block.limit`. */
  block(userId: string): Observable<UserBlockStateDto> {
    return this.http.put<UserBlockStateDto>(`${this.base}/users/${this.id(userId)}/block`, null, { context: this.silent() });
  }

  /** `DELETE /users/{id}/block`; `restoreFollow` (the toast's Undo after a block that ended your follow) follows again. */
  unblock(userId: string, restoreFollow = false): Observable<UserBlockStateDto> {
    const params = restoreFollow ? new HttpParams().set('restoreFollow', 'true') : undefined;
    return this.http.delete<UserBlockStateDto>(`${this.base}/users/${this.id(userId)}/block`, { params, context: this.silent() });
  }

  /** `GET /me/blocked`: newest block first, not paged (≤ 1,000). */
  blocked(): Observable<{ items: BlockedUserDto[] }> {
    return this.http.get<{ items: BlockedUserDto[] }>(`${this.base}/me/blocked`, { context: this.silent().set(WITH_SESSION, true) });
  }
}
