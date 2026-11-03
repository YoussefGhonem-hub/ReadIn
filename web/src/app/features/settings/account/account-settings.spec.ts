import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { TEST_API, settle, setupAuthTesting, testMe, testSession } from '../../../../testing/auth-testing';
import { installProviderSdks } from '../../../../testing/external-testing';
import { MeDto } from '../../../core/api/models';
import { EXTERNAL_CLIENT_IDS } from '../../../core/auth/external-identity.service';
import { provideAppIcons } from '../../../shared/ui/icons';
import { AccountSettings } from './account-settings';

const GOOGLE_ONLY = testMe({
  phoneNumber: null,
  hasPassword: false,
  hasRecoveryPin: false,
  externalLogins: [{ provider: 'google', email: 'mona@gmail.com', linkedAt: '2026-11-03T08:00:00Z' }],
});

async function setup(me: MeDto, externalProviders: string[] = ['google', 'apple']) {
  const testing = setupAuthTesting({
    providers: [provideRouter([]), provideAppIcons(), { provide: EXTERNAL_CLIENT_IDS, useValue: { google: 'google-client', apple: '' } }],
  });
  testing.auth.init();
  testing.http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1', me));
  await testing.auth.whenReady();
  const fixture = TestBed.createComponent(AccountSettings);
  fixture.detectChanges();
  testing.http
    .expectOne(`${TEST_API}/auth/config`)
    .flush({ pinLength: 4, password: { minLength: 8, maxLength: 128, requireLetter: true, requireDigit: true }, externalProviders });
  await settle(10);
  fixture.detectChanges();
  return { ...testing, fixture, root: fixture.nativeElement as HTMLElement };
}

describe('Settings → Account (F18)', () => {
  let sdks: ReturnType<typeof installProviderSdks>;

  beforeEach(() => {
    TestBed.resetTestingModule();
    sdks = installProviderSdks();
  });
  afterEach(() => sdks.uninstall());

  it('a phone account sees its number, password and PIN, and Google ready to link', async () => {
    const { root } = await setup(testMe());
    expect(root.querySelector('[data-account-phone]')!.textContent).toContain('+20 10 01234567');
    expect(root.querySelector('[data-open="phone"]')).not.toBeNull();
    expect(root.querySelector('[data-open="password"]')).not.toBeNull();
    expect(root.querySelector('[data-open="pin"]')).not.toBeNull();
    expect(root.querySelector('[data-add-phone-row]')).toBeNull();

    const rows = [...root.querySelectorAll('[data-linked-accounts] [data-provider]')];
    expect(rows.map((r) => r.getAttribute('data-provider'))).toEqual(['google']); // Apple: no web Services ID yet
    expect(rows[0].querySelector('[data-provider-status]')!.textContent).toContain('مش مربوط');
    expect(rows[0].querySelector('[data-link]')).not.toBeNull();
  });

  it('lists linked accounts with their email, also a provider the web cannot offer', async () => {
    const { root } = await setup(
      testMe({
        externalLogins: [
          { provider: 'google', email: 'mona@gmail.com', linkedAt: '2026-11-03T08:00:00Z' },
          { provider: 'apple', email: null, linkedAt: '2026-11-03T08:00:00Z' },
        ],
      }),
    );
    const rows = [...root.querySelectorAll('[data-linked-accounts] [data-provider]')];
    expect(rows.map((r) => r.getAttribute('data-provider'))).toEqual(['google', 'apple']);
    expect(rows[0].querySelector('[data-provider-status] [dir="ltr"]')!.textContent).toBe('mona@gmail.com');
    expect(rows[1].querySelector('[data-provider-status]')!.textContent).toContain('مربوط');
    expect(rows.every((r) => r.querySelector('[data-unlink]'))).toBe(true);
  });

  it('a Google-only account gets "add phone + password" instead of the number, password and PIN', async () => {
    const { root } = await setup(GOOGLE_ONLY);
    expect(root.querySelector('[data-add-phone-row]')).not.toBeNull();
    expect(root.querySelector('[data-open="phone"]')).toBeNull();
    expect(root.querySelector('[data-open="password"]')).toBeNull();
    expect(root.querySelector('[data-open="pin"]')).toBeNull();
  });

  it('explains when the last way to sign in cannot be unlinked', async () => {
    const { root, fixture, http } = await setup(GOOGLE_ONLY);
    root.querySelector<HTMLButtonElement>('[data-unlink]')!.click();
    fixture.detectChanges();
    root.querySelector<HTMLButtonElement>('[data-unlink-confirm]')!.click();
    await settle(10);
    const request = http.expectOne(`${TEST_API}/me/external-logins/google`);
    expect(request.request.method).toBe('DELETE');
    request.flush({ code: 'auth.last_sign_in_method' }, { status: 400, statusText: 'Bad Request' });
    await settle(10);
    fixture.detectChanges();
    expect(root.querySelector('[data-last-method]')!.textContent).toContain('مينفعش تشيل آخر طريقة تدخل بيها');
    expect(root.querySelector('[data-unlink-confirm]')).toBeNull();
  });

  it('links Google after the provider popup, confirmed with the password', async () => {
    const { root, fixture, http, session } = await setup(testMe());
    root.querySelector<HTMLButtonElement>('[data-link]')!.click();
    fixture.detectChanges();
    await settle(10);
    fixture.detectChanges();
    expect(root.querySelector('[data-link-provider] [data-fake-gis]')).not.toBeNull();

    sdks.google.pick('google-token');
    await settle(5);
    fixture.detectChanges();
    const password = root.querySelector<HTMLInputElement>('#link-provider-password')!;
    password.value = 'Nile river 2026';
    password.dispatchEvent(new Event('input'));
    fixture.detectChanges();
    root.querySelector<HTMLFormElement>('[data-link-provider] form')!.dispatchEvent(new Event('submit'));
    await settle(10);

    const request = http.expectOne(`${TEST_API}/me/external-logins`);
    expect(request.request.body).toEqual({ credential: { provider: 'google', idToken: 'google-token' }, password: 'Nile river 2026' });
    request.flush(testMe({ externalLogins: [{ provider: 'google', email: 'mona@gmail.com', linkedAt: '2026-11-03T09:00:00Z' }] }));
    await settle(10);
    fixture.detectChanges();
    expect(session.me()!.externalLogins).toHaveLength(1);
    expect(root.querySelector('[data-link-provider]')).toBeNull();
    expect(root.querySelector('[data-linked-accounts] [data-unlink]')).not.toBeNull();
  });

  it('ends with a red "Delete account" row into the in-app flow, and the email route next to it', async () => {
    for (const me of [testMe(), GOOGLE_ONLY]) {
      TestBed.resetTestingModule();
      const { root, http } = await setup(me);
      const row = root.querySelector<HTMLAnchorElement>('[data-delete-account]')!;
      expect(row.getAttribute('href')).toBe('/settings/delete-account');
      expect(row.className).toContain('text-error');
      expect(row.textContent).toContain('احذف الحساب');
      // The last row of the Account card (the last section of Settings).
      const links = [...root.querySelectorAll('[data-account] a, [data-account] button')];
      expect(links.at(-2)).toBe(row);
      const byEmail = root.querySelector<HTMLAnchorElement>('[data-delete-by-email]')!;
      expect(byEmail.href).toBe('https://readin-cca78.firebaseapp.com/delete-account');
      expect(byEmail.textContent).toContain('احذفه بالإيميل بدل كده');
      http.expectNone((r) => r.url === `${TEST_API}/me` && r.method === 'DELETE');
    }
  });
});
