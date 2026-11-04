import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { CommentDto, CommentLikeDto, CommentPageDto, CommentSort, CursorPage, MentionCandidateDto } from './models';

export interface CommentsQuery {
  sort?: CommentSort;
  cursor?: string | null;
  limit?: number;
}

/**
 * Comments and replies (F11). Reads are open to guests but personal for a signed-in reader (`likedByMe`, `can*`), so
 * they carry the token. Silent: the comments UI shows its own translated errors and rolls optimistic changes back.
 */
@Injectable({ providedIn: 'root' })
export class CommentsApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  private readonly personal = () => this.silent().set(WITH_SESSION, true);
  private readonly id = encodeURIComponent;

  private comment(id: string, path = ''): string {
    return `${this.base}/comments/${this.id(id)}${path}`;
  }

  /** `GET /articles/{id}/comments` 🌐: top-level comments with their first 2 replies; the pinned one first on page 1. */
  list(articleId: string, query: CommentsQuery = {}): Observable<CommentPageDto> {
    let params = new HttpParams().set('sort', query.sort ?? 'top').set('limit', String(query.limit ?? 20));
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CommentPageDto>(`${this.base}/articles/${this.id(articleId)}/comments`, { params, context: this.personal() });
  }

  /** `GET /comments/{id}/replies` 🌐: a thread's replies, oldest first. */
  replies(commentId: string, query: { cursor?: string | null; limit?: number } = {}): Observable<CursorPage<CommentDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<CommentDto>>(this.comment(commentId, '/replies'), { params, context: this.personal() });
  }

  /** `GET /comments/{id}` 🌐: one comment as you see it (deleted/hidden ones as placeholders); refetched after live events. */
  get(commentId: string): Observable<CommentDto> {
    return this.http.get<CommentDto>(this.comment(commentId), { context: this.personal() });
  }

  /** `POST /articles/{id}/comments` → 201. 10 a minute per user (`429`), flood limits `comment.article_limit` / `comment.duplicate`. */
  create(articleId: string, body: string): Observable<CommentDto> {
    return this.http.post<CommentDto>(`${this.base}/articles/${this.id(articleId)}/comments`, { body }, { context: this.silent() });
  }

  /** `POST /comments/{id}/replies` → 201. Replying to a reply joins its thread. `409 comment.not_available`. */
  reply(commentId: string, body: string): Observable<CommentDto> {
    return this.http.post<CommentDto>(this.comment(commentId, '/replies'), { body }, { context: this.silent() });
  }

  /** `PATCH /comments/{id}` (own only, `403 comment.not_owner`) → the comment with `editedAt`. */
  update(commentId: string, body: string): Observable<CommentDto> {
    return this.http.patch<CommentDto>(this.comment(commentId), { body }, { context: this.silent() });
  }

  /** `DELETE /comments/{id}` → 204 (own only, idempotent, soft). */
  delete(commentId: string): Observable<void> {
    return this.http.delete<void>(this.comment(commentId), { context: this.silent() });
  }

  /** `PUT /comments/{id}/like` (idempotent). */
  like(commentId: string): Observable<CommentLikeDto> {
    return this.http.put<CommentLikeDto>(this.comment(commentId, '/like'), null, { context: this.silent() });
  }

  /** `DELETE /comments/{id}/like` (idempotent). */
  unlike(commentId: string): Observable<CommentLikeDto> {
    return this.http.delete<CommentLikeDto>(this.comment(commentId, '/like'), { context: this.silent() });
  }

  /** `POST /comments/{id}/pin`: the article's author only; unpins the previous pinned comment. */
  pin(commentId: string): Observable<CommentDto> {
    return this.http.post<CommentDto>(this.comment(commentId, '/pin'), null, { context: this.silent() });
  }

  /** `DELETE /comments/{id}/pin`. */
  unpin(commentId: string): Observable<CommentDto> {
    return this.http.delete<CommentDto>(this.comment(commentId, '/pin'), { context: this.silent() });
  }

  /**
   * `GET /users/mention-suggestions?q=` (signed in): by `@username` prefix or display name, never you, and only people
   * whose "Who can mention me" lets you (comments and the article editor).
   */
  mentionSuggestions(q: string, limit = 8): Observable<MentionCandidateDto[]> {
    const params = new HttpParams().set('q', q).set('limit', String(limit));
    return this.http.get<MentionCandidateDto[]>(`${this.base}/users/mention-suggestions`, { params, context: this.personal() });
  }
}
