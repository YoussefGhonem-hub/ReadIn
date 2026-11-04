import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ArticlePathDto, PathCardDto, PathDetailsDto } from './models';

/**
 * Learning paths (F09). Browsing is anonymous-friendly (the auth interceptor adds a token when signed in, which fills
 * `progress` and `enrollment`); `/me/paths*` need a session. Silent: the paths screens render their own states. Only
 * lazy code imports it, so it stays out of the initial bundle.
 */
@Injectable({ providedIn: 'root' })
export class PathsApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  /** Reads for the signed-in user: the token goes out even while hydrating. */
  private readonly personal = () => this.silent().set(WITH_SESSION, true);
  private readonly id = encodeURIComponent;

  /** `GET /paths?field=` 🌐: published paths in editorial order. */
  list(field?: string | null): Observable<PathCardDto[]> {
    const params = field ? new HttpParams().set('field', field) : undefined;
    return this.http.get<PathCardDto[]>(`${this.base}/paths`, { params, context: this.silent() });
  }

  /** `GET /paths/{slug}` 🌐. `404 path.not_found`. */
  pathUrl(slug: string): string {
    return `${this.base}/paths/${this.id(slug)}`;
  }

  path(slug: string): Observable<PathDetailsDto> {
    return this.http.get<PathDetailsDto>(this.pathUrl(slug), { context: this.silent() });
  }

  /**
   * `GET /articles/{id}/path` 🌐; resolves to `null` on `204` (the article is in no published path). The reader loads
   * it in the browser only, near the end of the article, so it is never in the SSR cache: the token always goes out.
   */
  articlePath(articleId: string): Observable<ArticlePathDto | null> {
    return this.http
      .get<ArticlePathDto>(`${this.base}/articles/${this.id(articleId)}/path`, { observe: 'response', context: this.personal() })
      .pipe(map((res) => (res.status === 204 ? null : res.body)));
  }

  /** `GET /users/{username}/paths` 🌐: their enrolled paths. `403 profile.stats_private`, `404 user.not_found`. */
  userPaths(username: string): Observable<PathCardDto[]> {
    return this.http.get<PathCardDto[]>(`${this.base}/users/${this.id(username.replace(/^@/, ''))}/paths`, { context: this.silent() });
  }

  /** `GET /me/paths`: in progress first (latest activity first), then completed. */
  mine(): Observable<PathCardDto[]> {
    return this.http.get<PathCardDto[]>(`${this.base}/me/paths`, { context: this.personal() });
  }

  /** `GET /me/paths/active` (Home); resolves to `null` on `204` (no enrolled path in progress). */
  active(): Observable<PathCardDto | null> {
    return this.http
      .get<PathCardDto>(`${this.base}/me/paths/active`, { observe: 'response', context: this.personal() })
      .pipe(map((res) => (res.status === 204 ? null : res.body)));
  }

  /** `PUT /me/paths/{pathId}` (enroll, idempotent). `404 path.not_found`. */
  enroll(pathId: string): Observable<PathCardDto> {
    return this.http.put<PathCardDto>(`${this.base}/me/paths/${this.id(pathId)}`, null, { context: this.silent() });
  }

  /** `DELETE /me/paths/{pathId}` → `204` (leave, idempotent). Reading history is kept. */
  leave(pathId: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/me/paths/${this.id(pathId)}`, { context: this.silent() });
  }
}
