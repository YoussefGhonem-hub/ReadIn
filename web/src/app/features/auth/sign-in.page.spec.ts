import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { TEST_API, settle, setupAuthTesting } from '../../../testing/auth-testing';
import { AuthFlowState } from '../../core/auth/auth-flow';
import { provideAppIcons } from '../../shared/ui/icons';
import { SignInPage } from './sign-in.page';

async function render(prepare: () => void = () => undefined) {
  const testing = setupAuthTesting({ providers: [provideRouter([]), provideAppIcons()] });
  prepare();
  const fixture = TestBed.createComponent(SignInPage);
  fixture.detectChanges();
  testing.http
    .expectOne(`${TEST_API}/auth/config`)
    .flush({ pinLength: 4, password: { minLength: 8, maxLength: 128, requireLetter: true, requireDigit: true }, externalProviders: [] });
  await settle(10);
  fixture.detectChanges();
  const root = fixture.nativeElement as HTMLElement;
  const error = () => root.querySelector('[data-error]')?.textContent?.trim() ?? null;
  /** F35: a suspension shows the support email for appeals, from `GET /support/config`. */
  const supportConfig = async (email: string | null = 'help@readin.test') => {
    // Signed out: the token lookup's refresh finds no session, then the config call goes out anonymously.
    for (const req of testing.http.match(`${TEST_API}/auth/refresh`)) req.flush({ code: 'auth.refresh_invalid', status: 401 }, { status: 401, statusText: 'Unauthorized' });
    await settle(10);
    // Once per time the note appears (it stays while the message does).
    for (const req of testing.http.match(`${TEST_API}/support/config`)) req.flush({ email, categories: [], maxAttachments: 3, maxAttachmentBytes: 5242880, attachmentTypes: [] });
    await settle();
    fixture.detectChanges();
    return root.querySelector('[data-appeal-email]')?.textContent?.trim() ?? null;
  };
  return { ...testing, fixture, root, error, supportConfig };
}

describe('Sign in: suspended accounts (F22)', () => {
  beforeEach(() => TestBed.resetTestingModule());

  it('a session that ended because the account was suspended opens Sign in with until when', async () => {
    const t = await render(() => TestBed.inject(AuthFlowState).suspension.set({ suspendedUntil: '2026-11-10T14:30:00Z' }));
    expect(t.error()).toMatch(/^هذا الحساب موقوف حتى .*نوفمبر 2026.*\.$/);
    expect(TestBed.inject(AuthFlowState).suspension()).toBeNull(); // shown once
    expect(await t.supportConfig()).toBe('help@readin.test');
    t.http.verify();
  });

  it('signing in to a suspended account says until when, or that it is permanent', async () => {
    const t = await render();
    expect(t.error()).toBeNull();
    const page = t.fixture.componentInstance as unknown as { form: { setValue(v: { phone: string; password: string }): void }; submit(): Promise<void> };
    page.form.setValue({ phone: '+201001234567', password: 'Readin2026!' });

    let done = page.submit();
    await settle();
    t.http
      .expectOne(`${TEST_API}/auth/login`)
      .flush({ code: 'user.suspended', status: 403, title: 'This account is suspended.', suspendedUntil: null }, { status: 403, statusText: 'Forbidden' });
    await done;
    t.fixture.detectChanges();
    expect(t.error()).toBe('هذا الحساب موقوف نهائيًا. تواصل مع الدعم.');
    expect(await t.supportConfig()).toBe('help@readin.test');

    done = page.submit();
    await settle();
    t.http
      .expectOne(`${TEST_API}/auth/login`)
      .flush({ code: 'user.suspended', status: 403, suspendedUntil: '2026-11-10T14:30:00Z' }, { status: 403, statusText: 'Forbidden' });
    await done;
    t.fixture.detectChanges();
    expect(t.error()).toContain('هذا الحساب موقوف حتى');
    expect(await t.supportConfig()).toBe('help@readin.test');
    t.http.verify();
  });
});
