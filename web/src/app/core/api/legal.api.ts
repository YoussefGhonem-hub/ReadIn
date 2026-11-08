import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { LegalDto, MeDto } from './models';

/**
 * Terms (F37, docs/api/contract-v1.md "Legal & content filter (F37)"): the current terms version with what changed
 * (`GET /legal` 🌐) and accepting it (`POST /me/terms/accept`). Silent: the terms screen shows its own errors.
 */
@Injectable({ providedIn: 'root' })
export class LegalApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  legal(): Observable<LegalDto> {
    return this.http.get<LegalDto>(`${this.base}/legal`, { context: this.silent() });
  }

  /** The current version, accepted now (idempotent) → the updated `MeDto`. */
  accept(): Observable<MeDto> {
    return this.http.post<MeDto>(`${this.base}/me/terms/accept`, null, { context: this.silent() });
  }
}
