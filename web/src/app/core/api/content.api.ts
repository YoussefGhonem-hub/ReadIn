import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { ArticleCardDto, ArticleDetailsDto, ArticleLanguage, CursorPage } from './models';

export interface ForYouQuery {
  field?: string | null;
  cursor?: string | null;
  limit?: number;
}

/** Articles + feed endpoints. Anonymous-friendly: the auth interceptor adds a token only when signed in. */
@Injectable({ providedIn: 'root' })
export class ContentApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  articleUrl(slug: string, lang: ArticleLanguage): string {
    return `${this.base}/articles/${encodeURIComponent(slug)}?lang=${encodeURIComponent(lang)}`;
  }

  article(slug: string, lang: ArticleLanguage): Observable<ArticleDetailsDto> {
    return this.http.get<ArticleDetailsDto>(this.articleUrl(slug, lang), { context: this.silent() });
  }

  forYou(query: ForYouQuery = {}): Observable<CursorPage<ArticleCardDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.field) params = params.set('field', query.field);
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ArticleCardDto>>(`${this.base}/feed/for-you`, { params, context: this.silent() });
  }

  /** Today's pick; resolves to `null` on `204 No Content` (no pick yet). */
  today(): Observable<ArticleCardDto | null> {
    return this.http
      .get<ArticleCardDto>(`${this.base}/feed/today`, { observe: 'response', context: this.silent() })
      .pipe(map((res) => (res.status === 204 ? null : res.body)));
  }
}
