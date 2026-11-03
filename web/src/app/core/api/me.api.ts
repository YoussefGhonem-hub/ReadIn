import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import {
  MeDto,
  RegisterDeviceRequest,
  SyncUserRequest,
  UpdateInterestsRequest,
  UpdatePreferencesRequest,
  UpdateProfileRequest,
} from './models';

@Injectable({ providedIn: 'root' })
export class MeApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);

  /** Creates the user on first call, refreshes email/photo afterwards. Call after every sign-in. */
  sync(body: SyncUserRequest): Observable<MeDto> {
    return this.http.post<MeDto>(`${this.base}/auth/sync`, body);
  }

  get(options: { silent?: boolean } = {}): Observable<MeDto> {
    return this.http.get<MeDto>(`${this.base}/me`, {
      context: new HttpContext().set(SILENT_ERRORS, options.silent ?? false),
    });
  }

  updateProfile(body: UpdateProfileRequest): Observable<void> {
    return this.http.patch<void>(`${this.base}/me`, body);
  }

  updatePreferences(body: UpdatePreferencesRequest): Observable<void> {
    return this.http.put<void>(`${this.base}/me/preferences`, body);
  }

  updateInterests(body: UpdateInterestsRequest): Observable<void> {
    return this.http.put<void>(`${this.base}/me/interests`, body);
  }

  registerDevice(body: RegisterDeviceRequest): Observable<void> {
    return this.http.post<void>(`${this.base}/me/devices`, body);
  }
}
