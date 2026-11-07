import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, catchError, from, map, switchMap, throwError } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { withBlobProblem } from './media.api';
import {
  AdminSupportMessageDto,
  AdminTicketDto,
  AdminTicketRowDto,
  CursorPage,
  NewSupportTicket,
  PagedList,
  SupportCategory,
  SupportConfigDto,
  SupportMessageDto,
  SupportStatus,
  SupportTicketDto,
  SupportTicketSummaryDto,
} from './models';

/** URL parameters without the empty values (a copy of admin.api's, so the member pages don't load the console's API). */
function queryParams(query: Record<string, string | number | null | undefined>): HttpParams {
  let params = new HttpParams();
  for (const [key, value] of Object.entries(query)) {
    if (value !== null && value !== undefined && value !== '') params = params.set(key, String(value));
  }
  return params;
}

/** `GET /admin/support/tickets`: Open (waiting longest first, the default), Answered or Closed. */
export interface AdminTicketsQuery {
  status?: SupportStatus | null;
  category?: SupportCategory | null;
  /** Words of the subject, the member's name or @username, or `#12`. */
  q?: string | null;
  page?: number;
  pageSize?: number;
}

/**
 * Help & support (F35): the public config (the support email), your tickets (`support.create`) and the console's queue
 * (`support.manage`). Silent: the screens show their own errors. Screenshots are private: they are only fetched here,
 * with the session, as blobs.
 */
@Injectable({ providedIn: 'root' })
export class SupportApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  private readonly personal = () => this.silent().set(WITH_SESSION, true);
  private readonly id = encodeURIComponent;

  /** `GET /support/config` 🌐: the support email (null: none), the categories and the screenshot limits. */
  config(): Observable<SupportConfigDto> {
    return this.http.get<SupportConfigDto>(`${this.base}/support/config`, { context: this.silent() });
  }

  /**
   * `POST /support/tickets` as `multipart/form-data` → `201`. `429 support.limit` (`limit: daily | open`),
   * `400 support.too_many_attachments`, `support.attachment_invalid`, `validation.failed`.
   */
  create(ticket: NewSupportTicket): Observable<SupportTicketDto> {
    const body = new FormData();
    body.append('category', ticket.category);
    body.append('subject', ticket.subject);
    body.append('message', ticket.message);
    for (const [key, value] of Object.entries(ticket.device)) {
      if (value) body.append(key, String(value));
    }
    for (const file of ticket.screenshots) body.append('screenshots', file, file.name);
    return this.http.post<SupportTicketDto>(`${this.base}/support/tickets`, body, { context: this.silent() });
  }

  /** `GET /me/support/tickets?status=active|closed` (omitted: all), latest activity first. */
  mine(status: 'active' | 'closed' | null, cursor: string | null, limit = 20): Observable<CursorPage<SupportTicketSummaryDto>> {
    let params = new HttpParams().set('limit', String(limit));
    if (status) params = params.set('status', status);
    if (cursor) params = params.set('cursor', cursor);
    return this.http.get<CursorPage<SupportTicketSummaryDto>>(`${this.base}/me/support/tickets`, { params, context: this.personal() });
  }

  /** `404 support.ticket_not_found` (unknown, or someone else's). */
  ticket(id: string): Observable<SupportTicketDto> {
    return this.http.get<SupportTicketDto>(`${this.base}/support/tickets/${this.id(id)}`, { context: this.personal() });
  }

  /** `409 support.ticket_closed`, and the screenshot errors of {@link create}. */
  reply(id: string, message: string, screenshots: File[]): Observable<SupportMessageDto> {
    const body = new FormData();
    body.append('message', message);
    for (const file of screenshots) body.append('screenshots', file, file.name);
    return this.http.post<SupportMessageDto>(`${this.base}/support/tickets/${this.id(id)}/messages`, body, { context: this.silent() });
  }

  close(id: string): Observable<void> {
    return this.http.post<void>(`${this.base}/support/tickets/${this.id(id)}/close`, null, { context: this.silent() });
  }

  /** `409 support.reopen_expired` (closed more than 30 days ago). */
  reopen(id: string): Observable<void> {
    return this.http.post<void>(`${this.base}/support/tickets/${this.id(id)}/reopen`, null, { context: this.silent() });
  }

  /** `GET /support/attachments/{id}`: a screenshot, with the session (it has no public URL). */
  attachment(id: string, contentType: string): Observable<Blob> {
    return this.http.get(`${this.base}/support/attachments/${this.id(id)}`, { responseType: 'blob', context: this.personal() }).pipe(
      map((blob) => (blob.type ? blob : new Blob([blob], { type: contentType }))),
      catchError((error: unknown) => from(withBlobProblem(error)).pipe(switchMap((e) => throwError(() => e)))),
    );
  }

  // ── The console's queue (`support.manage`) ──

  adminTickets(query: AdminTicketsQuery): Observable<PagedList<AdminTicketRowDto>> {
    return this.http.get<PagedList<AdminTicketRowDto>>(`${this.base}/admin/support/tickets`, {
      params: queryParams({ ...query }),
      context: this.personal(),
    });
  }

  adminTicket(id: string): Observable<AdminTicketDto> {
    return this.http.get<AdminTicketDto>(`${this.base}/admin/support/tickets/${this.id(id)}`, { context: this.personal() });
  }

  /** A reply (`internal: false`: the ticket becomes Answered, the member is told) or an internal note. */
  adminMessage(id: string, body: string, internal: boolean): Observable<AdminSupportMessageDto> {
    return this.http.post<AdminSupportMessageDto>(`${this.base}/admin/support/tickets/${this.id(id)}/messages`, { body, internal }, { context: this.silent() });
  }

  /** Close / reopen (no time limit) or change the category. */
  adminUpdate(id: string, change: { status?: 'open' | 'closed'; category?: SupportCategory }): Observable<AdminTicketDto> {
    return this.http.patch<AdminTicketDto>(`${this.base}/admin/support/tickets/${this.id(id)}`, change, { context: this.silent() });
  }
}
