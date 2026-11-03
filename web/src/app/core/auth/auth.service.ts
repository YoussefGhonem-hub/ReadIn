import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { firstValueFrom } from 'rxjs';
import { isApiError } from '../api/api.config';
import { AuthApi } from '../api/auth.api';
import { MeApi } from '../api/me.api';
import { MeDto, RegisterRequest, SessionDto } from '../api/models';
import { LanguageService } from '../i18n/language.service';
import { PushService } from '../push/push.service';
import { ThemeService } from '../theme/theme.service';
import { SessionStore } from './session.store';
import { localTimeZone } from './time-zone';

/** Refresh this long before the access token expires (it lives 15 minutes, SPEC §9.3). */
export const REFRESH_AHEAD_MS = 60_000;
/** Never refresh more often than this, whatever the clocks say. */
export const MIN_REFRESH_DELAY_MS = 10_000;
/** After a refresh that failed for a network reason, try again after this delay. */
export const REFRESH_RETRY_MS = 30_000;
const DEFAULT_LIFETIME_MS = 15 * 60_000;

/**
 * The web session (SPEC §9.3, ADR 0007): phone + password against the API, which issues a 15-minute access token and
 * keeps a rotating 30-day refresh token in an HttpOnly cookie. The access token lives in this service's memory only.
 *
 * - On start (browser only, never during SSR) `POST /auth/refresh` restores the session; a 401 means guest.
 * - The token is refreshed shortly before it expires, and once after a 401 (single-flight, see `refresh`).
 * - Every endpoint that returns a `SessionDto` replaces the tokens.
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly api = inject(AuthApi);
  private readonly meApi = inject(MeApi);
  private readonly session = inject(SessionStore);
  private readonly language = inject(LanguageService);
  private readonly theme = inject(ThemeService);
  private readonly push = inject(PushService);

  private accessToken: string | null = null;
  private refreshTimer: ReturnType<typeof setTimeout> | null = null;
  private refreshing: Promise<string | null> | null = null;
  private started = false;
  private resolveReady!: () => void;
  private readonly ready = new Promise<void>((resolve) => (this.resolveReady = resolve));

  /** Restores the session in the background. Called once from an app initializer; a no-op during SSR. */
  init(): void {
    if (!this.isBrowser || this.started) return;
    this.started = true;
    void this.restore();
  }

  /** Waits for the session to be restored (or not). Always null during SSR, where every page is anonymous. */
  async whenReady(): Promise<MeDto | null> {
    if (!this.isBrowser) return null;
    this.init();
    await this.ready;
    return this.session.me();
  }

  /** The current access token, or null for guests. */
  token(): string | null {
    return this.accessToken;
  }

  /** The token for an API call, once the initial restore has finished (so the first calls aren't anonymous). */
  async tokenForRequest(): Promise<string | null> {
    if (!this.isBrowser) return null;
    await this.whenReady();
    return this.accessToken;
  }

  /**
   * A call made with `failedToken` got 401. If another call already refreshed, use that token; otherwise refresh
   * once. Resolves null when the session can't be renewed.
   */
  renewAfterUnauthorized(failedToken: string): Promise<string | null> {
    if (!this.accessToken) return Promise.resolve(null);
    if (this.accessToken !== failedToken) return Promise.resolve(this.accessToken);
    return this.refresh();
  }

  /**
   * Single-flight refresh: concurrent callers share one `POST /auth/refresh`, because refresh tokens rotate and
   * reusing a rotated one ends the session. Resolves the new access token, or null.
   */
  refresh(): Promise<string | null> {
    this.refreshing ??= this.doRefresh().finally(() => (this.refreshing = null));
    return this.refreshing;
  }

  async signIn(phoneNumber: string, password: string): Promise<MeDto> {
    const session = await firstValueFrom(this.api.login({ phoneNumber, password }));
    await this.applySession(session, { profilePreferences: true });
    return session.user;
  }

  /** Sends the UI language and time zone along, so the new profile starts with them. */
  async register(request: Pick<RegisterRequest, 'phoneNumber' | 'password' | 'recoveryPin'>): Promise<MeDto> {
    const session = await firstValueFrom(
      this.api.register({ ...request, uiLanguage: this.language.lang(), timeZone: localTimeZone() }),
    );
    await this.applySession(session);
    return session.user;
  }

  /**
   * Signs out this browser: unregisters web push while the token still works, ends the session on the API (which
   * clears the cookie), then forgets everything locally. The live app signs out of Firebase when the session ends.
   */
  async signOut(): Promise<void> {
    if (this.accessToken) await this.push.unregisterDevice();
    try {
      await firstValueFrom(this.api.logout());
    } catch {
      /* always 204; offline, the token is still dropped below and the cookie expires */
    }
    this.endLocalSession();
  }

  /** Every other session ends; this browser gets fresh tokens. */
  async signOutEverywhere(): Promise<void> {
    await this.applySession(await firstValueFrom(this.api.logoutAll()));
  }

  async changePassword(currentPassword: string, newPassword: string): Promise<MeDto> {
    const session = await firstValueFrom(this.meApi.changePassword(currentPassword, newPassword));
    await this.applySession(session);
    return session.user;
  }

  async changePhone(newPhoneNumber: string, currentPassword: string): Promise<MeDto> {
    const session = await firstValueFrom(this.meApi.changePhone(newPhoneNumber, currentPassword));
    await this.applySession(session);
    return session.user;
  }

  /** Soft delete (requires the password); the API ends every session, so this browser signs out too. */
  async deleteAccount(password: string): Promise<void> {
    await firstValueFrom(this.meApi.deleteAccount(password));
    this.endLocalSession();
  }

  /** Re-reads `/me` (e.g. after onboarding) and updates the session. */
  async refreshMe(): Promise<MeDto | null> {
    try {
      const me = await firstValueFrom(this.meApi.get({ silent: true }));
      this.session.setMe(me);
      return me;
    } catch {
      return this.session.me();
    }
  }

  /** A `MeDto` returned by an endpoint (complete profile, set PIN) replaces the current one. */
  updateMe(me: MeDto): void {
    if (this.accessToken) this.session.setMe(me);
  }

  /** Forgets the session in this browser only (the API already ended it, or can't be reached). */
  endLocalSession(): void {
    this.accessToken = null;
    this.clearTimer();
    this.session.setGuest();
  }

  private async restore(): Promise<void> {
    try {
      await this.applySession(await firstValueFrom(this.api.refresh()), { profilePreferences: true });
    } catch {
      this.endLocalSession(); // 401 auth.refresh_invalid: a guest (offline: browse as a guest too)
    } finally {
      this.resolveReady();
    }
  }

  private async doRefresh(): Promise<string | null> {
    try {
      const session = await firstValueFrom(this.api.refresh());
      await this.applySession(session);
      return session.accessToken;
    } catch (error) {
      const sessionOver = isApiError(error) && error.status >= 400 && error.status < 500 && error.status !== 429;
      if (sessionOver) this.endLocalSession();
      else if (this.accessToken) this.schedule(REFRESH_RETRY_MS); // offline or a server error: keep the session
      return null;
    }
  }

  private async applySession(session: SessionDto, options: { profilePreferences?: boolean } = {}): Promise<void> {
    this.accessToken = session.accessToken;
    this.session.setMe(session.user);
    this.schedule(Math.max(tokenLifetimeMs(session) - REFRESH_AHEAD_MS, MIN_REFRESH_DELAY_MS));
    if (options.profilePreferences) {
      // The profile is the cross-device source of truth for theme and UI language (SPEC §15.5, F18).
      this.theme.setPreference(session.user.theme);
      await this.language.setLanguage(session.user.uiLanguage);
    }
  }

  private schedule(delayMs: number): void {
    this.clearTimer();
    if (!this.isBrowser) return;
    this.refreshTimer = setTimeout(() => {
      this.refreshTimer = null;
      void this.refresh();
    }, delayMs);
  }

  private clearTimer(): void {
    if (this.refreshTimer !== null) clearTimeout(this.refreshTimer);
    this.refreshTimer = null;
  }
}

/**
 * How long a new access token lives, measured on the server's clock (`exp - iat` in the JWT) so a wrong device clock
 * can't cause a refresh loop. Falls back to `accessTokenExpiresAt` and then to 15 minutes.
 */
export function tokenLifetimeMs(session: Pick<SessionDto, 'accessToken' | 'accessTokenExpiresAt'>): number {
  const claims = jwtClaims(session.accessToken);
  const issuedAt = claims?.['iat'] ?? claims?.['nbf'];
  const expires = claims?.['exp'];
  if (typeof expires === 'number' && typeof issuedAt === 'number' && expires > issuedAt) return (expires - issuedAt) * 1000;
  const fromDto = Date.parse(session.accessTokenExpiresAt) - Date.now();
  return Number.isFinite(fromDto) && fromDto > 0 && fromDto <= DEFAULT_LIFETIME_MS * 4 ? fromDto : DEFAULT_LIFETIME_MS;
}

function jwtClaims(token: string): Record<string, unknown> | null {
  try {
    const payload = token.split('.')[1];
    if (!payload) return null;
    const base64 = payload.replace(/-/g, '+').replace(/_/g, '/');
    const claims: unknown = JSON.parse(atob(base64.padEnd(Math.ceil(base64.length / 4) * 4, '=')));
    return claims && typeof claims === 'object' ? (claims as Record<string, unknown>) : null;
  } catch {
    return null;
  }
}
