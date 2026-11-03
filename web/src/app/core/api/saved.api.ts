import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { CollectionDto, CursorPage, SaveStateDto, SavedArticleDto } from './models';

export interface SavedQuery {
  /** Field slug. */
  field?: string | null;
  /** Title search (Arabic-insensitive on the server). */
  q?: string | null;
  /** Collection id. */
  collection?: string | null;
  cursor?: string | null;
  limit?: number;
}

/** Saved articles and collections (F13, permission `saved.manage`). Silent: callers show their own errors. */
@Injectable({ providedIn: 'root' })
export class SavedApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  /** Reads for the signed-in user: the token goes out even while hydrating. */
  private readonly personal = () => this.silent().set(WITH_SESSION, true);
  private readonly id = encodeURIComponent;

  /** `PUT /me/saved/{articleId}` (idempotent). */
  save(articleId: string): Observable<SaveStateDto> {
    return this.http.put<SaveStateDto>(`${this.base}/me/saved/${this.id(articleId)}`, null, { context: this.silent() });
  }

  /** `DELETE /me/saved/{articleId}` (idempotent); also removes it from every collection. */
  unsave(articleId: string): Observable<SaveStateDto> {
    return this.http.delete<SaveStateDto>(`${this.base}/me/saved/${this.id(articleId)}`, { context: this.silent() });
  }

  /** `GET /me/saved`, newest saved first. */
  list(query: SavedQuery = {}): Observable<CursorPage<SavedArticleDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.field) params = params.set('field', query.field);
    if (query.q) params = params.set('q', query.q);
    if (query.collection) params = params.set('collection', query.collection);
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<SavedArticleDto>>(`${this.base}/me/saved`, { params, context: this.personal() });
  }

  /** `GET /me/collections` (name order). */
  collections(): Observable<CollectionDto[]> {
    return this.http.get<CollectionDto[]>(`${this.base}/me/collections`, { context: this.personal() });
  }

  /** `POST /me/collections` → `201`. `409 collection.name_taken`, `400 collection.limit`. */
  createCollection(name: string): Observable<CollectionDto> {
    return this.http.post<CollectionDto>(`${this.base}/me/collections`, { name }, { context: this.silent() });
  }

  /** `PATCH /me/collections/{id}`. */
  renameCollection(id: string, name: string): Observable<CollectionDto> {
    return this.http.patch<CollectionDto>(`${this.base}/me/collections/${this.id(id)}`, { name }, { context: this.silent() });
  }

  /** `DELETE /me/collections/{id}` → `204`; the articles stay saved. */
  deleteCollection(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/me/collections/${this.id(id)}`, { context: this.silent() });
  }

  /** `PUT /me/collections/{id}/articles/{articleId}` → `204`; saves the article first if needed. */
  addToCollection(id: string, articleId: string): Observable<void> {
    return this.http.put<void>(`${this.base}/me/collections/${this.id(id)}/articles/${this.id(articleId)}`, null, { context: this.silent() });
  }

  /** `DELETE /me/collections/{id}/articles/{articleId}` → `204`; the article stays saved. */
  removeFromCollection(id: string, articleId: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/me/collections/${this.id(id)}/articles/${this.id(articleId)}`, { context: this.silent() });
  }
}
