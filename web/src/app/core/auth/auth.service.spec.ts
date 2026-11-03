import { TestBed } from '@angular/core/testing';
import { TEST_API, settle, setupAuthTesting, testMe, testSession, tokenTag } from '../../../testing/auth-testing';
import { MIN_REFRESH_DELAY_MS, REFRESH_AHEAD_MS, REFRESH_RETRY_MS, tokenLifetimeMs } from './auth.service';

const unauthorized = { status: 401, statusText: 'Unauthorized' };

describe('AuthService (SPEC §9.3, ADR 0007)', () => {
  beforeEach(() => TestBed.resetTestingModule());
  afterEach(() => vi.useRealTimers());

  describe('restoring the session on start', () => {
    it('calls POST /auth/refresh with the cookie and the web client header, then applies the profile', async () => {
      const { auth, http, session, theme, language } = setupAuthTesting();
      auth.init();
      const refresh = http.expectOne(`${TEST_API}/auth/refresh`);
      expect(refresh.request.method).toBe('POST');
      expect(refresh.request.withCredentials).toBe(true);
      expect(refresh.request.headers.get('X-ReadIn-Client')).toBe('web');
      refresh.flush(testSession('t1', testMe({ theme: 'dark', uiLanguage: 'en' })));

      const me = await auth.whenReady();
      expect(me?.id).toBe('user-1');
      expect(session.isAuthenticated()).toBe(true);
      expect(tokenTag(`Bearer ${auth.token()}`)).toBe('t1');
      expect(theme.setPreference).toHaveBeenCalledWith('dark');
      expect(language.setLanguage).toHaveBeenCalledWith('en');
    });

    it('is a guest when the refresh cookie is missing or invalid', async () => {
      const { auth, http, session } = setupAuthTesting();
      auth.init();
      http.expectOne(`${TEST_API}/auth/refresh`).flush({ code: 'auth.refresh_invalid' }, unauthorized);
      expect(await auth.whenReady()).toBeNull();
      expect(session.isGuest()).toBe(true);
      expect(auth.token()).toBeNull();
    });

    it('is a guest when the API is unreachable', async () => {
      const { auth, http, session } = setupAuthTesting();
      auth.init();
      http.expectOne(`${TEST_API}/auth/refresh`).error(new ProgressEvent('error'));
      await auth.whenReady();
      expect(session.isGuest()).toBe(true);
    });

    it('restores only once', async () => {
      const { auth, http } = setupAuthTesting();
      auth.init();
      auth.init();
      void auth.whenReady();
      expect(http.match(`${TEST_API}/auth/refresh`)).toHaveLength(1);
    });

    it('does nothing during SSR, where every page is anonymous', async () => {
      const { auth, http, session } = setupAuthTesting({ platform: 'server' });
      auth.init();
      expect(await auth.whenReady()).toBeNull();
      expect(await auth.tokenForRequest()).toBeNull();
      http.expectNone(`${TEST_API}/auth/refresh`);
      expect(session.isResolved()).toBe(false);
    });
  });

  describe('refreshing', () => {
    it('refreshes shortly before the access token expires and keeps the new token', async () => {
      vi.useFakeTimers();
      const { auth, http } = setupAuthTesting();
      auth.init();
      http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1'));
      await settle();

      vi.advanceTimersByTime(900_000 - REFRESH_AHEAD_MS - 1);
      http.expectNone(`${TEST_API}/auth/refresh`);
      vi.advanceTimersByTime(1);
      http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t2'));
      await settle();
      expect(tokenTag(`Bearer ${auth.token()}`)).toBe('t2');
    });

    it('never schedules refreshes closer than the minimum delay', async () => {
      vi.useFakeTimers();
      const { auth, http } = setupAuthTesting();
      auth.init();
      http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1', testMe(), 30));
      await settle();
      vi.advanceTimersByTime(MIN_REFRESH_DELAY_MS - 1);
      http.expectNone(`${TEST_API}/auth/refresh`);
      vi.advanceTimersByTime(1);
      expect(http.match(`${TEST_API}/auth/refresh`)).toHaveLength(1);
    });

    it('keeps the session and retries later when a refresh fails for a network reason', async () => {
      vi.useFakeTimers();
      const { auth, http, session } = setupAuthTesting();
      auth.init();
      http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1'));
      await settle();

      const result = auth.refresh();
      http.expectOne(`${TEST_API}/auth/refresh`).error(new ProgressEvent('error'));
      expect(await result).toBeNull();
      expect(session.isAuthenticated()).toBe(true);
      vi.advanceTimersByTime(REFRESH_RETRY_MS);
      expect(http.match(`${TEST_API}/auth/refresh`)).toHaveLength(1);
    });

    it('shares one refresh between concurrent callers', async () => {
      const { auth, http } = setupAuthTesting();
      auth.init();
      http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1'));
      await auth.whenReady();

      const results = Promise.all([auth.refresh(), auth.refresh(), auth.renewAfterUnauthorized(auth.token()!)]);
      const calls = http.match(`${TEST_API}/auth/refresh`);
      expect(calls).toHaveLength(1);
      calls[0].flush(testSession('t2'));
      const tokens = await results;
      expect(tokens.map((t) => tokenTag(`Bearer ${t}`))).toEqual(['t2', 't2', 't2']);
    });

    it('measures the token lifetime on the server clock (JWT iat/exp), not the device clock', () => {
      const session = testSession('t1', testMe(), 900);
      expect(tokenLifetimeMs({ ...session, accessTokenExpiresAt: '2001-01-01T00:00:00Z' })).toBe(900_000);
      expect(tokenLifetimeMs({ accessToken: 'not-a-jwt', accessTokenExpiresAt: 'garbage' })).toBe(900_000);
    });
  });

  describe('signing in and out', () => {
    it('signs in with phone + password and applies the profile preferences', async () => {
      const { auth, http, session, theme } = setupAuthTesting();
      auth.init();
      http.expectOne(`${TEST_API}/auth/refresh`).flush({}, unauthorized);
      await auth.whenReady();

      const signIn = auth.signIn('+201001234567', 'Nile river 2026');
      const login = http.expectOne(`${TEST_API}/auth/login`);
      expect(login.request.body).toEqual({ phoneNumber: '+201001234567', password: 'Nile river 2026' });
      expect(login.request.withCredentials).toBe(true);
      expect(login.request.headers.get('X-ReadIn-Client')).toBe('web');
      login.flush(testSession('t1', testMe({ theme: 'light' })));
      expect((await signIn).id).toBe('user-1');
      expect(session.isAuthenticated()).toBe(true);
      expect(theme.setPreference).toHaveBeenCalledWith('light');
    });

    it('registers with the UI language and time zone', async () => {
      const { auth, http, language } = setupAuthTesting();
      language.lang.set('en');
      const register = auth.register({ phoneNumber: '+201001234567', password: 'Nile river 2026', recoveryPin: '4829' });
      const call = http.expectOne(`${TEST_API}/auth/register`);
      expect(call.request.body).toMatchObject({ phoneNumber: '+201001234567', recoveryPin: '4829', uiLanguage: 'en' });
      expect(typeof call.request.body.timeZone).toBe('string');
      call.flush(testSession('t1', testMe({ isProfileComplete: false })));
      expect((await register).isProfileComplete).toBe(false);
      expect(auth.token()).not.toBeNull();
    });

    it('signs out: unregisters web push first, ends the API session, then forgets everything', async () => {
      const { auth, http, session, push } = setupAuthTesting();
      auth.init();
      http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1'));
      await auth.whenReady();

      const signOut = auth.signOut();
      await settle(10);
      expect(push.unregisterDevice).toHaveBeenCalled();
      const logout = http.expectOne(`${TEST_API}/auth/logout`);
      expect(logout.request.withCredentials).toBe(true);
      expect(logout.request.headers.has('Authorization')).toBe(false);
      logout.flush(null, { status: 204, statusText: 'No Content' });
      await signOut;
      expect(session.isGuest()).toBe(true);
      expect(auth.token()).toBeNull();
    });

    it('still signs out locally when the API is unreachable', async () => {
      const { auth, http, session } = setupAuthTesting();
      auth.init();
      http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1'));
      await auth.whenReady();
      const signOut = auth.signOut();
      await settle(10);
      http.expectOne(`${TEST_API}/auth/logout`).error(new ProgressEvent('error'));
      await signOut;
      expect(session.isGuest()).toBe(true);
    });
  });

  describe('endpoints that return a new session replace the tokens', () => {
    async function signedIn() {
      const setup = setupAuthTesting();
      setup.auth.init();
      setup.http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1'));
      await setup.auth.whenReady();
      return setup;
    }

    it('sign out of all devices', async () => {
      const { auth, http } = await signedIn();
      const done = auth.signOutEverywhere();
      await settle();
      const call = http.expectOne(`${TEST_API}/auth/logout-all`);
      expect(tokenTag(call.request.headers.get('Authorization'))).toBe('t1');
      call.flush(testSession('t2'));
      await done;
      expect(tokenTag(`Bearer ${auth.token()}`)).toBe('t2');
    });

    it('change password', async () => {
      const { auth, http } = await signedIn();
      const done = auth.changePassword('old-pass-1', 'Nile river 2026');
      await settle();
      const call = http.expectOne(`${TEST_API}/me/password`);
      expect(call.request.method).toBe('PUT');
      expect(call.request.withCredentials).toBe(true);
      expect(call.request.headers.get('X-ReadIn-Client')).toBe('web');
      expect(call.request.body).toEqual({ currentPassword: 'old-pass-1', newPassword: 'Nile river 2026' });
      call.flush(testSession('t2', testMe({ mustChangePassword: false })));
      await done;
      expect(tokenTag(`Bearer ${auth.token()}`)).toBe('t2');
    });

    it('change phone number', async () => {
      const { auth, http, session } = await signedIn();
      const done = auth.changePhone('+966501234567', 'pass-1234');
      await settle();
      const call = http.expectOne(`${TEST_API}/me/phone`);
      expect(call.request.withCredentials).toBe(true);
      expect(call.request.body).toEqual({ newPhoneNumber: '+966501234567', currentPassword: 'pass-1234' });
      call.flush(testSession('t2', testMe({ phoneNumber: '+966501234567' })));
      await done;
      expect(session.phoneNumber()).toBe('+966501234567');
      expect(tokenTag(`Bearer ${auth.token()}`)).toBe('t2');
    });

    it('delete account ends the session locally', async () => {
      const { auth, http, session } = await signedIn();
      const done = auth.deleteAccount({ password: 'pass-1234' });
      await settle();
      const call = http.expectOne(`${TEST_API}/me`);
      expect(call.request.method).toBe('DELETE');
      expect(call.request.withCredentials).toBe(true);
      expect(call.request.body).toEqual({ password: 'pass-1234' });
      call.flush(null, { status: 204, statusText: 'No Content' });
      await done;
      expect(session.isGuest()).toBe(true);
    });
  });
});
