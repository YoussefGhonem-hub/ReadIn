import { HttpClient, HttpContext, HttpEvent, HttpRequest } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, catchError, from, switchMap, throwError } from 'rxjs';
import { API_BASE_URL, ApiError, SILENT_ERRORS, isApiError } from './api.config';
import { MediaAssetDto, ProblemDetails } from './models';
import { UPLOAD_HTTP } from './upload-http';

export type ImageUploadPurpose = 'image' | 'avatar' | 'cover';

/** Media endpoints (ADR 0011). Upload calls emit HttpClient events so callers can show progress; unsubscribe cancels. */
@Injectable({ providedIn: 'root' })
export class MediaApi {
  private readonly http = inject(HttpClient);
  private readonly uploadHttp = inject(UPLOAD_HTTP);
  private readonly base = inject(API_BASE_URL);
  /** Upload UIs render their own per-file errors. */
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  /** `POST /uploads/images` → `201 MediaAssetDto` (`status: "ready"`). */
  uploadImage(file: Blob, fileName: string, purpose: ImageUploadPurpose = 'image'): Observable<HttpEvent<MediaAssetDto>> {
    const body = new FormData();
    body.append('file', file, fileName);
    body.append('purpose', purpose);
    return this.uploadHttp.request(
      new HttpRequest<FormData>('POST', `${this.base}/uploads/images`, body, { reportProgress: true, context: this.silent() }),
    );
  }

  /** `POST /uploads/documents` → `202 MediaAssetDto` (`status: "processing"`, `pageCount` set). */
  uploadDocument(file: Blob, fileName: string, title: string, allowDownload: boolean): Observable<HttpEvent<MediaAssetDto>> {
    const body = new FormData();
    body.append('file', file, fileName);
    body.append('title', title);
    body.append('allowDownload', String(allowDownload));
    return this.uploadHttp.request(
      new HttpRequest<FormData>('POST', `${this.base}/uploads/documents`, body, { reportProgress: true, context: this.silent() }),
    );
  }

  /** Owner only. Poll every 2 s while `status` is `processing`. */
  get(id: string): Observable<MediaAssetDto> {
    return this.http.get<MediaAssetDto>(`${this.base}/uploads/${encodeURIComponent(id)}`, { context: this.silent() });
  }

  /** `409 media.in_use` while attached to an article. */
  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/uploads/${encodeURIComponent(id)}`, { context: this.silent() });
  }

  /**
   * Downloads the original PDF (`GET /documents/{assetId}/download`, absolute URL from the DTO). Goes through
   * HttpClient so the bearer token is sent (owners/moderators may download even when downloads are off). Silent: the
   * full-screen viewer sits above the toast layer and shows its own message.
   */
  download(downloadUrl: string): Observable<Blob> {
    return this.http.get(downloadUrl, { responseType: 'blob', context: this.silent() }).pipe(
      catchError((error: unknown) => from(withBlobProblem(error)).pipe(switchMap((e) => throwError(() => e)))),
    );
  }
}

/** With `responseType: 'blob'` the ProblemDetails body arrives as a Blob; parse it so the stable `code` is kept. */
export async function withBlobProblem(error: unknown): Promise<unknown> {
  if (!isApiError(error) || !(error.problem instanceof Blob)) return error;
  try {
    const problem = JSON.parse(await (error.problem as Blob).text()) as ProblemDetails;
    return new ApiError(error.status, problem.code ?? error.code, problem);
  } catch {
    return new ApiError(error.status, error.code, null);
  }
}
