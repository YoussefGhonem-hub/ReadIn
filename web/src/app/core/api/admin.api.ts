import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import {
  AdminArticleRowDto,
  AdminCommentRowDto,
  AdminDashboardDto,
  AdminFieldDto,
  AdminPathDto,
  AdminPeriod,
  AdminSummaryDto,
  AdminSystemDto,
  AdminTagDto,
  AdminTaxonomyDto,
  AdminTopicDto,
  AdminUserDto,
  AdminUserRowDto,
  AnnouncementDto,
  AnnouncementPreviewDto,
  AnnouncementRequest,
  AnnouncementsDto,
  AuditEntryDto,
  CreateFieldRequest,
  CreateTopicRequest,
  PagedList,
  UpdateFieldRequest,
  UpdateTopicRequest,
  UpsertPathRequest,
} from './models';

/** A query of an admin table: empty values (null, undefined, '') are left out of the URL. */
export type AdminQuery = Record<string, string | number | boolean | null | undefined>;

/** `GET /admin/users` (contract: Admin console → Users). */
export interface AdminUsersQuery extends AdminQuery {
  q?: string | null;
  status?: 'active' | 'suspended' | null;
  verified?: boolean | null;
  method?: 'phone' | 'google' | 'apple' | null;
  joinedFrom?: string | null;
  joinedTo?: string | null;
  hasReports?: boolean | null;
  sort?: 'joined' | 'lastSeen' | 'followers' | 'openReports' | null;
  dir?: 'asc' | 'desc' | null;
  page?: number;
  pageSize?: number;
}

/** `GET /admin/articles`. */
export interface AdminArticlesQuery extends AdminQuery {
  from?: string | null;
  to?: string | null;
  field?: string | null;
  topic?: string | null;
  writer?: string | null;
  status?: 'published' | 'archived' | null;
  hidden?: boolean | null;
  featured?: boolean | null;
  reported?: boolean | null;
  q?: string | null;
  sort?: 'published' | 'featured' | null;
  page?: number;
  pageSize?: number;
}

/** `GET /admin/tags`. */
export interface AdminTagsQuery extends AdminQuery {
  q?: string | null;
  status?: 'all' | 'visible' | 'hidden' | null;
  origin?: 'all' | 'system' | 'user' | null;
  sort?: 'articles' | 'name' | 'newest' | null;
  page?: number;
  pageSize?: number;
}

/** `GET /admin/audit`. */
export interface AdminAuditQuery extends AdminQuery {
  actor?: string | null;
  target?: string | null;
  action?: string | null;
  source?: 'audit' | 'moderation' | null;
  from?: string | null;
  to?: string | null;
  page?: number;
  pageSize?: number;
}

/** The query as URL parameters, without the empty ones (`false` stays: it is a filter value). */
export function adminParams(query: AdminQuery): HttpParams {
  let params = new HttpParams();
  for (const [key, value] of Object.entries(query)) {
    if (value === null || value === undefined || value === '') continue;
    params = params.set(key, String(value));
  }
  return params;
}

/**
 * The admin console's API (F23): the summary badge, the dashboard, users, content, taxonomy and tags, paths and the
 * featured lists, announcements, the audit log and the system page. Every route needs a permission (contract table
 * "Permissions and sections"); the screens show only what the session's permissions allow. Silent: the console renders
 * its own errors. Only the console's lazy chunks (and the summary store, itself lazy) import it.
 */
@Injectable({ providedIn: 'root' })
export class AdminApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  /** Admin reads are personal: the token goes out even while the page is hydrating. */
  private readonly personal = () => this.silent().set(WITH_SESSION, true);
  private readonly id = encodeURIComponent;

  // ── Summary and dashboard (`admin.access`) ──

  /** `GET /admin/summary`: the console entry's badge. Not cached. */
  summary(): Observable<AdminSummaryDto> {
    return this.http.get<AdminSummaryDto>(`${this.base}/admin/summary`, { context: this.personal() });
  }

  /** `GET /admin/dashboard?period=` (cached 60 s on the server). */
  dashboard(period: AdminPeriod): Observable<AdminDashboardDto> {
    return this.http.get<AdminDashboardDto>(`${this.base}/admin/dashboard`, { params: adminParams({ period }), context: this.personal() });
  }

  // ── Users (`users.read`) ──

  users(query: AdminUsersQuery): Observable<PagedList<AdminUserRowDto>> {
    return this.http.get<PagedList<AdminUserRowDto>>(`${this.base}/admin/users`, { params: adminParams(query), context: this.personal() });
  }

  /** `404 user.not_found`. */
  user(id: string): Observable<AdminUserDto> {
    return this.http.get<AdminUserDto>(`${this.base}/admin/users/${this.id(id)}`, { context: this.personal() });
  }

  /** `GET /admin/users/{id}/phone` (`users.read.pii`): the full number, one at a time, audited. */
  phone(id: string): Observable<{ phoneNumber: string | null }> {
    return this.http.get<{ phoneNumber: string | null }>(`${this.base}/admin/users/${this.id(id)}/phone`, { context: this.personal() });
  }

  /** `POST /admin/users/{id}/logout-all` → 204 (`users.suspend`). `400 moderation.self`, `403 moderation.staff_target`. */
  logoutAll(id: string): Observable<void> {
    return this.http.post<void>(`${this.base}/admin/users/${this.id(id)}/logout-all`, null, { context: this.silent() });
  }

  /** `POST /admin/users/{id}/reset-password` (`users.reset_password`): the temporary password, shown once. */
  resetPassword(id: string): Observable<{ temporaryPassword: string }> {
    return this.http.post<{ temporaryPassword: string }>(`${this.base}/admin/users/${this.id(id)}/reset-password`, null, { context: this.silent() });
  }

  // ── Content (`moderation.manage`; featuring `articles.feature`) ──

  articles(query: AdminArticlesQuery): Observable<PagedList<AdminArticleRowDto>> {
    return this.http.get<PagedList<AdminArticleRowDto>>(`${this.base}/admin/articles`, { params: adminParams(query), context: this.personal() });
  }

  /** `404 article.not_found` (unknown, a draft, or deleted). */
  article(id: string): Observable<AdminArticleRowDto> {
    return this.http.get<AdminArticleRowDto>(`${this.base}/admin/articles/${this.id(id)}`, { context: this.personal() });
  }

  comments(query: { hidden?: boolean | null; page?: number; pageSize?: number }): Observable<PagedList<AdminCommentRowDto>> {
    return this.http.get<PagedList<AdminCommentRowDto>>(`${this.base}/admin/comments`, { params: adminParams(query), context: this.personal() });
  }

  /** `PUT /admin/articles/{id}/featured` → 204. `404 article.not_found` when readers can't open it. */
  feature(articleId: string): Observable<void> {
    return this.http.put<void>(`${this.base}/admin/articles/${this.id(articleId)}/featured`, null, { context: this.silent() });
  }

  /** `DELETE /admin/articles/{id}/featured` → 204 (idempotent). */
  unfeature(articleId: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/admin/articles/${this.id(articleId)}/featured`, { context: this.silent() });
  }

  // ── Taxonomy and tags (`taxonomy.manage`) ──

  taxonomy(): Observable<AdminTaxonomyDto> {
    return this.http.get<AdminTaxonomyDto>(`${this.base}/admin/fields`, { context: this.personal() });
  }

  /** `409 field.slug_taken`. */
  createField(request: CreateFieldRequest): Observable<AdminFieldDto> {
    return this.http.post<AdminFieldDto>(`${this.base}/admin/fields`, request, { context: this.silent() });
  }

  updateField(id: string, request: UpdateFieldRequest): Observable<AdminFieldDto> {
    return this.http.put<AdminFieldDto>(`${this.base}/admin/fields/${this.id(id)}`, request, { context: this.silent() });
  }

  /** Every field once, in display order. `400 admin.order_invalid`. */
  reorderFields(ids: string[]): Observable<void> {
    return this.http.put<void>(`${this.base}/admin/fields/order`, { ids }, { context: this.silent() });
  }

  /** `409 topic.slug_taken`. */
  createTopic(request: CreateTopicRequest): Observable<AdminTopicDto> {
    return this.http.post<AdminTopicDto>(`${this.base}/admin/topics`, request, { context: this.silent() });
  }

  updateTopic(id: string, request: UpdateTopicRequest): Observable<AdminTopicDto> {
    return this.http.put<AdminTopicDto>(`${this.base}/admin/topics/${this.id(id)}`, request, { context: this.silent() });
  }

  /** Every topic of the field once, in display order. */
  reorderTopics(fieldId: string, ids: string[]): Observable<void> {
    return this.http.put<void>(`${this.base}/admin/fields/${this.id(fieldId)}/topics/order`, { ids }, { context: this.silent() });
  }

  tags(query: AdminTagsQuery): Observable<PagedList<AdminTagDto>> {
    return this.http.get<PagedList<AdminTagDto>>(`${this.base}/admin/tags`, { params: adminParams(query), context: this.personal() });
  }

  /** `409 tag.name_taken` (with `tagId`, `tagSlug`: offer a merge). */
  renameTag(id: string, name: string): Observable<AdminTagDto> {
    return this.http.put<AdminTagDto>(`${this.base}/admin/tags/${this.id(id)}`, { name }, { context: this.silent() });
  }

  /** Merges `id` into `intoTagId` (can't be undone) → the tag merged into. `400 tag.merge_self`. */
  mergeTag(id: string, intoTagId: string): Observable<AdminTagDto> {
    return this.http.post<AdminTagDto>(`${this.base}/admin/tags/${this.id(id)}/merge`, { intoTagId }, { context: this.silent() });
  }

  setTagHidden(id: string, hidden: boolean): Observable<AdminTagDto> {
    const url = `${this.base}/admin/tags/${this.id(id)}/hidden`;
    return hidden ? this.http.put<AdminTagDto>(url, null, { context: this.silent() }) : this.http.delete<AdminTagDto>(url, { context: this.silent() });
  }

  // ── Paths (`paths.manage`) and featured paths (`articles.feature`) ──

  paths(): Observable<AdminPathDto[]> {
    return this.http.get<AdminPathDto[]>(`${this.base}/admin/paths`, { context: this.personal() });
  }

  createPath(request: UpsertPathRequest): Observable<{ id: string; slug: string }> {
    return this.http.post<{ id: string; slug: string }>(`${this.base}/admin/paths`, request, { context: this.silent() });
  }

  updatePath(id: string, request: UpsertPathRequest): Observable<void> {
    return this.http.put<void>(`${this.base}/admin/paths/${this.id(id)}`, request, { context: this.silent() });
  }

  /** 1–100 articles readers can open, in path order. `400 path.items_invalid`, `409 path.editorial`. */
  setPathItems(id: string, articleIds: string[]): Observable<void> {
    return this.http.put<void>(`${this.base}/admin/paths/${this.id(id)}/items`, { articleIds }, { context: this.silent() });
  }

  deletePath(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/admin/paths/${this.id(id)}`, { context: this.silent() });
  }

  /** The whole featured list in Explore order (0–20). `400 path.featured_invalid`. */
  setFeaturedPaths(pathIds: string[]): Observable<void> {
    return this.http.put<void>(`${this.base}/admin/paths/featured`, { pathIds }, { context: this.silent() });
  }

  // ── Announcements (`notifications.broadcast`) ──

  announcements(): Observable<AnnouncementsDto> {
    return this.http.get<AnnouncementsDto>(`${this.base}/admin/announcements`, { context: this.personal() });
  }

  /** Who it would reach now; nothing is sent. */
  previewAnnouncement(request: AnnouncementRequest): Observable<AnnouncementPreviewDto> {
    return this.http.post<AnnouncementPreviewDto>(`${this.base}/admin/announcements/preview`, request, { context: this.silent() });
  }

  /** Sends it to you alone, at once; it isn't the day's announcement. */
  testAnnouncement(request: AnnouncementRequest): Observable<void> {
    return this.http.post<void>(`${this.base}/admin/announcements/test`, request, { context: this.silent() });
  }

  /** `202` (`status: "sending"`). `429 announcement.limit`, `400 announcement.no_recipients`. */
  sendAnnouncement(request: AnnouncementRequest): Observable<AnnouncementDto> {
    return this.http.post<AnnouncementDto>(`${this.base}/admin/announcements`, request, { context: this.silent() });
  }

  // ── Audit log (`audit.read`) and System (`system.settings`) ──

  audit(query: AdminAuditQuery): Observable<PagedList<AuditEntryDto>> {
    return this.http.get<PagedList<AuditEntryDto>>(`${this.base}/admin/audit`, { params: adminParams(query), context: this.personal() });
  }

  system(): Observable<AdminSystemDto> {
    return this.http.get<AdminSystemDto>(`${this.base}/admin/system`, { context: this.personal() });
  }

  rebuildCounters(): Observable<unknown> {
    return this.http.post(`${this.base}/admin/realtime/rebuild-counters`, null, { context: this.silent() });
  }
}
