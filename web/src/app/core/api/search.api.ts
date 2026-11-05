import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ArticleLanguage, CursorPage, SearchArticleDto, SearchSuggestionsDto, SearchTopicDto, SearchType, TagDto, UserSummaryDto } from './models';

/** What each `type` of `GET /search` returns. */
export interface SearchResultOf {
  articles: SearchArticleDto;
  users: UserSummaryDto;
  topics: SearchTopicDto;
  tags: TagDto;
}

/** Article filters; the other types ignore them. Reading time in whole minutes (0–600, inclusive). */
export interface SearchFilters {
  /** A field slug. */
  field?: string | null;
  lang?: ArticleLanguage | null;
  minMinutes?: number | null;
  maxMinutes?: number | null;
}

/**
 * Search (F16, docs/api/contract-v1.md → Search). Anonymous allowed; signed in, your follow, reaction and save state
 * comes with the results. Only the browser searches (never SSR), so the token goes out even while hydrating. Silent:
 * the search page and the header box render their own states. Only lazy code imports it.
 */
@Injectable({ providedIn: 'root' })
export class SearchApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly context = () => new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true);

  /** `GET /search` 🌐: one tab of results, best first, in cursor pages. */
  search<T extends SearchType>(
    q: string,
    type: T,
    options: { filters?: SearchFilters; cursor?: string | null; limit?: number } = {},
  ): Observable<CursorPage<SearchResultOf[T]>> {
    let params = new HttpParams().set('q', q).set('type', type).set('limit', String(options.limit ?? 20));
    const filters = type === 'articles' ? (options.filters ?? {}) : {};
    if (filters.field) params = params.set('field', filters.field);
    if (filters.lang) params = params.set('lang', filters.lang);
    if (filters.minMinutes != null) params = params.set('minMinutes', String(filters.minMinutes));
    if (filters.maxMinutes != null) params = params.set('maxMinutes', String(filters.maxMinutes));
    if (options.cursor) params = params.set('cursor', options.cursor);
    return this.http.get<CursorPage<SearchResultOf[T]>>(`${this.base}/search`, { params, context: this.context() });
  }

  /** `GET /search/suggest` 🌐: the first 3 results of each type, for the as-you-type dropdown. */
  suggest(q: string): Observable<SearchSuggestionsDto> {
    return this.http.get<SearchSuggestionsDto>(`${this.base}/search/suggest`, { params: new HttpParams().set('q', q), context: this.context() });
  }
}
