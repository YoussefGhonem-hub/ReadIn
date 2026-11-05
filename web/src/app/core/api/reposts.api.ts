import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { ArticleCardDto, CursorPage, RepostStateDto } from './models';

/**
 * Reposts (F29, permission `reposts.create` for writes). Silent: the UI rolls its optimistic change back and shows its
 * own translated error (`repost.own_article`, `article.not_found`, `rate_limited`).
 */
@Injectable({ providedIn: 'root' })
export class RepostsApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  private url(articleId: string): string {
    return `${this.base}/articles/${encodeURIComponent(articleId)}/repost`;
  }

  /** `PUT /articles/{id}/repost` (idempotent). */
  repost(articleId: string): Observable<RepostStateDto> {
    return this.http.put<RepostStateDto>(this.url(articleId), null, { context: this.silent() });
  }

  /** `DELETE /articles/{id}/repost` (idempotent). */
  unrepost(articleId: string): Observable<RepostStateDto> {
    return this.http.delete<RepostStateDto>(this.url(articleId), { context: this.silent() });
  }

  /** `GET /users/{username}/reposts` 🌐: a profile's Reposts tab, newest repost first; each card's `repostedBy` is them. */
  userReposts(username: string, query: { cursor?: string | null; limit?: number } = {}): Observable<CursorPage<ArticleCardDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ArticleCardDto>>(`${this.base}/users/${encodeURIComponent(username)}/reposts`, { params });
  }
}
