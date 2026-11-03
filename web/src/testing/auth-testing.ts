import { PLATFORM_ID, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { API_BASE_URL } from '../app/core/api/api.config';
import { MeDto, SessionDto } from '../app/core/api/models';
import { AuthService } from '../app/core/auth/auth.service';
import { SessionStore } from '../app/core/auth/session.store';
import { API_INTERCEPTORS } from '../app/core/http/api-interceptors';
import { LanguageService } from '../app/core/i18n/language.service';
import { PushService } from '../app/core/push/push.service';
import { ThemeService } from '../app/core/theme/theme.service';
import { translocoTesting } from './transloco-testing';

export const TEST_API = 'https://api.test/api/v1';

/** A signed-in account that has finished every setup step. */
export function testMe(patch: Partial<MeDto> = {}): MeDto {
  return {
    id: 'user-1',
    phoneNumber: '+201001234567',
    email: null,
    displayName: 'Mona Adel',
    username: 'mona',
    avatarUrl: null,
    bio: null,
    links: {},
    uiLanguage: 'ar',
    articleLanguage: 'ar-EG',
    theme: 'system',
    timeZone: 'Africa/Cairo',
    reminderTime: '08:00',
    isVerified: false,
    onboardingCompleted: true,
    mustChangePassword: false,
    mustSetRecoveryPin: false,
    isProfileComplete: true,
    hasRecoveryPin: true,
    roles: ['Member'],
    permissions: ['articles.read', 'articles.create'],
    interests: { fieldIds: [], topicIds: [] },
    ...patch,
  };
}

function base64Url(value: unknown): string {
  return btoa(JSON.stringify(value)).replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');
}

/** A session whose JWT lives `lifetimeSeconds` (iat/exp), like the API's 15-minute access tokens. */
export function testSession(token: string, me: MeDto = testMe(), lifetimeSeconds = 900): SessionDto {
  const iat = 1_800_000_000;
  const jwt = [base64Url({ alg: 'HS256' }), base64Url({ sub: me.id, iat, exp: iat + lifetimeSeconds, tag: token }), 'signature'].join('.');
  return {
    accessToken: jwt,
    accessTokenExpiresAt: new Date(Date.now() + lifetimeSeconds * 1000).toISOString(),
    refreshToken: null,
    refreshTokenExpiresAt: new Date(Date.now() + 30 * 86_400_000).toISOString(),
    user: me,
  };
}

/** The `tag` claim of a test token, to tell tokens apart in assertions. */
export function tokenTag(authorization: string | null): string | null {
  const payload = authorization?.replace(/^Bearer /, '').split('.')[1];
  if (!payload) return null;
  return (JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/'))) as { tag?: string }).tag ?? null;
}

/**
 * The real AuthService + interceptor chain against HttpTestingController, in the browser. Push, theme and language
 * are fakes, so the tests see exactly which HTTP calls the session makes.
 */
export function setupAuthTesting(options: { platform?: 'browser' | 'server' } = {}) {
  const push = { unregisterDevice: vi.fn(async () => undefined) };
  const theme = { setPreference: vi.fn() };
  const language = { lang: signal<'ar' | 'en'>('ar'), setLanguage: vi.fn(async () => undefined) };
  TestBed.configureTestingModule({
    imports: [translocoTesting()],
    providers: [
      provideHttpClient(withInterceptors(API_INTERCEPTORS)),
      provideHttpClientTesting(),
      { provide: API_BASE_URL, useValue: TEST_API },
      { provide: PLATFORM_ID, useValue: options.platform ?? 'browser' },
      { provide: PushService, useValue: push },
      { provide: ThemeService, useValue: theme },
      { provide: LanguageService, useValue: language },
    ],
  });
  return {
    auth: TestBed.inject(AuthService),
    session: TestBed.inject(SessionStore),
    http: TestBed.inject(HttpTestingController),
    push,
    theme,
    language,
  };
}

/** Lets pending promise callbacks (and the interceptor's async token lookup) run. */
export async function settle(times = 5): Promise<void> {
  for (let i = 0; i < times; i++) await Promise.resolve();
}
