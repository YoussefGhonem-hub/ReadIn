import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ReadingHeatmapDto, ReadingProgressRequest, ReadingProgressResultDto, ReadingStatsDto } from './models';

/** Days of the reading heatmap (F08: the last 12 months). The API accepts 1–371. */
export const HEATMAP_DAYS = 365;

/**
 * Reading progress, streaks and stats (SPEC F04, F08, ADR 0013). Signed-in users only. Silent: progress reports run
 * in the background and the stats views render their own error states.
 */
@Injectable({ providedIn: 'root' })
export class ReadingApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  /** Every call here is the signed-in reader's own (progress, stats): the token goes out even while hydrating. */
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true);

  /**
   * `PUT /articles/{id}/progress`. `keepalive` lets the last report of a closing tab finish. `404 article.not_found`,
   * `409 reading.conflict` (a parallel report: send it again).
   */
  progress(articleId: string, body: ReadingProgressRequest, options: { keepalive?: boolean } = {}): Observable<ReadingProgressResultDto> {
    return this.http.put<ReadingProgressResultDto>(`${this.base}/articles/${encodeURIComponent(articleId)}/progress`, body, {
      context: this.silent(),
      keepalive: options.keepalive ?? false,
    });
  }

  /** `GET /me/stats`: streak, freezes, last 7/30 days, totals and top fields. */
  stats(): Observable<ReadingStatsDto> {
    return this.http.get<ReadingStatsDto>(`${this.base}/me/stats`, { context: this.silent() });
  }

  /** `GET /me/stats/heatmap?days=`: only days with a read or a freeze. */
  heatmap(days = HEATMAP_DAYS): Observable<ReadingHeatmapDto> {
    return this.http.get<ReadingHeatmapDto>(`${this.base}/me/stats/heatmap`, {
      params: new HttpParams().set('days', String(days)),
      context: this.silent(),
    });
  }
}
