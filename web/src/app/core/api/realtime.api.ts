import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';

/** Firebase custom token whose `uid` is the ReadIn user id; it only grants reads of `/live/users/{id}`. */
export interface RealtimeTokenDto {
  token: string;
}

@Injectable({ providedIn: 'root' })
export class RealtimeApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);

  /** `POST /realtime/token` (SPEC §17.2). Silent: live updates are optional, REST keeps working without them. */
  token(): Observable<RealtimeTokenDto> {
    return this.http.post<RealtimeTokenDto>(`${this.base}/realtime/token`, null, {
      context: new HttpContext().set(SILENT_ERRORS, true),
    });
  }
}
