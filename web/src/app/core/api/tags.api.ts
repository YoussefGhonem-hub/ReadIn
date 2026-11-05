import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { ArticleCardDto, CursorPage, TagDto } from './models';

/**
 * Tags (F32): the editor's suggestions and the tag page. Silent: both render their own states. Only lazy code (the
 * editor, the tag page) imports it, so it stays out of the initial bundle.
 */
@Injectable({ providedIn: 'root' })
export class TagsApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  /**
   * `GET /tags?q=&limit=` 🌐: tags with a word of their name (or their slug) starting with `q`; the tag named exactly
   * `q` first, then the most used. Never a hidden tag.
   */
  search(q: string, limit = 10): Observable<TagDto[]> {
    const params = new HttpParams().set('q', q).set('limit', String(limit));
    return this.http.get<TagDto[]>(`${this.base}/tags`, { params, context: this.silent() });
  }

  /** `GET /tags/{slug}` 🌐: the tag page's header. `404 tag.not_found` for an unknown or hidden tag. */
  tagUrl(slug: string): string {
    return `${this.base}/tags/${encodeURIComponent(slug)}`;
  }

  tag(slug: string): Observable<TagDto> {
    return this.http.get<TagDto>(this.tagUrl(slug), { context: this.silent() });
  }

  /** `GET /tags/{slug}/articles` 🌐: every published article with the tag, newest first, with your reactions and saves. */
  articles(slug: string, query: { cursor?: string | null; limit?: number } = {}): Observable<CursorPage<ArticleCardDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ArticleCardDto>>(`${this.tagUrl(slug)}/articles`, { params, context: this.silent() });
  }
}
