import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ArticleCardDto, CursorPage, WriterCategoryDto, WriterCategoryListDto, WriterCategoryPageDto } from './models';

/**
 * Writer categories (F31, docs/api/contract-v1.md → "Writer categories"): the profile's Categories tab, the category
 * pages (`_other` is the uncategorized list) and the writer's own list (the manage view and the editor's picker); an
 * article's category is set with `ArticlesApi.setCategory`. Silent: every screen renders its own states and messages.
 * Only lazy code imports it (the profile, category and editor chunks), so it stays out of the initial bundle.
 */
@Injectable({ providedIn: 'root' })
export class WriterCategoriesApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  /** Your own list is never server-rendered (nor cached): the token always goes out. */
  private readonly personal = () => this.silent().set(WITH_SESSION, true);
  private readonly id = encodeURIComponent;

  private userUrl(username: string): string {
    return `${this.base}/users/${encodeURIComponent(username.replace(/^@/, ''))}/categories`;
  }

  /** `GET /users/{username}/categories` 🌐: the categories readers can see something in, and the uncategorized count. */
  list(username: string): Observable<WriterCategoryListDto> {
    return this.http.get<WriterCategoryListDto>(this.userUrl(username), { context: this.silent() });
  }

  /** `GET /users/{username}/categories/{slug}` 🌐: the page header (empty ones too). `404 category.not_found`, `user.not_found`. */
  page(username: string, slug: string): Observable<WriterCategoryPageDto> {
    return this.http.get<WriterCategoryPageDto>(`${this.userUrl(username)}/${this.id(slug)}`, { context: this.silent() });
  }

  /** `GET /users/{username}/categories/{slug}/articles` 🌐: newest first, with your reactions and saves. */
  articles(username: string, slug: string, query: { cursor?: string | null; limit?: number } = {}): Observable<CursorPage<ArticleCardDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ArticleCardDto>>(`${this.userUrl(username)}/${this.id(slug)}/articles`, { params, context: this.silent() });
  }

  /** `GET /me/categories`: all of yours in your order, empty ones included (never cached). */
  mine(): Observable<WriterCategoryListDto> {
    return this.http.get<WriterCategoryListDto>(`${this.base}/me/categories`, { context: this.personal() });
  }

  /** `POST /me/categories` → 201, added last. `400 category.limit`, `409 category.name_taken`, validation `category.name_invalid`. */
  create(name: string): Observable<WriterCategoryDto> {
    return this.http.post<WriterCategoryDto>(`${this.base}/me/categories`, { name }, { context: this.personal() });
  }

  /** `PATCH /me/categories/{id}`: renames it; the slug stays, so its links keep working. */
  rename(id: string, name: string): Observable<WriterCategoryDto> {
    return this.http.patch<WriterCategoryDto>(`${this.base}/me/categories/${this.id(id)}`, { name }, { context: this.personal() });
  }

  /** `DELETE /me/categories/{id}` → 204: its articles stay published, without a category. */
  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/me/categories/${this.id(id)}`, { context: this.personal() });
  }

  /** `PUT /me/categories/order`: your categories in this order (the rest keep theirs after them). */
  reorder(categoryIds: string[]): Observable<WriterCategoryListDto> {
    return this.http.put<WriterCategoryListDto>(`${this.base}/me/categories/order`, { categoryIds }, { context: this.personal() });
  }
}
