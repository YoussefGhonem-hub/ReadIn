import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { ModerationAction, ModerationActionRequest, ReportReason, ReportRequest } from './models';

/** Reports and moderator actions (F22 hooks in F11: comments only for now). Silent: callers show their own errors. */
@Injectable({ providedIn: 'root' })
export class ModerationApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  /**
   * `POST /reports` → 204 (permission `reports.create`). Reporting again is a no-op that also succeeds.
   * `400 report.own_content`, validation `report.reason_invalid`, `404 report.target_not_found`.
   */
  reportComment(commentId: string, reason: ReportReason, details?: string | null): Observable<void> {
    const body: ReportRequest = { targetType: 'comment', targetId: commentId, reason };
    if (details?.trim()) body.details = details.trim();
    return this.http.post<void>(`${this.base}/reports`, body, { context: this.silent() });
  }

  /** `POST /moderation/actions` → 204 (permission `moderation.manage`). Audited. `404 comment.not_found`. */
  moderateComment(commentId: string, action: ModerationAction): Observable<void> {
    const body: ModerationActionRequest = { action, targetType: 'comment', targetId: commentId };
    return this.http.post<void>(`${this.base}/moderation/actions`, body, { context: this.silent() });
  }
}
