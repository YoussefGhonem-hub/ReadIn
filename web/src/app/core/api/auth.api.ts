import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, webSessionOptions } from './api.config';
import {
  AuthConfigDto,
  ExternalSignInRequest,
  LoginRequest,
  PasswordResetTokenDto,
  RegisterRequest,
  ResetPasswordRequest,
  SessionDto,
  VerifyPinRequest,
} from './models';

/**
 * Phone + password sessions (SPEC §9, ADR 0007). Every call carries `X-ReadIn-Client: web` and credentials, so the
 * API keeps the refresh token in its HttpOnly cookie (`SessionDto.refreshToken` is null on the web).
 */
@Injectable({ providedIn: 'root' })
export class AuthApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);

  /** PIN length and password rules that drive the forms. */
  config(): Observable<AuthConfigDto> {
    return this.http.get<AuthConfigDto>(`${this.base}/auth/config`, webSessionOptions());
  }

  register(body: RegisterRequest): Observable<SessionDto> {
    return this.http.post<SessionDto>(`${this.base}/auth/register`, body, webSessionOptions());
  }

  login(body: LoginRequest): Observable<SessionDto> {
    return this.http.post<SessionDto>(`${this.base}/auth/login`, body, webSessionOptions());
  }

  /**
   * Continue with Google / Apple (ADR 0012): signs in a linked identity (or one whose verified email matches an
   * account). `404 auth.external_not_linked` → ask again with `createAccount` or `link`.
   */
  external(body: ExternalSignInRequest): Observable<SessionDto> {
    return this.http.post<SessionDto>(`${this.base}/auth/external`, body, webSessionOptions());
  }

  /** Rotates the cookie and returns a fresh access token. `401 auth.refresh_invalid` → sign out locally. */
  refresh(): Observable<SessionDto> {
    return this.http.post<SessionDto>(`${this.base}/auth/refresh`, {}, webSessionOptions());
  }

  /** Ends this browser's session and clears the cookie. Always `204`. */
  logout(): Observable<void> {
    return this.http.post<void>(`${this.base}/auth/logout`, {}, webSessionOptions());
  }

  /** Bearer: ends every other session and returns fresh tokens for this one. */
  logoutAll(): Observable<SessionDto> {
    return this.http.post<SessionDto>(`${this.base}/auth/logout-all`, {}, webSessionOptions());
  }

  /** Forgot password, step 1: phone + PIN → a 10-minute reset token. */
  verifyPin(body: VerifyPinRequest): Observable<PasswordResetTokenDto> {
    return this.http.post<PasswordResetTokenDto>(`${this.base}/auth/recovery/verify-pin`, body, webSessionOptions());
  }

  /** Forgot password, step 2. Signs out every session. */
  resetPassword(body: ResetPasswordRequest): Observable<void> {
    return this.http.post<void>(`${this.base}/auth/recovery/reset-password`, body, webSessionOptions());
  }
}
