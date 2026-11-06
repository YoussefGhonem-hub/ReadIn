import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { ArticleCardDto, CursorPage, RepostRequest, RepostStateDto } from './models';

/**
 * Reposts (F29, permission `reposts.create` for writes). Silent: the UI rolls its optimistic change back, or the caption
 * dialog stays open, and shows its own translated error (`repost.own_article`, `repost.caption_too_long`,
 * `article.not_found`, `rate_limited`).
 */
@Injectable({ providedIn: 'root' })
export class RepostsApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  private url(articleId: string): string {
    return `${this.base}/articles/${encodeURIComponent(articleId)}/repost`;
  }

  /**
   * `PUT /articles/{id}/repost` (idempotent). Without `caption` there is no body: a new repost has no caption and an
   * existing one keeps its own. With one (`{ caption }`) it reposts with your thoughts, or only sets them when you
   * already reposted (the repost keeps its time and count); `""` clears them.
   */
  repost(articleId: string, caption?: string | null): Observable<RepostStateDto> {
    const body: RepostRequest | null = caption === undefined ? null : { caption };
    return this.http.put<RepostStateDto>(this.url(articleId), body, { context: this.silent() });
  }

  /** `GET /articles/{id}/repost`: your repost of it now, with its caption (prefills "عدّل رأيك"). */
  state(articleId: string): Observable<RepostStateDto> {
    return this.http.get<RepostStateDto>(this.url(articleId), { context: this.silent() });
  }

  /** `DELETE /articles/{id}/repost` (idempotent); the caption goes with the repost. */
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
