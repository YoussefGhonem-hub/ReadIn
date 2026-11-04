import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ArticleCardDto, ArticleDetailsDto, ArticleLanguage, ArticlePreviewDto, CursorPage } from './models';

export interface FeedQuery {
  cursor?: string | null;
  limit?: number;
}

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

  /** `GET /articles/{id}/related?lang=&limit=` (F04): 0–`limit` cards for the end of the reader. */
  relatedUrl(id: string, lang: ArticleLanguage, limit: number): string {
    return `${this.base}/articles/${encodeURIComponent(id)}/related?lang=${encodeURIComponent(lang)}&limit=${limit}`;
  }

  article(slug: string, lang: ArticleLanguage): Observable<ArticleDetailsDto> {
    return this.http.get<ArticleDetailsDto>(this.articleUrl(slug, lang), { context: this.silent() });
  }

  /**
   * `GET /articles/{id}/preview?lang=` (F34): the first blocks of the version, for a post card's "Read more". Silent:
   * the card shows its own error state. `404 article.not_found` where the article itself would answer it.
   */
  preview(id: string, lang: ArticleLanguage): Observable<ArticlePreviewDto> {
    return this.http.get<ArticlePreviewDto>(`${this.base}/articles/${encodeURIComponent(id)}/preview`, {
      params: new HttpParams().set('lang', lang),
      context: this.silent(),
    });
  }

  forYou(query: ForYouQuery = {}): Observable<CursorPage<ArticleCardDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.field) params = params.set('field', query.field);
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ArticleCardDto>>(`${this.base}/feed/for-you`, { params, context: this.silent() });
  }

  /** `GET /feed/following` (F12, Bearer): published articles by people you follow, newest first. */
  following(query: FeedQuery = {}): Observable<CursorPage<ArticleCardDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ArticleCardDto>>(`${this.base}/feed/following`, { params, context: this.silent().set(WITH_SESSION, true) });
  }

  /** Today's pick; resolves to `null` on `204 No Content` (no pick yet). */
  today(): Observable<ArticleCardDto | null> {
    return this.http
      .get<ArticleCardDto>(`${this.base}/feed/today`, { observe: 'response', context: this.silent() })
      .pipe(map((res) => (res.status === 204 ? null : res.body)));
  }
}
