import { HttpClient, HttpContext } from '@angular/common/http';
import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';
import { TEST_API, settle, setupAuthTesting, testSession, tokenTag } from '../../../testing/auth-testing';
import { Router } from '@angular/router';
import { ApiError, WITH_SESSION } from '../api/api.config';
import { AuthFlowState } from '../auth/auth-flow';
import { isSessionCall } from './auth.interceptor';
import { HydrationWindow } from './hydration-window';

const unauthorized = { status: 401, statusText: 'Unauthorized' };

/** Starts the app signed in with token "t1". */
async function signedIn() {
  const setup = setupAuthTesting();
  setup.auth.init();
  setup.http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1'));
  await setup.auth.whenReady();
  return { ...setup, client: TestBed.inject(HttpClient) };
}

describe('authInterceptor (SPEC §9.3)', () => {
  beforeEach(() => TestBed.resetTestingModule());

  it('adds the access token as a Bearer header', async () => {
    const { client, http } = await signedIn();
    const done = firstValueFrom(client.get(`${TEST_API}/me`));
    await settle();
    const request = http.expectOne(`${TEST_API}/me`);
    expect(tokenTag(request.request.headers.get('Authorization'))).toBe('t1');
    request.flush({});
    await done;
    http.verify();
  });

  it('waits for the session restore before the first calls, so they are not anonymous', async () => {
    const { auth, http } = setupAuthTesting();
    const client = TestBed.inject(HttpClient);
    auth.init();
    const done = firstValueFrom(client.get(`${TEST_API}/feed/for-you`));
    await settle();
    http.expectNone(`${TEST_API}/feed/for-you`);

    http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1'));
    await settle(10);
    const request = http.expectOne(`${TEST_API}/feed/for-you`);
    expect(tokenTag(request.request.headers.get('Authorization'))).toBe('t1');
    request.flush({ items: [], nextCursor: null });
    await done;
  });

  it('sends guests anonymously', async () => {
    const { auth, http } = setupAuthTesting();
    const client = TestBed.inject(HttpClient);
    auth.init();
    http.expectOne(`${TEST_API}/auth/refresh`).flush({ code: 'auth.refresh_invalid' }, unauthorized);
    await auth.whenReady();
    const done = firstValueFrom(client.get(`${TEST_API}/feed/today`));
    await settle();
    const request = http.expectOne(`${TEST_API}/feed/today`);
    expect(request.request.headers.has('Authorization')).toBe(false);
    request.flush(null);
    await done;
  });

  it('refreshes once for concurrent 401s (single-flight) and retries each call with the new token', async () => {
    const { client, http, session } = await signedIn();
    const first = firstValueFrom(client.get(`${TEST_API}/me`));
    const second = firstValueFrom(client.get(`${TEST_API}/feed/for-you`));
    await settle();
    http.expectOne(`${TEST_API}/me`).flush({ code: 'auth.unauthorized' }, unauthorized);
    http.expectOne(`${TEST_API}/feed/for-you`).flush({ code: 'auth.unauthorized' }, unauthorized);
    await settle(10);

    const refreshes = http.match(`${TEST_API}/auth/refresh`);
    expect(refreshes).toHaveLength(1);
    expect(refreshes[0].request.withCredentials).toBe(true);
    expect(refreshes[0].request.headers.get('X-ReadIn-Client')).toBe('web');
    expect(refreshes[0].request.headers.has('Authorization')).toBe(false);
    refreshes[0].flush(testSession('t2'));
    await settle(10);

    const retriedMe = http.expectOne(`${TEST_API}/me`);
    const retriedFeed = http.expectOne(`${TEST_API}/feed/for-you`);
    expect(tokenTag(retriedMe.request.headers.get('Authorization'))).toBe('t2');
    expect(tokenTag(retriedFeed.request.headers.get('Authorization'))).toBe('t2');
    retriedMe.flush({ id: 'user-1' });
    retriedFeed.flush({ items: [] });
    await expect(first).resolves.toEqual({ id: 'user-1' });
    await expect(second).resolves.toEqual({ items: [] });
    expect(session.isAuthenticated()).toBe(true);
    http.verify();
  });

  it('uses a token another call already refreshed instead of refreshing again', async () => {
    const { client, http, auth } = await signedIn();
    const done = firstValueFrom(client.get(`${TEST_API}/me`));
    await settle();
    const stale = http.expectOne(`${TEST_API}/me`);
    // Meanwhile the timer refreshed the session.
    const refreshed = auth.refresh();
    http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t2'));
    await refreshed;

    stale.flush({}, unauthorized);
    await settle(10);
    http.expectNone(`${TEST_API}/auth/refresh`);
    const retried = http.expectOne(`${TEST_API}/me`);
    expect(tokenTag(retried.request.headers.get('Authorization'))).toBe('t2');
    retried.flush({});
    await done;
  });

  it('signs out locally when the refresh token is no longer valid, and does not retry', async () => {
    const { client, http, session } = await signedIn();
    const done = firstValueFrom(client.get(`${TEST_API}/me`));
    await settle();
    http.expectOne(`${TEST_API}/me`).flush({ code: 'auth.unauthorized' }, unauthorized);
    await settle(10);
    http.expectOne(`${TEST_API}/auth/refresh`).flush({ code: 'auth.refresh_invalid' }, unauthorized);

    const error = await done.catch((e: unknown) => e);
    expect(error).toBeInstanceOf(ApiError);
    expect((error as ApiError).status).toBe(401);
    expect(session.isGuest()).toBe(true);
    http.verify();
  });

  it('does not retry a call that fails with 401 again after the refresh', async () => {
    const { client, http } = await signedIn();
    const done = firstValueFrom(client.get(`${TEST_API}/me`));
    await settle();
    http.expectOne(`${TEST_API}/me`).flush({}, unauthorized);
    await settle(10);
    http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t2'));
    await settle(10);
    http.expectOne(`${TEST_API}/me`).flush({}, unauthorized);
    await expect(done).rejects.toBeInstanceOf(ApiError);
    http.verify();
  });

  it('never sends the access token to the cookie-based session calls, except logout-all', async () => {
    const { client, http } = await signedIn();
    for (const path of ['/auth/login', '/auth/logout', '/auth/logout-all']) void firstValueFrom(client.post(`${TEST_API}${path}`, {}));
    await settle();
    expect(http.expectOne(`${TEST_API}/auth/login`).request.headers.has('Authorization')).toBe(false);
    expect(http.expectOne(`${TEST_API}/auth/logout`).request.headers.has('Authorization')).toBe(false);
    expect(tokenTag(http.expectOne(`${TEST_API}/auth/logout-all`).request.headers.get('Authorization'))).toBe('t1');
  });

  it('leaves other origins alone', async () => {
    const { client, http } = await signedIn();
    void firstValueFrom(client.get('https://cdn.example.com/x.json'));
    await settle();
    expect(http.expectOne('https://cdn.example.com/x.json').request.headers.has('Authorization')).toBe(false);
  });

  it('while hydrating, GETs go out anonymously (SSR transfer cache), except personal ones marked WITH_SESSION', async () => {
    const setup = setupAuthTesting({ providers: [{ provide: HydrationWindow, useValue: { isOpen: true } }] });
    setup.auth.init();
    setup.http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1'));
    await setup.auth.whenReady();
    const client = TestBed.inject(HttpClient);

    const feed = firstValueFrom(client.get(`${TEST_API}/feed/for-you`));
    const saved = firstValueFrom(client.get(`${TEST_API}/me/saved`, { context: new HttpContext().set(WITH_SESSION, true) }));
    await settle();
    const anonymous = setup.http.expectOne(`${TEST_API}/feed/for-you`);
    expect(anonymous.request.headers.has('Authorization')).toBe(false);
    anonymous.flush({});
    const personal = setup.http.expectOne(`${TEST_API}/me/saved`);
    expect(tokenTag(personal.request.headers.get('Authorization'))).toBe('t1');
    personal.flush({});
    await Promise.all([feed, saved]);
  });

  it('a call answered 403 user.suspended ends the session and opens Sign in with the end of the suspension (F22)', async () => {
    const { client, http, session } = await signedIn();
    const router = TestBed.inject(Router);
    const navigate = vi.spyOn(router, 'navigate').mockResolvedValue(true);
    vi.spyOn(router, 'url', 'get').mockReturnValue('/en/a/clean-architecture');
    const suspended = { code: 'user.suspended', status: 403, title: 'This account is suspended.', suspendedUntil: '2026-11-10T14:30:00Z' };

    const first = firstValueFrom(client.put(`${TEST_API}/articles/a1/reaction`, { type: 'love' }));
    const second = firstValueFrom(client.get(`${TEST_API}/me/saved`));
    await settle();
    http.expectOne(`${TEST_API}/articles/a1/reaction`).flush(suspended, { status: 403, statusText: 'Forbidden' });
    http.expectOne(`${TEST_API}/me/saved`).flush(suspended, { status: 403, statusText: 'Forbidden' });
    await expect(first).rejects.toMatchObject({ code: 'user.suspended' });
    await expect(second).rejects.toMatchObject({ code: 'user.suspended' });

    expect(session.isGuest()).toBe(true);
    expect(TestBed.inject(AuthFlowState).suspension()).toEqual({ suspendedUntil: '2026-11-10T14:30:00Z' });
    // Once, even though two calls bounced.
    expect(navigate).toHaveBeenCalledTimes(1);
    expect(navigate).toHaveBeenCalledWith(['/auth/sign-in'], { queryParams: { returnUrl: '/en/a/clean-architecture' } });
    http.verify();
  });

  it('a refresh refused with user.suspended ends the session the same way (F22)', async () => {
    const { client, http, session } = await signedIn();
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    const done = firstValueFrom(client.get(`${TEST_API}/me`));
    await settle();
    http.expectOne(`${TEST_API}/me`).flush({}, unauthorized);
    await settle(10);
    http.expectOne(`${TEST_API}/auth/refresh`).flush({ code: 'user.suspended', suspendedUntil: null }, { status: 403, statusText: 'Forbidden' });
    await expect(done).rejects.toBeInstanceOf(ApiError);
    expect(session.isGuest()).toBe(true);
    expect(TestBed.inject(AuthFlowState).suspension()).toEqual({ suspendedUntil: null });
    expect(navigate).toHaveBeenCalledTimes(1);
    http.verify();
  });

  it('classifies session calls', () => {
    expect(isSessionCall('/auth/refresh')).toBe(true);
    expect(isSessionCall('/auth/recovery/verify-pin')).toBe(true);
    expect(isSessionCall('/auth/logout-all')).toBe(false);
    expect(isSessionCall('/me/password')).toBe(false);
  });
});
