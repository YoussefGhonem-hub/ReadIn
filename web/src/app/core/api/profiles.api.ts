import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import {
  ArticleCardDto,
  CursorPage,
  ProfileDto,
  ReadingHeatmapDto,
  ReadingStatsDto,
  UpdatePrivacyRequest,
  UpdateProfileRequest,
} from './models';
import { HEATMAP_DAYS } from './reading.api';

/**
 * Public profiles (F14) and the privacy settings behind them (F18). Silent: the profile screens render their own
 * loading, empty and error states. Only lazy profile and settings code imports it, so it stays out of the initial
 * bundle.
 */
@Injectable({ providedIn: 'root' })
export class ProfilesApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  /** `GET /users/{username}` 🌐 (case-insensitive, a leading `@` is ignored). `404 user.not_found`. */
  profileUrl(username: string): string {
    return `${this.base}/users/${encodeURIComponent(username.replace(/^@/, ''))}`;
  }

  profile(username: string): Observable<ProfileDto> {
    return this.http.get<ProfileDto>(this.profileUrl(username), { context: this.silent() });
  }

  /** `GET /users/{username}/articles` 🌐: published, newest first, with the viewer's reactions and saves. */
  articles(username: string, query: { cursor?: string | null; limit?: number } = {}): Observable<CursorPage<ArticleCardDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ArticleCardDto>>(`${this.profileUrl(username)}/articles`, { params, context: this.silent() });
  }

  /**
   * `GET /users/{username}/reposts` 🌐 (F29): the profile's Reposts tab, newest repost first; each card's `repostedBy`
   * is this user. `404 user.not_found`.
   */
  reposts(username: string, query: { cursor?: string | null; limit?: number } = {}): Observable<CursorPage<ArticleCardDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ArticleCardDto>>(`${this.profileUrl(username)}/reposts`, { params, context: this.silent() });
  }

  /** `GET /users/{username}/stats` 🌐, in that user's time zone. `403 profile.stats_private`. */
  stats(username: string): Observable<ReadingStatsDto> {
    return this.http.get<ReadingStatsDto>(`${this.profileUrl(username)}/stats`, { context: this.silent() });
  }

  /** `GET /users/{username}/stats/heatmap?days=` 🌐. `403 profile.stats_private`. */
  heatmap(username: string, days = HEATMAP_DAYS): Observable<ReadingHeatmapDto> {
    return this.http.get<ReadingHeatmapDto>(`${this.profileUrl(username)}/stats/heatmap`, {
      params: new HttpParams().set('days', String(days)),
      context: this.silent(),
    });
  }

  /**
   * `PATCH /me` → `204` (refetch `GET /me`). `409 user.username_taken`, `400 profile.avatar_invalid`,
   * `400 profile.expertise_invalid`, validation codes per field.
   */
  updateProfile(body: UpdateProfileRequest): Observable<void> {
    return this.http.patch<void>(`${this.base}/me`, body, { context: this.silent() });
  }

  /** `PUT /me/privacy` → `204`: the settings it names (the clients send them all). `400 validation.failed`. */
  updatePrivacy(body: UpdatePrivacyRequest): Observable<void> {
    return this.http.put<void>(`${this.base}/me/privacy`, body, { context: this.silent() });
  }
}
