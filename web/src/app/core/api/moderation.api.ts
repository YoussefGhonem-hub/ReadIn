import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import {
  CursorPage,
  ModerationAction,
  ModerationActionDto,
  ModerationActionRequest,
  ModerationCaseDto,
  ModerationNoticeDto,
  ModerationQueueItemDto,
  ModerationSummaryDto,
  ModerationTargetType,
  ReportReason,
  ReportRequest,
  ReportStatus,
} from './models';

export interface ModerationQueueQuery {
  /** Default `open`. */
  status?: ReportStatus;
  type?: ModerationTargetType | null;
  cursor?: string | null;
  /** 1–50, default 20. */
  limit?: number;
}

export interface ModerationLogQuery {
  targetUserId?: string | null;
  moderatorId?: string | null;
  targetType?: ModerationTargetType | null;
  cursor?: string | null;
  limit?: number;
}

/**
 * Reports, the moderation queue and log, moderator actions and the affected user's notices (F22). Silent: callers
 * show their own translated errors. Reads are personal (moderators only, or your own notices), so they keep the token.
 */
@Injectable({ providedIn: 'root' })
export class ModerationApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);
  private readonly personal = () => this.silent().set(WITH_SESSION, true);
  private readonly id = encodeURIComponent;

  /**
   * `POST /reports` → 204 (permission `reports.create`). Reporting the same target again is a no-op that succeeds too.
   * `400 report.own_content`, `404 report.target_not_found`, validation `report.target_invalid` / `report.reason_invalid`.
   */
  report(targetType: ModerationTargetType, targetId: string, reason: ReportReason, details?: string | null): Observable<void> {
    const body: ReportRequest = { targetType, targetId, reason };
    if (details?.trim()) body.details = details.trim();
    return this.http.post<void>(`${this.base}/reports`, body, { context: this.silent() });
  }

  /**
   * `POST /moderation/actions` → 204 (permission `moderation.manage`). Logged; repeating an action that changes nothing
   * is a 204 too. `400 moderation.self` / `moderation.note_required` / `moderation.duration_invalid` /
   * `moderation.action_invalid`, `403 moderation.staff_target`, `404 article.not_found` / `comment.not_found` / `user.not_found`.
   */
  act(request: ModerationActionRequest): Observable<void> {
    const body: ModerationActionRequest = { ...request };
    const note = request.note?.trim();
    if (note) body.note = note;
    else delete body.note;
    return this.http.post<void>(`${this.base}/moderation/actions`, body, { context: this.silent() });
  }

  /** The comments' inline hide / unhide / delete (F11). */
  moderateComment(commentId: string, action: Extract<ModerationAction, 'hide' | 'unhide' | 'delete'>): Observable<void> {
    return this.act({ action, targetType: 'comment', targetId: commentId });
  }

  /** `GET /moderation/summary`: targets with open reports, for the nav badge. */
  summary(): Observable<ModerationSummaryDto> {
    return this.http.get<ModerationSummaryDto>(`${this.base}/moderation/summary`, { context: this.personal() });
  }

  /** `GET /moderation/reports`: one item per target. Open: most reports first; resolved/dismissed: latest closed first. */
  queue(query: ModerationQueueQuery = {}): Observable<CursorPage<ModerationQueueItemDto>> {
    let params = new HttpParams().set('status', query.status ?? 'open').set('limit', String(query.limit ?? 20));
    if (query.type) params = params.set('type', query.type);
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ModerationQueueItemDto>>(`${this.base}/moderation/reports`, { params, context: this.personal() });
  }

  /** `GET /moderation/reports/{targetType}/{targetId}`: the target, all its reports and its history. */
  case(targetType: ModerationTargetType, targetId: string): Observable<ModerationCaseDto> {
    return this.http.get<ModerationCaseDto>(`${this.base}/moderation/reports/${this.id(targetType)}/${this.id(targetId)}`, {
      context: this.personal(),
    });
  }

  /** `GET /moderation/actions`: the moderation log, newest first. */
  log(query: ModerationLogQuery = {}): Observable<CursorPage<ModerationActionDto>> {
    let params = new HttpParams().set('limit', String(query.limit ?? 20));
    if (query.targetUserId) params = params.set('targetUserId', query.targetUserId);
    if (query.moderatorId) params = params.set('moderatorId', query.moderatorId);
    if (query.targetType) params = params.set('targetType', query.targetType);
    if (query.cursor) params = params.set('cursor', query.cursor);
    return this.http.get<CursorPage<ModerationActionDto>>(`${this.base}/moderation/actions`, { params, context: this.personal() });
  }

  /** `GET /me/moderation-notices`: your unacknowledged warnings and hidden-article notices, oldest first. */
  notices(): Observable<{ items: ModerationNoticeDto[] }> {
    return this.http.get<{ items: ModerationNoticeDto[] }>(`${this.base}/me/moderation-notices`, { context: this.personal() });
  }

  /** `POST /me/moderation-notices/{id}/acknowledge` → 204 (idempotent; `404 moderation.notice_not_found`). */
  acknowledgeNotice(noticeId: string): Observable<void> {
    return this.http.post<void>(`${this.base}/me/moderation-notices/${this.id(noticeId)}/acknowledge`, null, { context: this.silent() });
  }
}
