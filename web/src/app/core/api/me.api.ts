import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS, webSessionOptions } from './api.config';
import {
  AccountConfirmation,
  CompleteProfileRequest,
  ExternalCredential,
  ExternalProvider,
  MeDto,
  RegisterDeviceRequest,
  SessionDto,
  UpdateInterestsRequest,
  UpdatePreferencesRequest,
  UsernameAvailabilityDto,
} from './models';

@Injectable({ providedIn: 'root' })
export class MeApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly silent = () => new HttpContext().set(SILENT_ERRORS, true);

  get(options: { silent?: boolean } = {}): Observable<MeDto> {
    return this.http.get<MeDto>(`${this.base}/me`, {
      context: new HttpContext().set(SILENT_ERRORS, options.silent ?? false),
    });
  }

  /** After sign up: display name, unique @username and an optional avatar URL from `POST /uploads/images`. */
  completeProfile(body: CompleteProfileRequest): Observable<MeDto> {
    return this.http.put<MeDto>(`${this.base}/me/profile/complete`, body, { context: this.silent() });
  }

  /** Live @username check (format + availability; your own handle counts as available). */
  usernameAvailable(username: string): Observable<UsernameAvailabilityDto> {
    return this.http.get<UsernameAvailabilityDto>(`${this.base}/users/username-available`, {
      params: new HttpParams().set('u', username),
      context: this.silent(),
    });
  }

  /** The mandatory first PIN (`mustSetRecoveryPin`). */
  setRecoveryPin(pin: string): Observable<MeDto> {
    return this.http.post<MeDto>(`${this.base}/me/recovery-pin`, { pin }, { context: this.silent() });
  }

  /** Settings → change PIN. */
  changeRecoveryPin(currentPassword: string, newPin: string): Observable<void> {
    return this.http.put<void>(`${this.base}/me/recovery-pin`, { currentPassword, newPin }, { context: this.silent() });
  }

  /** Other sessions end; this one gets fresh tokens (and a new refresh cookie). */
  changePassword(currentPassword: string, newPassword: string): Observable<SessionDto> {
    return this.http.put<SessionDto>(`${this.base}/me/password`, { currentPassword, newPassword }, webSessionOptions());
  }

  /** Other sessions end; this one gets fresh tokens (and a new refresh cookie). */
  changePhone(newPhoneNumber: string, currentPassword: string): Observable<SessionDto> {
    return this.http.put<SessionDto>(`${this.base}/me/phone`, { newPhoneNumber, currentPassword }, webSessionOptions());
  }

  /**
   * Soft delete, confirmed with the password or (accounts without one) a fresh Google/Apple token; every session ends
   * and the cookie is cleared.
   */
  deleteAccount(confirmation: AccountConfirmation): Observable<void> {
    return this.http.delete<void>(`${this.base}/me`, { ...webSessionOptions(), body: confirmation });
  }

  /** Google/Apple-only accounts add phone + password + PIN, confirmed with a linked provider. Other sessions end. */
  addPhoneSignIn(body: { phoneNumber: string; password: string; recoveryPin: string; external: ExternalCredential }): Observable<SessionDto> {
    return this.http.post<SessionDto>(`${this.base}/me/phone-sign-in`, body, webSessionOptions());
  }

  /** Links Google/Apple, confirmed with the password or a fresh token of an already linked provider. */
  linkExternal(credential: ExternalCredential, confirmation: AccountConfirmation): Observable<MeDto> {
    return this.http.post<MeDto>(`${this.base}/me/external-logins`, { credential, ...confirmation }, { context: this.silent() });
  }

  /** `400 auth.last_sign_in_method` when it's the only way to sign in. */
  unlinkExternal(provider: ExternalProvider): Observable<MeDto> {
    return this.http.delete<MeDto>(`${this.base}/me/external-logins/${encodeURIComponent(provider)}`, { context: this.silent() });
  }

  updatePreferences(body: UpdatePreferencesRequest): Observable<void> {
    return this.http.put<void>(`${this.base}/me/preferences`, body);
  }

  updateInterests(body: UpdateInterestsRequest): Observable<void> {
    return this.http.put<void>(`${this.base}/me/interests`, body);
  }

  registerDevice(body: RegisterDeviceRequest, options: { silent?: boolean } = {}): Observable<void> {
    return this.http.post<void>(`${this.base}/me/devices`, body, {
      context: new HttpContext().set(SILENT_ERRORS, options.silent ?? false),
    });
  }

  /** On sign out, while the access token is still valid. Idempotent. */
  unregisterDevice(token: string): Observable<void> {
    return this.http.delete<void>(`${this.base}/me/devices/${encodeURIComponent(token)}`, { context: this.silent() });
  }
}
