import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { FakeApple, FakeGoogle, installProviderSdks } from '../../../testing/external-testing';
import { API_BASE_URL } from '../api/api.config';
import { EXTERNAL_CLIENT_IDS, ExternalIdentityService, appleDisplayName, createNonce, credentialOf } from './external-identity.service';

const API = 'https://api.test/api/v1';

function setup(ids = { google: 'google-client', apple: 'apple-services-id' }, platform = 'browser') {
  TestBed.configureTestingModule({
    providers: [
      provideHttpClient(),
      provideHttpClientTesting(),
      { provide: API_BASE_URL, useValue: API },
      { provide: PLATFORM_ID, useValue: platform },
      { provide: EXTERNAL_CLIENT_IDS, useValue: ids },
    ],
  });
  return { service: TestBed.inject(ExternalIdentityService), http: TestBed.inject(HttpTestingController) };
}

async function withConfig(http: HttpTestingController, service: ExternalIdentityService, providers: string[]): Promise<void> {
  const loading = service.load();
  http
    .expectOne(`${API}/auth/config`)
    .flush({ pinLength: 4, password: { minLength: 8, maxLength: 128, requireLetter: true, requireDigit: true }, externalProviders: providers });
  await loading;
}

describe('ExternalIdentityService (ADR 0012)', () => {
  let sdks: { google: FakeGoogle; apple: FakeApple; uninstall: () => void };

  beforeEach(() => {
    TestBed.resetTestingModule();
    sdks = installProviderSdks();
  });
  afterEach(() => sdks.uninstall());

  describe('which buttons show', () => {
    it('only providers the API lists and this build has a client id for', async () => {
      const { service, http } = setup({ google: 'google-client', apple: '' });
      expect(service.providers()).toEqual([]);
      await withConfig(http, service, ['google', 'apple']);
      expect(service.providers()).toEqual(['google']); // no Apple Services ID yet
    });

    it('hides a provider the API turned off', async () => {
      const { service, http } = setup();
      await withConfig(http, service, ['apple']);
      expect(service.providers()).toEqual(['apple']);
    });
  });

  describe('Google', () => {
    it("renders Google's own button in the UI theme and language, then hands over the ID token", async () => {
      const { service } = setup();
      const host = document.body.appendChild(document.createElement('div'));
      const received: unknown[] = [];
      await service.renderGoogleButton(host, { theme: 'dark', locale: 'ar', width: 1000 }, (r) => received.push(r));

      expect(sdks.google.initialize).toHaveBeenCalledWith(expect.objectContaining({ client_id: 'google-client', ux_mode: 'popup', auto_select: false }));
      expect(sdks.google.renderButton).toHaveBeenCalledWith(host, expect.objectContaining({ theme: 'filled_black', locale: 'ar', width: 400, text: 'continue_with' }));
      sdks.google.pick('id-token-1');
      expect(received).toEqual([{ provider: 'google', idToken: 'id-token-1' }]);
      host.remove();
    });

    it('initializes once and sends the credential to the button still on the page', async () => {
      const { service } = setup();
      const first = document.body.appendChild(document.createElement('div'));
      const second = document.body.appendChild(document.createElement('div'));
      const a = vi.fn();
      const b = vi.fn();
      await service.renderGoogleButton(first, { theme: 'light', locale: 'en', width: 300 }, a);
      await service.renderGoogleButton(second, { theme: 'light', locale: 'en', width: 300 }, b);
      expect(sdks.google.initialize).toHaveBeenCalledTimes(1);
      expect(sdks.google.renderButton).toHaveBeenLastCalledWith(second, expect.objectContaining({ theme: 'outline' }));

      second.remove(); // e.g. a sheet closed
      sdks.google.pick();
      expect(b).not.toHaveBeenCalled();
      expect(a).toHaveBeenCalledTimes(1);
      first.remove();
    });

    it('ignores an empty credential and does nothing without a client id or on the server', async () => {
      const { service } = setup({ google: '', apple: '' });
      await service.renderGoogleButton(document.createElement('div'), { theme: 'light', locale: 'en', width: 300 }, vi.fn());
      expect(sdks.google.initialize).not.toHaveBeenCalled();

      TestBed.resetTestingModule();
      const server = setup(undefined, 'server').service;
      await server.renderGoogleButton(document.createElement('div'), { theme: 'light', locale: 'en', width: 300 }, vi.fn());
      expect(sdks.google.renderButton).not.toHaveBeenCalled();
      expect(await server.signInWithApple()).toBeNull();
    });
  });

  describe('Apple', () => {
    it('gives Apple the SHA-256 of a fresh nonce and the API the raw one, with the first-time name', async () => {
      const { service } = setup();
      const result = await service.signInWithApple();

      expect(sdks.apple.config).toMatchObject({ clientId: 'apple-services-id', scope: 'name email', usePopup: true, redirectURI: location.origin });
      expect(result).toMatchObject({ provider: 'apple', idToken: 'apple-id-token', displayName: 'Mona Adel' });
      const expected = [...new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(result!.nonce!)))]
        .map((b) => b.toString(16).padStart(2, '0'))
        .join('');
      expect(sdks.apple.config!.nonce).toBe(expected);
    });

    it("passes Apple's one-time authorization code on, so the API can revoke Apple's token on deletion", async () => {
      const { service } = setup();
      const result = await service.signInWithApple();
      expect(result).toMatchObject({ provider: 'apple', authorizationCode: 'apple-auth-code' });
      expect(credentialOf(result!)).toEqual({ provider: 'apple', idToken: 'apple-id-token', nonce: result!.nonce, authorizationCode: 'apple-auth-code' });

      sdks.apple.next = { authorization: { id_token: 'apple-id-token-2' } }; // no code: nothing made up
      expect(credentialOf((await service.signInWithApple())!)).not.toHaveProperty('authorizationCode');
    });

    it('does nothing when the popup is closed', async () => {
      const { service } = setup();
      sdks.apple.next = 'cancel';
      expect(await service.signInWithApple()).toBeNull();
    });

    it('builds the display name only from what Apple sent', () => {
      expect(appleDisplayName({ firstName: ' Mona ', lastName: '' })).toBe('Mona');
      expect(appleDisplayName(undefined)).toBeUndefined();
    });

    it('makes a new nonce every time', async () => {
      const a = await createNonce();
      const b = await createNonce();
      expect(a.raw).not.toBe(b.raw);
      expect(a.hashed).toMatch(/^[0-9a-f]{64}$/);
    });
  });
});
