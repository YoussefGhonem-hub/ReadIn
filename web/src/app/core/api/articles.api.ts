import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { CreateArticleRequest, CreatedArticleDto, SetAttachmentsRequest } from './models';

/** Writing endpoints (permission `articles.create`). Errors are rendered by the editor, so they stay silent. */
@Injectable({ providedIn: 'root' })
export class ArticlesApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  /** `POST /articles` → `201 { id, slug }` (draft). */
  create(body: CreateArticleRequest): Observable<CreatedArticleDto> {
    return this.http.post<CreatedArticleDto>(`${this.base}/articles`, body, { context: this.silent() });
  }

  /** `PUT /articles/{id}/attachments` → `204`. Replaces the whole set. */
  setAttachments(id: string, body: SetAttachmentsRequest): Observable<void> {
    return this.http.put<void>(`${this.base}/articles/${encodeURIComponent(id)}/attachments`, body, { context: this.silent() });
  }

  /** `POST /articles/{id}/publish` → `204` (`article.sources_required` when the field needs sources). */
  publish(id: string): Observable<void> {
    return this.http.post<void>(`${this.base}/articles/${encodeURIComponent(id)}/publish`, null, { context: this.silent() });
  }
}
