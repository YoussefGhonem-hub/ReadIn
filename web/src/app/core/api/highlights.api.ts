import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ArticleLanguage, AuthorDto, CursorPage } from './models';

// ── Highlights (F30), docs/api/contract-v1.md → "Highlights (F30)" ──
// Offsets: UTF-16 code units in the block's plain text, end exclusive (shared/rdoc/highlight-fixtures.json).

export interface CreateHighlightRequest {
  /** The version being read (ArticleHighlightsDto.language). */
  language: ArticleLanguage;
  blockId: string;
  startOffset: number;
  endOffset: number;
  /** Exactly the block's plain text between the offsets. */
  text: string;
}

/** One of yours; never sent to anyone else. */
export interface HighlightDto {
  id: string;
  blockId: string;
  startOffset: number;
  endOffset: number;
  text: string;
  createdAt: string;
}

/** Marked by ≥ 3 readers; no ids, no names. */
export interface PopularHighlightDto {
  blockId: string;
  startOffset: number;
  endOffset: number;
  text: string;
  count: number;
}

export interface ArticleHighlightsDto {
  articleId: string;
  /** The version these belong to. */
  language: ArticleLanguage;
  /** Document order; [] for guests. */
  mine: HighlightDto[];
  /** ≤ 5, most marked first. */
  popular: PopularHighlightDto[];
}

/** `201` (made, maybe joining some of yours) or `200` (already inside one of yours). */
export interface HighlightCreatedDto {
  highlight: HighlightDto;
  /** Your highlights it joined (deleted): drop them. */
  replacedIds: string[];
}

export interface HighlightArticleDto {
  id: string;
  slug: string;
  /** Open the article in this version, at the highlight's block. */
  language: ArticleLanguage;
  /** That version's title. */
  title: string;
  /** Null: the author deleted their account. */
  author: AuthorDto | null;
}

/** `GET /me/highlights`: one article version, all of yours on it newest first; groups newest first by `latestAt`. */
export interface HighlightGroupDto {
  article: HighlightArticleDto;
  highlights: HighlightDto[];
  latestAt: string;
}

/**
 * Highlights (F30). Reading is open to guests (`mine` is then empty); writes need `highlights.create`. Silent: the
 * reader rolls its optimistic change back and shows its own translated error.
 */
@Injectable({ providedIn: 'root' })
export class HighlightsApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  /** Your own highlights: never from the SSR cache, the token goes out even while the page hydrates. */
  private readonly context = () => new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true);

  /** `GET /articles/{id}/highlights?lang=`: yours and the popular ones on the version on screen. */
  forArticle(articleId: string, language: ArticleLanguage): Observable<ArticleHighlightsDto> {
    return this.http.get<ArticleHighlightsDto>(`${this.base}/articles/${encodeURIComponent(articleId)}/highlights`, {
      params: new HttpParams().set('lang', language),
      context: this.context(),
    });
  }

  /** `POST /articles/{id}/highlights`. */
  create(articleId: string, body: CreateHighlightRequest): Observable<HighlightCreatedDto> {
    return this.http.post<HighlightCreatedDto>(`${this.base}/articles/${encodeURIComponent(articleId)}/highlights`, body, { context: this.context() });
  }

  /** `DELETE /highlights/{id}`; `404 highlight.not_found` means it is already gone. */
  remove(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/highlights/${encodeURIComponent(id)}`, { context: this.context() });
  }

  /** `GET /me/highlights`: the profile's Saved tab, Highlights section (F14). */
  mine(query: { cursor?: string | null; limit?: number } = {}): Observable<CursorPage<HighlightGroupDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<HighlightGroupDto>>(`${this.base}/me/highlights`, { params, context: this.context() });
  }
}
