import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import {
  ArticleDraftDocument,
  ArticleEditDto,
  ArticleRevisionDetailsDto,
  ArticleRevisionDto,
  ArticleStatus,
  CursorPage,
  MyArticleDto,
  PublishedArticleDto,
  SaveDraftRequest,
} from './models';

export interface MyArticlesQuery {
  status: ArticleStatus;
  cursor?: string | null;
  limit?: number;
}

/**
 * Writing endpoints (F05, permission `articles.create`): the owner's working copy, autosave, publish, revisions and
 * "My articles". Errors are rendered by the editor and the list, so they stay silent.
 */
@Injectable({ providedIn: 'root' })
export class ArticlesApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true);

  private url(id: string, suffix = ''): string {
    return `${this.base}/articles/${encodeURIComponent(id)}${suffix}`;
  }

  /** `GET /me/articles?status=` → drafts (newest edit first) or published (newest publish first). */
  mine(query: MyArticlesQuery): Observable<CursorPage<MyArticleDto>> {
    let params = new HttpParams().set('status', query.status).set('limit', String(query.limit ?? 20));
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<MyArticleDto>>(`${this.base}/me/articles`, { params, context: this.silent() });
  }

  /** `POST /articles` → `201` a never-published draft (lenient: an unfinished article saves fine). */
  create(document: ArticleDraftDocument): Observable<ArticleEditDto> {
    return this.http.post<ArticleEditDto>(`${this.base}/articles`, document, { context: this.silent() });
  }

  /** `GET /articles/{id}/edit` (owner only; `404 article.not_found` for anyone else). */
  edit(id: string): Observable<ArticleEditDto> {
    return this.http.get<ArticleEditDto>(this.url(id, '/edit'), { context: this.silent() });
  }

  /** `PUT /articles/{id}/draft` (autosave): replaces the working copy. `409 article.draft_conflict` on a stale `baseVersion`. */
  saveDraft(id: string, body: SaveDraftRequest): Observable<ArticleEditDto> {
    return this.http.put<ArticleEditDto>(this.url(id, '/draft'), body, { context: this.silent() });
  }

  /** `DELETE /articles/{id}/draft`: drops the unpublished changes of a published article. */
  discardDraft(id: string): Observable<ArticleEditDto> {
    return this.http.delete<ArticleEditDto>(this.url(id, '/draft'), { context: this.silent() });
  }

  /** `POST /articles/{id}/publish`: first publish or "Update". `400` with `problems` when the checks fail. */
  publish(id: string, baseVersion: number): Observable<PublishedArticleDto> {
    return this.http.post<PublishedArticleDto>(this.url(id, '/publish'), { baseVersion }, { context: this.silent() });
  }

  /** `GET /articles/{id}/revisions`, newest first (one per publish/update). */
  revisions(id: string): Observable<ArticleRevisionDto[]> {
    return this.http.get<ArticleRevisionDto[]>(this.url(id, '/revisions'), { context: this.silent() });
  }

  revision(id: string, revision: number): Observable<ArticleRevisionDetailsDto> {
    return this.http.get<ArticleRevisionDetailsDto>(this.url(id, `/revisions/${revision}`), { context: this.silent() });
  }

  /** Copies a revision into the working copy (not live until Update). */
  restoreRevision(id: string, revision: number, baseVersion: number): Observable<ArticleEditDto> {
    return this.http.post<ArticleEditDto>(this.url(id, `/revisions/${revision}/restore`), { baseVersion }, { context: this.silent() });
  }

  /** `DELETE /articles/{id}` → `204` (drafts at once; published articles leave the feeds). */
  delete(id: string): Observable<void> {
    return this.http.delete<void>(this.url(id), { context: this.silent() });
  }
}
