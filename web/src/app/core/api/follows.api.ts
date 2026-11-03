import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { CursorPage, FollowStateDto, InterestsDto, UserSummaryDto } from './models';

export interface PeopleQuery {
  /** Filters by display name or @username. */
  q?: string | null;
  cursor?: string | null;
  limit?: number;
}

/** Follow writers, fields and topics (F12, permission `follows.manage` for writes). Silent: callers show their own errors. */
@Injectable({ providedIn: 'root' })
export class FollowsApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  /** Reads for the signed-in user: the token goes out even while hydrating. */
  private readonly personal = () => this.silent().set(WITH_SESSION, true);
  private readonly id = encodeURIComponent;

  /** `PUT /users/{id}/follow` (idempotent). `400 follow.self`, `404 user.not_found`. */
  follow(userId: string): Observable<FollowStateDto> {
    return this.http.put<FollowStateDto>(`${this.base}/users/${this.id(userId)}/follow`, null, { context: this.silent() });
  }

  /** `DELETE /users/{id}/follow` (idempotent). */
  unfollow(userId: string): Observable<FollowStateDto> {
    return this.http.delete<FollowStateDto>(`${this.base}/users/${this.id(userId)}/follow`, { context: this.silent() });
  }

  /** `GET /users/{id}/followers` 🌐, newest first. */
  followers(userId: string, query: PeopleQuery = {}): Observable<CursorPage<UserSummaryDto>> {
    return this.people(userId, 'followers', query);
  }

  /** `GET /users/{id}/following` 🌐, newest first. */
  following(userId: string, query: PeopleQuery = {}): Observable<CursorPage<UserSummaryDto>> {
    return this.people(userId, 'following', query);
  }

  /** `GET /users/suggested`: writers whose fields overlap your interests, not followed yet; verified first. */
  suggested(limit = 10): Observable<UserSummaryDto[]> {
    return this.http.get<UserSummaryDto[]>(`${this.base}/users/suggested`, {
      params: new HttpParams().set('limit', String(limit)),
      context: this.personal(),
    });
  }

  /** Follow a field (an interest, F02). */
  followField(fieldId: string): Observable<InterestsDto> {
    return this.http.put<InterestsDto>(`${this.base}/me/interests/fields/${this.id(fieldId)}`, null, { context: this.silent() });
  }

  /** `400 user.interests.min_three` when fewer than 3 interests would be left. */
  unfollowField(fieldId: string): Observable<InterestsDto> {
    return this.http.delete<InterestsDto>(`${this.base}/me/interests/fields/${this.id(fieldId)}`, { context: this.silent() });
  }

  followTopic(topicId: string): Observable<InterestsDto> {
    return this.http.put<InterestsDto>(`${this.base}/me/interests/topics/${this.id(topicId)}`, null, { context: this.silent() });
  }

  /** `400 user.interests.min_three` when fewer than 3 interests would be left. */
  unfollowTopic(topicId: string): Observable<InterestsDto> {
    return this.http.delete<InterestsDto>(`${this.base}/me/interests/topics/${this.id(topicId)}`, { context: this.silent() });
  }

  private people(userId: string, list: 'followers' | 'following', query: PeopleQuery): Observable<CursorPage<UserSummaryDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.q) params = params.set('q', query.q);
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<UserSummaryDto>>(`${this.base}/users/${this.id(userId)}/${list}`, { params, context: this.personal() });
  }
}
