import { PLATFORM_ID } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpTestingController } from '@angular/common/http/testing';
import { ActivatedRouteSnapshot, Router, RouterStateSnapshot, UrlTree, convertToParamMap, provideRouter } from '@angular/router';
import { testMe } from '../../../testing/auth-testing';
import { TEST_API, flushMicrotasks, problem, setupSocialTesting } from '../../../testing/social-testing';
import { LegalDto, MeDto } from '../../core/api/models';
import { SETUP_ORDER, nextSetupStep, postAuthUrl } from '../../core/auth/account-setup';
import { AuthService } from '../../core/auth/auth.service';
import { accountSetupGuard, setupStepGuard } from '../../core/auth/guards';
import { SessionStore } from '../../core/auth/session.store';
import { AcceptTermsPage } from './accept-terms.page';

const LEGAL: LegalDto = {
  termsVersion: '2026-11-08',
  effectiveAt: '2026-11-08T00:00:00Z',
  summary: { ar: 'أضفنا الحظر وفلتر المحتوى.', en: 'We added blocking and a content filter.' },
  pages: { terms: '/terms', communityGuidelines: '/community-guidelines', privacy: '/privacy' },
};

describe('New terms as a setup step (F37)', () => {
  beforeEach(() => TestBed.resetTestingModule());

  function setup(me: MeDto) {
    TestBed.configureTestingModule({
      providers: [provideRouter([]), { provide: PLATFORM_ID, useValue: 'browser' }, { provide: AuthService, useValue: { whenReady: async () => me } }],
    });
    TestBed.inject(SessionStore).setMe(me);
  }

  async function run(guard: (route: ActivatedRouteSnapshot, state: RouterStateSnapshot) => unknown, url: string): Promise<string | true> {
    const route = { queryParamMap: convertToParamMap({}) } as ActivatedRouteSnapshot;
    const result = await TestBed.runInInjectionContext(() => guard(route, { url } as RouterStateSnapshot));
    return result === true ? true : TestBed.inject(Router).serializeUrl(result as UrlTree);
  }

  it('comes after the password and the PIN, before the profile', () => {
    expect(SETUP_ORDER).toEqual(['password', 'pin', 'terms', 'profile', 'onboarding']);
    expect(nextSetupStep(testMe({ mustSetRecoveryPin: true, mustAcceptTerms: true }))).toBe('pin');
    expect(nextSetupStep(testMe({ mustAcceptTerms: true, isProfileComplete: false }))).toBe('terms');
    expect(nextSetupStep(testMe({ mustAcceptTerms: false }))).toBeNull();
    expect(postAuthUrl(testMe({ mustAcceptTerms: true }), '/write')).toBe('/auth/terms?returnUrl=%2Fwrite');
  });

  it('blocks the app until accepted, keeping the requested page', async () => {
    setup(testMe({ mustAcceptTerms: true }));
    expect(await run(accountSetupGuard, '/saved')).toBe('/auth/terms?returnUrl=%2Fsaved');
    expect(await run(accountSetupGuard, '/write')).toBe('/auth/terms?returnUrl=%2Fwrite');
    expect(await run(setupStepGuard('terms'), '/auth/terms')).toBe(true);
  });

  it.each(['/terms', '/community-guidelines', '/support', '/settings/delete-account', '/terms?lang=en', '/support#new'])(
    'still opens %s: the texts, help and deleting the account',
    async (url) => {
      setup(testMe({ mustAcceptTerms: true }));
      expect(await run(accountSetupGuard, url)).toBe(true);
    },
  );

  it('the open pages are only open on the terms step (the PIN comes first)', async () => {
    setup(testMe({ mustSetRecoveryPin: true, mustAcceptTerms: true }));
    expect(await run(accountSetupGuard, '/terms')).toBe('/auth/recovery-pin?returnUrl=%2Fterms');
  });
});

describe('AcceptTermsPage (F37)', () => {
  let http: HttpTestingController;
  const auth = { updateMe: vi.fn(), signOut: vi.fn(async () => undefined) };

  beforeEach(() => {
    TestBed.resetTestingModule();
    auth.updateMe.mockClear();
    auth.signOut.mockClear();
    ({ http } = setupSocialTesting({ providers: [{ provide: AuthService, useValue: auth }] }));
  });
  afterEach(() => http.verify());

  async function render(legal: LegalDto | 'error' = LEGAL, returnUrl: string | null = null) {
    const navigate = vi.spyOn(TestBed.inject(Router), 'navigateByUrl').mockResolvedValue(true);
    const fixture = TestBed.createComponent(AcceptTermsPage);
    if (returnUrl) fixture.componentRef.setInput('returnUrl', returnUrl);
    fixture.detectChanges();
    const get = http.expectOne(`${TEST_API}/legal`);
    if (legal === 'error') get.flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    else get.flush(legal);
    const root = fixture.nativeElement as HTMLElement;
    const stable = async () => {
      await flushMicrotasks();
      fixture.detectChanges();
    };
    await stable();
    return { root, stable, navigate, $: (s: string) => root.querySelector<HTMLElement>(s) };
  }

  it('says what changed in the UI language, when it took effect, and links both texts', async () => {
    const t = await render();
    expect(t.root.textContent).toContain('حدّثنا شروط الاستخدام');
    const summary = t.$('[data-terms-summary]')!;
    expect(summary.textContent).toContain('أضفنا الحظر وفلتر المحتوى.');
    expect(summary.textContent).toContain('سارية منذ');
    expect(t.$('[data-terms-link]')!.getAttribute('href')).toBe('/terms');
    expect(t.$('[data-guidelines-link]')!.getAttribute('href')).toBe('/community-guidelines');
    expect(t.$('[data-terms-link]')!.getAttribute('target')).toBe('_blank');
    expect(t.root.textContent).toContain('لا تسامح مطلقًا مع المحتوى المسيء أو المستخدمين المسيئين.');
    expect(t.$('[data-accept]')!.textContent!.trim()).toBe('موافق');
    expect(t.$('[data-terms-delete]')!.getAttribute('href')).toBe('/settings/delete-account');
  });

  it('without a summary (or when /legal fails) it shows a general line', async () => {
    let t = await render({ ...LEGAL, summary: { ar: null, en: 'Only English' }, effectiveAt: null });
    expect(t.$('[data-terms-summary]')!.textContent).toContain('غيّرنا شروط الاستخدام وقواعد المجتمع.');
    expect(t.$('[data-terms-summary]')!.textContent).not.toContain('سارية منذ');
    TestBed.resetTestingModule();
    ({ http } = setupSocialTesting({ providers: [{ provide: AuthService, useValue: auth }] }));
    t = await render('error');
    expect(t.$('[data-terms-summary]')!.textContent).toContain('غيّرنا شروط الاستخدام وقواعد المجتمع.');
  });

  it('«موافق» accepts, updates the account and goes on to the next step or the requested page', async () => {
    const t = await render(LEGAL, '/write');
    t.$('[data-accept]')!.click();
    await t.stable();
    expect((t.$('[data-accept]') as HTMLButtonElement).disabled).toBe(true);
    const post = http.expectOne(`${TEST_API}/me/terms/accept`);
    expect(post.request.method).toBe('POST');
    const me = testMe({ mustAcceptTerms: false, termsVersion: '2026-11-08' });
    post.flush(me);
    await t.stable();
    expect(auth.updateMe).toHaveBeenCalledWith(me);
    expect(t.navigate).toHaveBeenCalledWith('/write');

    // Still a step to go: the profile comes next.
    t.$('[data-accept]')!.click();
    http.expectOne(`${TEST_API}/me/terms/accept`).flush(testMe({ isProfileComplete: false }));
    await t.stable();
    expect(t.navigate).toHaveBeenLastCalledWith('/auth/complete-profile?returnUrl=%2Fwrite');
  });

  it('a failure stays on the page with the message', async () => {
    const t = await render();
    t.$('[data-accept]')!.click();
    http.expectOne(`${TEST_API}/me/terms/accept`).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    await t.stable();
    expect(t.$('[data-accept-error]')).not.toBeNull();
    expect(auth.updateMe).not.toHaveBeenCalled();
    expect(t.navigate).not.toHaveBeenCalled();
    expect((t.$('[data-accept]') as HTMLButtonElement).disabled).toBe(false);
  });

  it('Sign out signs out and goes home', async () => {
    const t = await render();
    t.$('[data-terms-sign-out]')!.click();
    await t.stable();
    expect(auth.signOut).toHaveBeenCalledTimes(1);
    expect(t.navigate).toHaveBeenCalledWith('/');
    http.expectNone(`${TEST_API}/me/terms/accept`);
  });
});
