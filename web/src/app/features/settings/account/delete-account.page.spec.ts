import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { TestRequest } from '@angular/common/http/testing';
import { Router, Routes, provideRouter } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';
import { TranslocoService } from '@jsverse/transloco';
import { TEST_API, settle, setupAuthTesting, testMe, testSession, tokenTag } from '../../../../testing/auth-testing';
import { installProviderSdks } from '../../../../testing/external-testing';
import { MeDto } from '../../../core/api/models';
import { EXTERNAL_CLIENT_IDS } from '../../../core/auth/external-identity.service';
import { provideAppIcons } from '../../../shared/ui/icons';
import { SignInPage } from '../../auth/sign-in.page';
import { DeleteAccountPage } from './delete-account.page';

@Component({ template: '' })
class Blank {}

const ROUTES: Routes = [
  { path: 'settings', component: Blank },
  { path: 'settings/delete-account', component: DeleteAccountPage },
  { path: 'auth/sign-in', component: SignInPage },
];

const LINKED_AT = '2026-11-03T08:00:00Z';
const WITH_PASSWORD = testMe();
const PASSWORD_AND_APPLE = testMe({ externalLogins: [{ provider: 'apple', email: null, linkedAt: LINKED_AT }] });
const GOOGLE_ONLY = testMe({
  phoneNumber: null,
  hasPassword: false,
  hasRecoveryPin: false,
  externalLogins: [{ provider: 'google', email: 'mona@gmail.com', linkedAt: LINKED_AT }],
});
const APPLE_ONLY = testMe({ phoneNumber: null, hasPassword: false, hasRecoveryPin: false, externalLogins: [{ provider: 'apple', email: null, linkedAt: LINKED_AT }] });

const PASSWORD = 'Nile river 2026';
const problem = (status: number, code: string, title = code) => ({ body: { code, title, status }, status, statusText: String(status) });

async function setup(me: MeDto, options: { apple?: boolean; lang?: 'ar' | 'en' } = {}) {
  const testing = setupAuthTesting({
    providers: [
      provideRouter(ROUTES),
      provideAppIcons(),
      { provide: EXTERNAL_CLIENT_IDS, useValue: { google: 'google-client', apple: options.apple ? 'apple-services-id' : '' } },
    ],
  });
  if (options.lang) TestBed.inject(TranslocoService).setActiveLang(options.lang);
  testing.auth.init();
  testing.http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t1', me));
  await testing.auth.whenReady();

  const harness = await RouterTestingHarness.create('/settings/delete-account');
  testing.http
    .expectOne(`${TEST_API}/auth/config`)
    .flush({ pinLength: 4, password: { minLength: 8, maxLength: 128, requireLetter: true, requireDigit: true }, externalProviders: ['google', 'apple'] });
  await settle(10);
  harness.detectChanges();

  const root = () => harness.routeNativeElement as HTMLElement;
  const $ = <T extends HTMLElement = HTMLElement>(selector: string) => root().querySelector<T>(selector);
  /** Lets promises run, renders, then lets what rendering started run too (effects, the fake provider SDKs). */
  const render = async (times = 10) => {
    await settle(times);
    harness.detectChanges();
    await settle(times);
    harness.detectChanges();
    await settle(2);
  };
  /** Waits across real event-loop turns (Apple's nonce is hashed with WebCrypto), rendering each time. */
  const until = <T>(check: () => T | null | undefined): Promise<T> =>
    vi.waitFor(
      () => {
        harness.detectChanges();
        const value = check();
        if (!value) throw new Error('not yet');
        return value;
      },
      { timeout: 2000, interval: 5 },
    );

  return { ...testing, harness, root, $, render, until };
}

type Page = Awaited<ReturnType<typeof setup>>;

async function toConfirm(page: Page): Promise<void> {
  page.$<HTMLButtonElement>('[data-continue]')!.click();
  await page.render(5); // the provider buttons render once the (fake) SDK is ready
}

function typePassword(page: Page, value = PASSWORD): void {
  const input = page.$<HTMLInputElement>('#delete-account-password')!;
  input.value = value;
  input.dispatchEvent(new Event('input'));
  page.harness.detectChanges();
}

function tickUnderstood(page: Page): void {
  page.$<HTMLInputElement>('[data-understood]')!.click();
  page.harness.detectChanges();
}

async function submit(page: Page): Promise<void> {
  page.$<HTMLFormElement>('[data-delete-form]')!.dispatchEvent(new Event('submit'));
  await page.render(2);
}

/** Red button → "Delete forever" in the final dialog → the request. */
async function deleteForever(page: Page): Promise<void> {
  await submit(page);
  page.$<HTMLButtonElement>('[data-delete-forever]')!.click();
  await page.render();
}

const isDelete = (r: { url: string; method: string }) => r.url === `${TEST_API}/me` && r.method === 'DELETE';

function deleteRequest(page: Page): TestRequest {
  return page.http.expectOne(isDelete);
}

/** A DELETE sent after Apple sign in, which takes real event-loop turns. */
function laterDeleteRequest(page: Page): Promise<TestRequest> {
  return page.until(() => page.http.match(isDelete)[0]);
}

function noDeleteRequest(page: Page): void {
  page.http.expectNone(isDelete);
}

async function flushProblem(page: Page, request: TestRequest, status: number, code: string): Promise<void> {
  const { body, ...options } = problem(status, code);
  request.flush(body, options);
  await page.render();
}

/** After `204`: the session is gone and Sign in shows the confirmation. */
async function expectDeleted(page: Page): Promise<void> {
  await page.until(() => TestBed.inject(Router).url === '/auth/sign-in' && page.root()?.querySelector('[data-banner]'));
  expect(page.session.isGuest()).toBe(true);
  expect(page.auth.token()).toBeNull();
  const banner = page.root().querySelector('[data-banner="accountDeleted"]')!;
  expect(banner.getAttribute('role')).toBe('status');
  expect(banner.textContent).toContain('تم حذف حسابك.');
}

describe('Delete account (SPEC F01, immediate hard delete)', () => {
  let sdks: ReturnType<typeof installProviderSdks>;

  beforeEach(() => {
    TestBed.resetTestingModule();
    sdks = installProviderSdks();
  });
  afterEach(() => {
    sdks.uninstall();
    vi.restoreAllMocks();
    localStorage.clear();
  });

  it('first says what is deleted, what is kept and why, before asking anything', async () => {
    const page = await setup(WITH_PASSWORD);
    expect(page.$('#delete-about-title')!.textContent).toContain('احذف حسابك');
    expect(page.$('[data-lead]')!.textContent).toContain('ده بيحذف حسابك على ReadIn نهائيًا. مينفعش ترجع فيه، ومش هنقدر نرجّعه.');
    expect(page.root().querySelectorAll('[data-deleted] li')).toHaveLength(7);
    expect(page.$('[data-deleted]')!.textContent).toContain('ربط حسابك بجوجل وأبل، وبنلغي صلاحية ReadIn عند أبل كمان.');
    // Drafts and unpublished articles go; published ones stay up as "Deleted user" (SPEC §9.6).
    expect(page.$('[data-deleted]')!.textContent).toContain('المسودات وأي مقال مش منشور، بالصور وملفات الـ PDF اللي فيها، وأي صورة أو ملف تاني رفعته');
    expect(page.$('[data-deleted]')!.textContent).not.toContain('مقالاتك والمسودات');
    // The title and the reposts (F14, F29) are deleted too (SPEC §9.6).
    expect(page.$('[data-deleted]')!.textContent).toContain('بروفايلك: الاسم واسم المستخدم والصورة والمسمى والنبذة والروابط');
    expect(page.$('[data-deleted]')!.textContent).toContain('وتفاعلاتك وإعادات نشرك وإعجاباتك بالتعليقات');
    const kept = page.root().querySelectorAll('[data-kept] li');
    expect(kept).toHaveLength(4);
    expect(kept[0].textContent!.trim()).toBe(
      'مقالاتك المنشورة وتعليقاتك بتفضل موجودة باسم «مستخدم محذوف»، بالصور وملفات الـ PDF اللي فيها: من غير اسمك أو اسم المستخدم أو صورتك، ومن غير أي حاجة تربطها بيك. ده عشان الروابط والنقاشات اللي غيرك معتمد عليها تفضل شغالة. لو عايز تشيل مقال، احذفه قبل ما تحذف حسابك.',
    );
    expect(page.$('[data-kept]')!.textContent).toContain('لحد 14 يوم');
    expect(page.$('[data-after]')!.textContent).toContain('وهيبدأ فاضي');
    expect(page.$<HTMLAnchorElement>('[data-delete-by-email]')!.href).toBe('https://readin-cca78.firebaseapp.com/delete-account');
    expect(page.$('#delete-account-password')).toBeNull();
    expect(page.$('[data-delete-submit]')).toBeNull();

    await toConfirm(page);
    expect(page.$('#delete-confirm-title')!.textContent).toContain('أكّد إنه انت');
    expect(page.$('#delete-account-password')).not.toBeNull();
    noDeleteRequest(page);
  });

  it('reads the same in English', async () => {
    const page = await setup(WITH_PASSWORD, { lang: 'en' });
    expect(page.$('#delete-about-title')!.textContent).toContain('Delete your account');
    expect(page.$('[data-lead]')!.textContent).toContain("This permanently deletes your ReadIn account. You can't undo it, and we can't restore it.");
    expect(page.$('[data-deleted]')!.textContent).toContain('Your devices and notification tokens, so no notification reaches you');
    expect(page.$('[data-deleted]')!.textContent).toContain(
      "Your drafts and any article that isn't published, with their images and PDFs, and every other photo or file you uploaded",
    );
    expect(page.$('[data-deleted]')!.textContent).toContain('Your profile: name, @username, photo, title, bio and links');
    expect(page.$('[data-deleted]')!.textContent).toContain('reading progress and stats, reactions, reposts, comment likes');
    expect(page.root().querySelector('[data-kept] li')!.textContent!.trim()).toBe(
      'Your published articles and comments stay up under “Deleted user”, with the images and PDFs they show: no name, @username or photo, and nothing that links them to you. That keeps links and discussions other readers rely on working. To take an article down, delete it before you delete your account.',
    );
    expect(page.$('[data-kept]')!.textContent).toContain('Database backups may still hold your data for up to 14 days');
    await toConfirm(page);
    expect(page.$('[data-understood]')!.closest('label')!.textContent).toContain('I understand, delete my account');
    expect(page.$('[data-delete-submit]')!.textContent).toContain('Delete my account');
  });

  it('password: the checkbox enables the red button, the final dialog starts on Cancel, then deletes for good', async () => {
    const page = await setup(WITH_PASSWORD);
    localStorage.setItem('readin.phoneCountry', 'EG');
    await toConfirm(page);
    const button = () => page.$<HTMLButtonElement>('[data-delete-submit]')!;
    expect(button().disabled).toBe(true);
    expect(button().textContent).toContain('احذف حسابي');

    typePassword(page);
    expect(button().disabled).toBe(true); // still needs the checkbox
    tickUnderstood(page);
    expect(button().disabled).toBe(false);

    // The second, explicit confirmation: an alert dialog whose default focus is Cancel.
    await submit(page);
    const dialog = page.$('[data-delete-dialog]')!.closest('section')!;
    expect(dialog.getAttribute('role')).toBe('alertdialog');
    expect(dialog.getAttribute('aria-labelledby')).toBe('delete-forever-title');
    expect(page.$('#delete-forever-title')!.textContent).toContain('تحذف حسابك نهائيًا؟');
    expect(page.$('#delete-forever-body')!.textContent).toContain('مينفعش ترجع في الخطوة دي.');
    expect(page.$('[data-delete-forever]')!.textContent).toContain('احذف نهائيًا');
    expect(document.activeElement).toBe(page.$('[data-delete-cancel]'));
    page.$<HTMLButtonElement>('[data-delete-cancel]')!.click();
    await page.render();
    expect(page.$('[data-delete-dialog]')).toBeNull();
    noDeleteRequest(page);

    await deleteForever(page);
    const request = deleteRequest(page);
    expect(request.request.body).toEqual({ password: PASSWORD });
    expect(request.request.withCredentials).toBe(true);
    expect(tokenTag(request.request.headers.get('Authorization'))).toBe('t1');
    // Progress: the form is disabled, the button says so and screen readers hear it.
    expect(button().disabled).toBe(true);
    expect(button().getAttribute('aria-busy')).toBe('true');
    expect(button().textContent).toContain('بنحذف حسابك…');
    expect(page.$<HTMLFieldSetElement>('[data-delete-form] fieldset')!.disabled).toBe(true);
    expect(page.$('[data-delete-status]')!.textContent).toContain('بنحذف حسابك…');
    expect(page.session.isAuthenticated()).toBe(true); // nothing looks deleted before the API says so

    request.flush(null, { status: 204, statusText: 'No Content' });
    await expectDeleted(page);
    expect(page.push.forgetDevice).toHaveBeenCalledTimes(1); // the FCM token on this browser
    expect(localStorage.getItem('readin.phoneCountry')).toBeNull();
  });

  it('asks for the password before the dialog, and a wrong one stays on this step under the field', async () => {
    const page = await setup(WITH_PASSWORD);
    await toConfirm(page);
    tickUnderstood(page);
    await submit(page);
    expect(page.$('[data-delete-dialog]')).toBeNull();
    expect(page.$('#delete-account-password-error')!.textContent).toContain('الخانة دي مطلوبة.');

    typePassword(page, 'not-my-password');
    await deleteForever(page);
    await flushProblem(page, deleteRequest(page), 400, 'auth.wrong_password');
    expect(page.$('#delete-account-password-error')!.textContent).toContain('كلمة السر الحالية غلط.');
    expect(page.$('[data-retry]')).toBeNull();
    expect(page.$('[data-delete-confirm]')).not.toBeNull();
    expect(page.session.isAuthenticated()).toBe(true);
    expect(page.push.forgetDevice).not.toHaveBeenCalled();

    typePassword(page, PASSWORD); // typing again clears it
    expect(page.$('#delete-account-password-error')).toBeNull();
  });

  it('a Google-only account confirms with a fresh Google sign in', async () => {
    const page = await setup(GOOGLE_ONLY);
    await toConfirm(page);
    expect(page.$('#delete-account-password')).toBeNull();
    expect(page.$('[data-delete-external] [data-fake-gis]')).not.toBeNull();
    expect(page.$('[data-delete-external] [data-apple-button]')).toBeNull();

    tickUnderstood(page);
    await submit(page); // not confirmed yet: no dialog
    expect(page.$('[data-delete-dialog]')).toBeNull();
    expect(page.$('[data-confirm-first]')!.textContent).toContain('أكّد إنه انت الأول.');

    sdks.google.pick('google-token');
    await page.render();
    expect(page.$('[data-confirmed]')!.textContent).toContain('Google');
    await deleteForever(page);
    const request = deleteRequest(page);
    expect(request.request.body).toEqual({ external: { provider: 'google', idToken: 'google-token' } });
    request.flush(null, { status: 204, statusText: 'No Content' });
    await expectDeleted(page);
  });

  it('a refused Google sign in asks for it again (and is not taken for an ended session)', async () => {
    const page = await setup(GOOGLE_ONLY);
    await toConfirm(page);
    sdks.google.pick('expired-token');
    await page.render();
    tickUnderstood(page);
    await deleteForever(page);

    // auth.external_invalid is a 401: the interceptor renews the session once and the retry is refused the same way.
    const first = deleteRequest(page);
    const { body, ...options } = problem(401, 'auth.external_invalid');
    first.flush(body, options);
    await settle(10);
    page.http.expectOne(`${TEST_API}/auth/refresh`).flush(testSession('t2', GOOGLE_ONLY));
    await settle(10);
    await flushProblem(page, deleteRequest(page), 401, 'auth.external_invalid');

    expect(page.$('[data-delete-error]')!.textContent).toContain('مقدرناش نتأكد من الدخول بجوجل أو أبل');
    expect(page.$('[data-confirmed]')).toBeNull(); // pick the account again
    expect(page.$('[data-delete-external] [data-fake-gis]')).not.toBeNull();
    expect(page.session.isAuthenticated()).toBe(true);
    expect(TestBed.inject(Router).url).toBe('/settings/delete-account');
  });

  it('Confirm with Apple sends the raw nonce and Apple’s authorization code', async () => {
    const page = await setup(PASSWORD_AND_APPLE, { apple: true });
    await toConfirm(page);
    const apple = page.$<HTMLButtonElement>('[data-delete-external] [data-apple-button]')!;
    expect(apple.textContent).toContain('أكّد بأبل');
    expect(page.$('#delete-account-password')).not.toBeNull(); // the password stays possible too

    apple.click();
    const confirmed = await page.until(() => page.$('[data-confirmed]'));
    expect(confirmed.textContent).toContain('Apple');
    noDeleteRequest(page); // a held confirmation still needs the checkbox and the final dialog
    tickUnderstood(page);
    await deleteForever(page);
    const request = deleteRequest(page);
    expect(request.request.body).toEqual({
      external: { provider: 'apple', idToken: 'apple-id-token', nonce: expect.any(String), authorizationCode: 'apple-auth-code' },
    });
    request.flush(null, { status: 204, statusText: 'No Content' });
    await expectDeleted(page);
  });

  it('auth.apple_confirmation_required runs Apple sign in and goes on with the deletion', async () => {
    const page = await setup(PASSWORD_AND_APPLE, { apple: true });
    await toConfirm(page);
    typePassword(page);
    tickUnderstood(page);
    await deleteForever(page);
    const first = deleteRequest(page);
    expect(first.request.body).toEqual({ password: PASSWORD });
    await flushProblem(page, first, 400, 'auth.apple_confirmation_required');

    const second = await laterDeleteRequest(page);
    expect(sdks.apple.signIn).toHaveBeenCalledTimes(1);
    expect(second.request.body).toEqual({
      external: { provider: 'apple', idToken: 'apple-id-token', nonce: expect.any(String), authorizationCode: 'apple-auth-code' },
    });
    second.flush(null, { status: 204, statusText: 'No Content' });
    await expectDeleted(page);
  });

  it('auth.apple_confirmation_required keeps "Confirm with Apple" when the popup was closed', async () => {
    const page = await setup(PASSWORD_AND_APPLE, { apple: true });
    sdks.apple.next = 'cancel';
    await toConfirm(page);
    typePassword(page);
    tickUnderstood(page);
    await deleteForever(page);
    await flushProblem(page, deleteRequest(page), 400, 'auth.apple_confirmation_required');
    await page.until(() => sdks.apple.signIn.mock.settledResults[0]?.type === 'rejected'); // the popup was closed
    await page.render();
    noDeleteRequest(page);
    expect(page.$('[data-delete-error]')!.textContent).toContain('حسابك مربوط بأبل. أكّد بأبل عشان تحذفه.');

    sdks.apple.next = { authorization: { id_token: 'apple-id-token', code: 'apple-auth-code' } };
    page.$<HTMLButtonElement>('[data-delete-external] [data-apple-button]')!.click();
    const request = await laterDeleteRequest(page); // already confirmed in the dialog: it goes on at once
    expect(request.request.body.external).toMatchObject({ provider: 'apple', authorizationCode: 'apple-auth-code' });
  });

  it('auth.apple_confirmation_required without Apple on the web points to the iPhone app and email', async () => {
    const page = await setup(PASSWORD_AND_APPLE);
    await toConfirm(page);
    expect(page.$('[data-apple-button]')).toBeNull(); // no Services ID on the web yet
    typePassword(page);
    tickUnderstood(page);
    await deleteForever(page);
    await flushProblem(page, deleteRequest(page), 400, 'auth.apple_confirmation_required');

    const notice = page.$('[data-apple-unavailable]')!;
    expect(notice.getAttribute('role')).toBe('alert');
    expect(notice.textContent).toContain('حسابك مربوط بأبل. أكّد بأبل من تطبيق ReadIn على الآيفون، أو ابعتلنا إيميل نحذفه.');
    expect(notice.querySelector<HTMLAnchorElement>('a')!.href).toContain('mailto:youssef.fcaih@gmail.com');
    expect(page.$('[data-retry]')).toBeNull();
    expect(sdks.apple.signIn).not.toHaveBeenCalled();
    noDeleteRequest(page);
    expect(page.session.isAuthenticated()).toBe(true);
  });

  it('an Apple-only account on the web is told where it can delete', async () => {
    const page = await setup(APPLE_ONLY);
    await toConfirm(page);
    expect(page.$('[data-no-confirm-here]')!.textContent).toContain('أكّد بأبل من تطبيق ReadIn على الآيفون');
    tickUnderstood(page);
    await submit(page);
    expect(page.$('[data-delete-dialog]')).toBeNull();
    noDeleteRequest(page);
  });

  it('503: nothing was deleted, so it says so and Retry sends it again', async () => {
    const page = await setup(WITH_PASSWORD);
    await toConfirm(page);
    typePassword(page);
    tickUnderstood(page);
    await deleteForever(page);
    await flushProblem(page, deleteRequest(page), 503, 'account.deletion_unavailable');

    const error = page.$('[data-delete-error]')!;
    expect(error.getAttribute('role')).toBe('alert');
    expect(error.textContent).toContain('معرفناش نكمّل حذف حسابك، فمفيش حاجة اتحذفت.');
    expect(page.session.isAuthenticated()).toBe(true);
    expect(page.push.forgetDevice).not.toHaveBeenCalled();
    expect(page.$('[data-delete-status]')!.textContent!.trim()).toBe('');

    page.$<HTMLButtonElement>('[data-retry]')!.click();
    await page.render();
    const retry = deleteRequest(page);
    expect(retry.request.body).toEqual({ password: PASSWORD });
    retry.flush(null, { status: 204, statusText: 'No Content' });
    await expectDeleted(page);
  });

  it('offline: says so, sends nothing and never queues it; Retry sends it once back online', async () => {
    const page = await setup(WITH_PASSWORD);
    let online = false;
    Object.defineProperty(navigator, 'onLine', { configurable: true, get: () => online });
    try {
      await toConfirm(page);
      typePassword(page);
      tickUnderstood(page);
      await deleteForever(page);
      noDeleteRequest(page);
      expect(page.$('[data-delete-error]')!.textContent).toContain('انت مش متصل بالإنترنت. اتصل الأول عشان تحذف حسابك.');
      expect(page.$('[data-retry]')).not.toBeNull();
      expect(page.session.isAuthenticated()).toBe(true);

      online = true;
      window.dispatchEvent(new Event('online'));
      await page.render();
      noDeleteRequest(page); // coming back online sends nothing by itself

      page.$<HTMLButtonElement>('[data-retry]')!.click();
      await page.render();
      // The connection drops during the request: the same message, still nothing deleted.
      const request = deleteRequest(page);
      expect(request.request.body).toEqual({ password: PASSWORD });
      request.error(new ProgressEvent('error'));
      await page.render();
      expect(page.$('[data-delete-error]')!.textContent).toContain('انت مش متصل بالإنترنت');
      expect(page.$('[data-retry]')).not.toBeNull();
      expect(page.session.isAuthenticated()).toBe(true);
      noDeleteRequest(page);
    } finally {
      delete (navigator as { onLine?: boolean }).onLine; // back to jsdom's own getter
    }
  });

  it('429: shows the message and lets them try again later', async () => {
    const page = await setup(WITH_PASSWORD);
    await toConfirm(page);
    typePassword(page);
    tickUnderstood(page);
    await deleteForever(page);
    await flushProblem(page, deleteRequest(page), 429, 'rate_limited');
    expect(page.$('[data-delete-error]')!.textContent).toContain('طلبات كتير');
    expect(page.$('[data-retry]')).toBeNull();
    expect(page.$<HTMLButtonElement>('[data-delete-submit]')!.disabled).toBe(false);
  });

  it('401: the session already ended, so it goes to Sign in and back here afterwards', async () => {
    const page = await setup(WITH_PASSWORD);
    await toConfirm(page);
    typePassword(page);
    tickUnderstood(page);
    await deleteForever(page);
    const { body, ...options } = problem(401, 'auth.unauthorized');
    deleteRequest(page).flush(body, options);
    await settle(10);
    page.http.expectOne(`${TEST_API}/auth/refresh`).flush({ code: 'auth.refresh_invalid' }, { status: 401, statusText: 'Unauthorized' });
    await page.until(() => TestBed.inject(Router).url === '/auth/sign-in?returnUrl=%2Fsettings%2Fdelete-account');
    expect(page.session.isGuest()).toBe(true);
    expect(page.push.forgetDevice).not.toHaveBeenCalled();
    await page.render();
    expect(page.root().querySelector('#sign-in-phone')).not.toBeNull();
    expect(page.root().querySelector('[data-banner]')).toBeNull(); // not "deleted": it may not be
  });
});
