import { PLATFORM_ID, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { of } from 'rxjs';
import { MeApi } from '../api/me.api';
import { MeDto } from '../api/models';
import { SessionStore } from '../auth/session.store';
import { LanguageService } from '../i18n/language.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { PUSH_CLIENT, PushClient, PushPermission, WorkerMessage } from './push-client';
import { PushService } from './push.service';

class FakePushClient implements PushClient {
  supported = true;
  current: PushPermission = 'default';
  token = 'fcm-token-1';
  worker: ((message: WorkerMessage) => void) | null = null;

  readonly isSupported = vi.fn(async () => this.supported);
  readonly requestPermission = vi.fn(async (): Promise<PushPermission> => (this.current = 'granted'));
  readonly getToken = vi.fn(async () => this.token);
  readonly deleteToken = vi.fn(async () => undefined);

  permission(): PushPermission {
    return this.current;
  }

  onWorkerMessage(next: (message: WorkerMessage) => void): () => void {
    this.worker = next;
    return () => (this.worker = null);
  }
}

const flush = () => new Promise<void>((resolve) => setTimeout(resolve, 0));

async function setup(client = new FakePushClient()) {
  const meApi = { registerDevice: vi.fn(() => of(undefined)), unregisterDevice: vi.fn(() => of(undefined)) };
  TestBed.configureTestingModule({
    providers: [
      provideRouter([]),
      { provide: PUSH_CLIENT, useValue: client },
      { provide: MeApi, useValue: meApi },
      { provide: LanguageService, useValue: { lang: signal('ar') } },
      { provide: PLATFORM_ID, useValue: 'browser' },
    ],
  });
  const service = TestBed.inject(PushService);
  await service.init();
  return { service, client, meApi, session: TestBed.inject(SessionStore), toasts: TestBed.inject(ToastService) };
}

async function signIn(session: SessionStore, id = 'user-1'): Promise<void> {
  session.setMe({ id, displayName: 'Mona' } as MeDto);
  TestBed.tick();
  await flush();
}

describe('PushService', () => {
  beforeEach(() => TestBed.resetTestingModule());

  it('stays unsupported and never asks where web push is unavailable', async () => {
    const client = new FakePushClient();
    client.supported = false;
    const { service } = await setup(client);

    expect(service.permission()).toBe('unsupported');
    expect(await service.enable()).toBe('unsupported');
    expect(client.requestPermission).not.toHaveBeenCalled();
  });

  it('never asks for permission by itself', async () => {
    const { client, session, meApi } = await setup();
    await signIn(session);

    expect(client.requestPermission).not.toHaveBeenCalled();
    expect(client.getToken).not.toHaveBeenCalled();
    expect(meApi.registerDevice).not.toHaveBeenCalled();
  });

  it('asks in context and then registers this browser for the signed-in user', async () => {
    const { service, session, meApi } = await setup();
    await signIn(session);

    expect(await service.enable()).toBe('granted');
    TestBed.tick();
    await flush();

    expect(meApi.registerDevice).toHaveBeenCalledWith({ token: 'fcm-token-1', platform: 'web' }, { silent: true });
  });

  it('registers on sign-in when permission was granted earlier, once per user and token', async () => {
    const client = new FakePushClient();
    client.current = 'granted';
    const { session, meApi } = await setup(client);

    await signIn(session);
    session.patchMe({ displayName: 'Mona A.' });
    TestBed.tick();
    await flush();
    expect(meApi.registerDevice).toHaveBeenCalledTimes(1);

    // A rotated token is sent again on the next sign-in.
    client.token = 'fcm-token-2';
    session.setGuest();
    TestBed.tick();
    await flush();
    await signIn(session, 'user-2');
    expect(meApi.registerDevice).toHaveBeenLastCalledWith({ token: 'fcm-token-2', platform: 'web' }, { silent: true });
  });

  it('deletes the token on sign-out so the next account gets no pushes for this one', async () => {
    const client = new FakePushClient();
    client.current = 'granted';
    const { session } = await setup(client);
    await signIn(session);

    session.setGuest();
    TestBed.tick();
    await flush();
    expect(client.deleteToken).toHaveBeenCalledTimes(1);
  });

  it('unregisters the device on the API before signing out (DELETE /me/devices/{token})', async () => {
    const client = new FakePushClient();
    client.current = 'granted';
    const { service, session, meApi } = await setup(client);
    await signIn(session);

    await service.unregisterDevice();
    expect(meApi.unregisterDevice).toHaveBeenCalledWith('fcm-token-1');
    expect(client.deleteToken).toHaveBeenCalledTimes(1);

    // Signing out afterwards doesn't delete it twice; nothing registered means nothing to do.
    session.setGuest();
    TestBed.tick();
    await flush();
    await service.unregisterDevice();
    expect(client.deleteToken).toHaveBeenCalledTimes(1);
    expect(meApi.unregisterDevice).toHaveBeenCalledTimes(1);
  });

  it('after the account is deleted, deletes the FCM token without calling the API, once', async () => {
    const client = new FakePushClient();
    client.current = 'granted';
    const { service, session, meApi } = await setup(client);
    await signIn(session);

    await service.forgetDevice();
    expect(client.deleteToken).toHaveBeenCalledTimes(1);
    expect(meApi.unregisterDevice).not.toHaveBeenCalled(); // the API already dropped the account's devices

    session.setGuest(); // the session ends right after: no second deletion
    TestBed.tick();
    await flush();
    expect(client.deleteToken).toHaveBeenCalledTimes(1);
  });

  it('also deletes a token an earlier page load registered, and does nothing without permission', async () => {
    const granted = new FakePushClient();
    granted.current = 'granted'; // nothing registered from this page, but the browser may hold a token
    const first = await setup(granted);
    await first.service.forgetDevice();
    expect(granted.deleteToken).toHaveBeenCalledTimes(1);

    TestBed.resetTestingModule();
    const neverAsked = new FakePushClient();
    const second = await setup(neverAsked);
    await second.service.forgetDevice();
    expect(neverAsked.deleteToken).not.toHaveBeenCalled();
  });

  it('shows a foreground push as a toast that opens the post', async () => {
    const { client, toasts } = await setup();
    client.worker!({
      type: 'push',
      payload: { notification: { title: 'أحمد رد عليك', body: 'تعليق جميل' }, data: { link: 'readin://a/my-post#comment-9' } },
    });

    expect(toasts.toasts()).toEqual([expect.objectContaining({ kind: 'info', message: 'أحمد رد عليك — تعليق جميل', link: '/ar/a/my-post#comment-9' })]);
  });

  it('routes a tapped notification and ignores links to other sites', async () => {
    const { client } = await setup();
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigateByUrl').mockResolvedValue(true);

    client.worker!({ type: 'open', path: '//evil.example' });
    client.worker!({ type: 'open', path: '/ar/a/my-post#comment-9' });

    expect(navigate).toHaveBeenCalledTimes(1);
    expect(navigate).toHaveBeenCalledWith('/ar/a/my-post#comment-9');
  });
});
