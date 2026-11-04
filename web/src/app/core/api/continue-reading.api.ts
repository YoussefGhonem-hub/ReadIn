import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, WITH_SESSION } from './api.config';
import { ContinueReadingDto } from './models';

/**
 * Home's "Continue reading" (F03, Bearer). Apart from ReadingApi, which the streak badge puts in the initial bundle:
 * only Home imports this. Silent: Home just hides the card when it fails.
 */
@Injectable({ providedIn: 'root' })
export class ContinueReadingApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);

  /** `GET /me/continue-reading?limit=` (1–10, default 3), most recently read first. */
  list(limit = 3): Observable<ContinueReadingDto[]> {
    return this.http.get<ContinueReadingDto[]>(`${this.base}/me/continue-reading`, {
      params: new HttpParams().set('limit', String(limit)),
      context: new HttpContext().set(SILENT_ERRORS, true).set(WITH_SESSION, true),
    });
  }
}
