import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { Router, provideRouter } from '@angular/router';
import { TEST_API, settle, setupAuthTesting, testMe, testSession } from '../../../testing/auth-testing';
import { FakeGoogle, installProviderSdks } from '../../../testing/external-testing';
import { EXTERNAL_CLIENT_IDS } from '../../core/auth/external-identity.service';
import { provideAppIcons } from '../../shared/ui/icons';
import { ExternalSignIn } from './external-sign-in';

@Component({
  imports: [ExternalSignIn],
  template: `<rd-external-sign-in returnUrl="/write" [divider]="true" />`,
})
class Host {}

const notLinked = { status: 404, statusText: 'Not Found' };

async function setup(providers: string[] = ['google', 'apple'], ids = { google: 'google-client', apple: '' }) {
  const testing = setupAuthTesting({ providers: [provideRouter([]), provideAppIcons(), { provide: EXTERNAL_CLIENT_IDS, useValue: ids }] });
  const navigate = vi.spyOn(TestBed.inject(Router), 'navigateByUrl').mockResolvedValue(true);
  const fixture = TestBed.createComponent(Host);
  fixture.detectChanges();
  testing.http
    .expectOne(`${TEST_API}/auth/config`)
    .flush({ pinLength: 4, password: { minLength: 8, maxLength: 128, requireLetter: true, requireDigit: true }, externalProviders: providers });
  await settle(10);
  fixture.detectChanges();
  await settle(10); // the button renders once the (fake) GIS script is ready
  fixture.detectChanges();
  return { ...testing, fixture, root: fixture.nativeElement as HTMLElement, navigate };
}

async function pickGoogle(fixture: ComponentFixture<Host>, google: FakeGoogle, http: HttpTestingController) {
  google.pick('google-token');
  await settle(10);
  return http.expectOne(`${TEST_API}/auth/external`);
}

describe('Continue with Google / Apple (SPEC §9.2)', () => {
  let sdks: ReturnType<typeof installProviderSdks>;

  beforeEach(() => {
    TestBed.resetTestingModule();
    sdks = installProviderSdks();
  });
  afterEach(() => sdks.uninstall());

  it('shows the buttons the API and this build allow (Apple hidden without a Services ID)', async () => {
    const { root } = await setup();
    expect(root.querySelector('[data-google-button] [data-fake-gis]')).not.toBeNull();
    expect(root.querySelector('[data-apple-button]')).toBeNull();
  });

  it('shows nothing when no provider is available', async () => {
    const { root } = await setup([]);
    expect(root.querySelector('[data-external-buttons]')).toBeNull();
  });

  it('signs a linked identity in and applies the guards', async () => {
    const { fixture, http, navigate, session } = await setup();
    const request = await pickGoogle(fixture, sdks.google, http);
    expect(request.request.body).toMatchObject({ provider: 'google', idToken: 'google-token', uiLanguage: 'ar' });
    expect(request.request.withCredentials).toBe(true);
    expect(request.request.headers.get('X-ReadIn-Client')).toBe('web');
    request.flush(testSession('t1', testMe()));
    await settle(10);
    expect(session.isAuthenticated()).toBe(true);
    expect(navigate).toHaveBeenCalledWith('/write');
  });

  describe('not linked yet', () => {
    async function notLinkedSheet() {
      const setupResult = await setup();
      const request = await pickGoogle(setupResult.fixture, sdks.google, setupResult.http);
      request.flush({ code: 'auth.external_not_linked', title: 'No ReadIn account is linked' }, notLinked);
      await settle(10);
      setupResult.fixture.detectChanges();
      return setupResult;
    }

    it('asks what to do in an accessible sheet', async () => {
      const { root } = await notLinkedSheet();
      const sheet = root.querySelector('[data-not-linked]')!.closest('section')!;
      expect(sheet.getAttribute('role')).toBe('dialog');
      expect(sheet.getAttribute('aria-modal')).toBe('true');
      expect(sheet.getAttribute('aria-labelledby')).toBe('not-linked-title');
      expect(root.querySelector('#not-linked-title')!.textContent).toContain('لا يوجد حساب ReadIn مرتبط بهذا الحساب حتى الآن');
      expect(root.querySelector('[data-create]')).not.toBeNull();
      expect(root.querySelector('[data-have-account]')).not.toBeNull();
    });

    it('"create a new account" resends the same token with createAccount, then goes to Complete profile', async () => {
      const { root, http, fixture, navigate } = await notLinkedSheet();
      root.querySelector<HTMLButtonElement>('[data-create]')!.click();
      await settle(10);
      const request = http.expectOne(`${TEST_API}/auth/external`);
      expect(request.request.body).toMatchObject({ provider: 'google', idToken: 'google-token', createAccount: true });
      expect(request.request.body.link).toBeUndefined();
      request.flush(testSession('t1', testMe({ isProfileComplete: false, onboardingCompleted: false, hasPassword: false, mustSetRecoveryPin: false })));
      await settle(10);
      fixture.detectChanges();
      expect(navigate).toHaveBeenCalledWith('/auth/complete-profile?returnUrl=%2Fwrite');
      expect(root.querySelector('[data-not-linked]')).toBeNull();
    });

    it('"I have an account" links with phone + password, and shows errors from the API', async () => {
      const { root, http, fixture, navigate } = await notLinkedSheet();
      root.querySelector<HTMLButtonElement>('[data-have-account]')!.click();
      fixture.detectChanges();
      const phone = root.querySelector<HTMLInputElement>('#link-phone')!;
      const password = root.querySelector<HTMLInputElement>('#link-password')!;
      phone.value = '+201001234567';
      phone.dispatchEvent(new Event('input'));
      password.value = 'Nile river 2026';
      password.dispatchEvent(new Event('input'));
      root.querySelector<HTMLFormElement>('[data-link-form]')!.dispatchEvent(new Event('submit'));
      await settle(10);

      const wrong = http.expectOne(`${TEST_API}/auth/external`);
      expect(wrong.request.body).toMatchObject({ idToken: 'google-token', link: { phoneNumber: '+201001234567', password: 'Nile river 2026' } });
      wrong.flush({ code: 'auth.external_conflict' }, { status: 409, statusText: 'Conflict' });
      await settle(10);
      fixture.detectChanges();
      expect(root.querySelector('[data-sheet-error]')!.textContent).toContain('يوجد حساب آخر من النوع نفسه مرتبط بالفعل');

      root.querySelector<HTMLFormElement>('[data-link-form]')!.dispatchEvent(new Event('submit'));
      await settle(10);
      http.expectOne(`${TEST_API}/auth/external`).flush(testSession('t1', testMe()));
      await settle(10);
      expect(navigate).toHaveBeenCalledWith('/write');
    });

    it('forgets the token when the sheet is closed', async () => {
      const { root, fixture, http } = await notLinkedSheet();
      root.querySelector<HTMLButtonElement>('[data-not-linked]')!.closest('section')!.querySelector<HTMLButtonElement>('button[aria-label]')!.click();
      fixture.detectChanges();
      expect(root.querySelector('[data-not-linked]')).toBeNull();
      http.expectNone(`${TEST_API}/auth/external`);
    });
  });

  it('shows the API error when the token is refused, and nothing when the popup is closed', async () => {
    const { fixture, http, root } = await setup();
    const request = await pickGoogle(fixture, sdks.google, http);
    request.flush({ code: 'auth.external_invalid' }, { status: 401, statusText: 'Unauthorized' });
    await settle(10);
    fixture.detectChanges();
    expect(root.querySelector('[data-external-error]')!.textContent).toContain('تعذّر التحقق من تسجيل الدخول عبر Google أو Apple');

    sdks.google.callback?.({});
    await settle(10);
    http.expectNone(`${TEST_API}/auth/external`);
  });
});
