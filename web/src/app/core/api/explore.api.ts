import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { ArticleCardDto, CursorPage, ExploreDto, FieldPageDto, UserSummaryDto } from './models';

/** The two rankings with a "See all" page. */
export type ExploreRanking = 'trending' | 'most-saved';

export interface CursorQuery {
  cursor?: string | null;
  limit?: number;
}

/**
 * Explore and field pages (F15, docs/api/contract-v1.md → Explore and field pages). Anonymous allowed; signed in, your
 * reactions, saves and follows come with the lists. Silent: the pages render their own states. Only lazy code (the
 * Explore and field pages) imports it, so it stays out of the initial bundle.
 */
@Injectable({ providedIn: 'root' })
export class ExploreApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  /** `GET /explore` 🌐: every section of the Explore page. */
  explore(): Observable<ExploreDto> {
    return this.http.get<ExploreDto>(`${this.base}/explore`, { context: this.silent() });
  }

  /** `GET /explore/trending` or `/explore/most-saved` 🌐: a ranking in full, best first, in cursor pages. */
  ranking(ranking: ExploreRanking, query: CursorQuery = {}): Observable<CursorPage<ArticleCardDto>> {
    return this.http.get<CursorPage<ArticleCardDto>>(`${this.base}/explore/${ranking}`, { params: pageParams(query), context: this.silent() });
  }

  /** `GET /fields/{slug}` 🌐: the field page's header and topic chips. `404 field.not_found`. */
  field(slug: string): Observable<FieldPageDto> {
    return this.http.get<FieldPageDto>(this.fieldUrl(slug), { context: this.silent() });
  }

  /**
   * `GET /fields/{slug}/articles?topic=` 🌐: the field's (or one topic's) articles, newest first. `404 field.not_found`,
   * `404 topic.not_found` for a topic that isn't one of this field's.
   */
  fieldArticles(slug: string, query: CursorQuery & { topic?: string | null } = {}): Observable<CursorPage<ArticleCardDto>> {
    let params = pageParams(query);
    if (query.topic) params = params.set('topic', query.topic);
    return this.http.get<CursorPage<ArticleCardDto>>(`${this.fieldUrl(slug)}/articles`, { params, context: this.silent() });
  }

  /** `GET /fields/{slug}/writers` 🌐: "Top writers in this field", best first (≤ 10). */
  fieldWriters(slug: string, limit = 10): Observable<UserSummaryDto[]> {
    return this.http.get<UserSummaryDto[]>(`${this.fieldUrl(slug)}/writers`, {
      params: new HttpParams().set('limit', String(limit)),
      context: this.silent(),
    });
  }

  private fieldUrl(slug: string): string {
    return `${this.base}/fields/${encodeURIComponent(slug)}`;
  }
}

function pageParams(query: CursorQuery): HttpParams {
  let params = new HttpParams().set('limit', String(query.limit ?? 20));
  if (query.cursor) params = params.set('cursor', query.cursor);
  return params;
}
