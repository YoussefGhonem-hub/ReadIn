import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ArticleReactionsDto, CursorPage, ReactionType, ReactorDto } from './models';

export interface ReactorsQuery {
  type?: ReactionType | null;
  cursor?: string | null;
  limit?: number;
}

/**
 * Reactions (F10, permission `reactions.create` for writes). Silent: the UI rolls its optimistic change back and
 * shows its own translated error.
 */
@Injectable({ providedIn: 'root' })
export class ReactionsApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  /** Reads for the signed-in user: the token goes out even while hydrating. */
  private readonly personal = () => this.silent().set(WITH_SESSION, true);

  private url(articleId: string, path: string): string {
    return `${this.base}/articles/${encodeURIComponent(articleId)}/${path}`;
  }

  /** `PUT /articles/{id}/reaction`: sets or changes the one reaction per user per article. */
  react(articleId: string, type: ReactionType): Observable<ArticleReactionsDto> {
    return this.http.put<ArticleReactionsDto>(this.url(articleId, 'reaction'), { type }, { context: this.silent() });
  }

  /** `DELETE /articles/{id}/reaction` (idempotent). */
  unreact(articleId: string): Observable<ArticleReactionsDto> {
    return this.http.delete<ArticleReactionsDto>(this.url(articleId, 'reaction'), { context: this.silent() });
  }

  /** `GET /articles/{id}/reactions` 🌐: who reacted, newest first; `type` filters. */
  reactors(articleId: string, query: ReactorsQuery = {}): Observable<CursorPage<ReactorDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.type) params = params.set('type', query.type);
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ReactorDto>>(this.url(articleId, 'reactions'), { params, context: this.personal() });
  }
}
