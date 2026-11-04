import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, catchError, from, map, switchMap, throwError } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { withBlobProblem } from './media.api';
import {
  AdminVerificationRequestDto,
  CursorPage,
  MyVerificationRequestDto,
  VerificationStatus,
  VerificationStatusDto,
  VerificationSubmission,
} from './models';

/**
 * Writer verification (F19): your own request, and the admins' review (`verification.manage`). Every call is silent:
 * the pages show their own errors. The proof file is private: it is only ever fetched here, with the session, never
 * linked to.
 */
@Injectable({ providedIn: 'root' })
export class VerificationApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  /** Personal reads: the token goes out even while the page is hydrating. */
  private readonly context = () => new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true);

  /** `GET /me/verification`: verified or not, whether you can request, and your latest request. */
  status(): Observable<VerificationStatusDto> {
    return this.http.get<VerificationStatusDto>(`${this.base}/me/verification`, { context: this.context() });
  }

  /**
   * `POST /verification-requests` as `multipart/form-data` → `201`. `400 verification.proof_required`,
   * `verification.proof_invalid`, `verification.field_invalid`, `validation.failed`; `409 verification.already_pending`,
   * `verification.already_verified`; `403 user.suspended`.
   */
  submit(request: VerificationSubmission): Observable<MyVerificationRequestDto> {
    const body = new FormData();
    body.append('fieldId', request.fieldId);
    body.append('jobTitle', request.jobTitle);
    if (request.proofUrl) body.append('proofUrl', request.proofUrl);
    if (request.note) body.append('note', request.note);
    if (request.proof) body.append('proof', request.proof, request.proof.name);
    return this.http.post<MyVerificationRequestDto>(`${this.base}/verification-requests`, body, { context: this.context() });
  }

  /** `DELETE /me/verification`: withdraws the pending request and deletes its file. `404 verification.not_found`. */
  withdraw(): Observable<void> {
    return this.http.delete<void>(`${this.base}/me/verification`, { context: this.context() });
  }

  /** `GET /admin/verification-requests`: pending oldest first, the others newest decided first. */
  list(query: { status: VerificationStatus; cursor?: string | null; limit?: number }): Observable<CursorPage<AdminVerificationRequestDto>> {
    let params = new HttpParams().set('status', query.status);
    if (query.cursor) params = params.set('cursor', query.cursor);
    if (query.limit) params = params.set('limit', String(query.limit));
    return this.http.get<CursorPage<AdminVerificationRequestDto>>(`${this.base}/admin/verification-requests`, { params, context: this.context() });
  }

  /** `GET /admin/verification-requests/{id}`. `404 verification.not_found`. */
  get(id: string): Observable<AdminVerificationRequestDto> {
    return this.http.get<AdminVerificationRequestDto>(`${this.base}/admin/verification-requests/${encodeURIComponent(id)}`, { context: this.context() });
  }

  /**
   * `GET /admin/verification-requests/{id}/proof`: the file, with the bearer token (it has no public URL). Typed with
   * the response's content type, else `contentType`. `404 verification.proof_not_found` once it is deleted.
   */
  proof(id: string, contentType: string): Observable<Blob> {
    return this.http.get(`${this.base}/admin/verification-requests/${encodeURIComponent(id)}/proof`, { responseType: 'blob', context: this.context() }).pipe(
      map((blob) => (blob.type ? blob : new Blob([blob], { type: contentType }))),
      catchError((error: unknown) => from(withBlobProblem(error)).pipe(switchMap((e) => throwError(() => e)))),
    );
  }

  /** `POST /admin/verification-requests/{id}/approve` → `204`. `409 verification.already_decided`. */
  approve(id: string): Observable<void> {
    return this.http.post<void>(`${this.base}/admin/verification-requests/${encodeURIComponent(id)}/approve`, null, { context: this.context() });
  }

  /** `POST /admin/verification-requests/{id}/reject` with the reason (5–500) → `204`. `409 verification.already_decided`. */
  reject(id: string, reason: string): Observable<void> {
    return this.http.post<void>(`${this.base}/admin/verification-requests/${encodeURIComponent(id)}/reject`, { reason }, { context: this.context() });
  }
}
