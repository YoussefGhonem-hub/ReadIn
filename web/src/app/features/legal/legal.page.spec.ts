import { Component, PLATFORM_ID, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Meta, Title } from '@angular/platform-browser';
import { Route, Router, Routes, provideRouter, withComponentInputBinding } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';
import { setupSocialTesting } from '../../../testing/social-testing';
import { translocoTesting } from '../../../testing/transloco-testing';
import { LanguageService } from '../../core/i18n/language.service';
import { RenderMode } from '@angular/ssr';
import { routes } from '../../app.routes';
import { serverRoutes } from '../../app.routes.server';
import { environment } from '../../../environments/environment';
import { TermsCheckbox } from '../../shared/legal/terms-checkbox';
import { LEGAL_TEXTS, SUPPORT_EMAIL_PLACEHOLDER } from './legal-content';
import { LegalPage } from './legal.page';

describe('Terms of Use and Community Guidelines (F37)', () => {
  beforeEach(() => {
    TestBed.resetTestingModule();
    setupSocialTesting({ guest: true });
  });

  function render(page: 'terms' | 'guidelines') {
    const fixture = TestBed.createComponent(LegalPage);
    fixture.componentRef.setInput('page', page);
    fixture.detectChanges();
    TestBed.tick();
    const root = fixture.nativeElement as HTMLElement;
    return { fixture, root, $: (s: string) => root.querySelector<HTMLElement>(s) };
  }

  it('are public routes, rendered on the server like the rest of the site', () => {
    const all = (list: Routes): Route[] => list.flatMap((r) => [r, ...all(r.children ?? [])]);
    const terms = all(routes).find((r) => r.path === 'terms')!;
    const guidelines = all(routes).find((r) => r.path === 'community-guidelines')!;
    expect(terms.data).toEqual({ page: 'terms' });
    expect(guidelines.data).toEqual({ page: 'guidelines' });
    expect(terms.canActivate ?? []).toEqual([]);
    expect(guidelines.canActivate ?? []).toEqual([]);
    // No browser-only entry: they fall to the server-rendered catch-all.
    expect(serverRoutes.filter((r) => r.path === 'terms' || r.path === 'community-guidelines')).toEqual([]);
    expect(serverRoutes.at(-1)).toEqual({ path: '**', renderMode: RenderMode.Server });
  });

  it('show the text in the UI language, with the zero-tolerance line, the 24-hour review and the support email', () => {
    const t = render('terms');
    expect(t.$('[data-legal-title]')!.textContent!.trim()).toBe('شروط الاستخدام');
    expect(t.$('article')!.getAttribute('lang')).toBe('ar');
    expect(t.$('article')!.getAttribute('dir')).toBe('rtl');
    expect(t.root.textContent).toContain('لا تسامح مطلقًا مع المحتوى المسيء أو المستخدمين المسيئين');
    expect(t.root.textContent).toContain('خلال 24 ساعة');
    expect(t.root.textContent).not.toContain(SUPPORT_EMAIL_PLACEHOLDER);
    expect(TestBed.inject(Title).getTitle()).toBe('شروط الاستخدام — ReadIn');
    expect(TestBed.inject(Meta).getTag('name="description"')!.content).toBe(LEGAL_TEXTS.terms.ar.intro.slice(0, 160));
  });

  it('link to the other page, the privacy policy and help', () => {
    let links = [...render('terms').root.querySelectorAll<HTMLAnchorElement>('[data-legal-links] a')];
    expect(links.map((a) => a.getAttribute('href'))).toEqual(['/community-guidelines', `${new URL(environment.accountDeletionUrl).origin}/privacy`, '/support']);
    links = [...render('guidelines').root.querySelectorAll<HTMLAnchorElement>('[data-legal-links] a')];
    expect(links[0].getAttribute('href')).toBe('/terms');
  });

  it('every text exists in both languages, with the same number of sections', () => {
    for (const page of ['terms', 'guidelines'] as const) {
      expect(LEGAL_TEXTS[page].ar.sections.length).toBe(LEGAL_TEXTS[page].en.sections.length);
      expect(LEGAL_TEXTS[page].ar.sections.length).toBeGreaterThan(3);
    }
  });
});

@Component({
  imports: [TermsCheckbox],
  template: `<rd-terms-checkbox [(checked)]="accepted" />`,
})
class CheckboxHost {
  readonly accepted = signal(false);
}

describe('The terms checkbox (SPEC §9.2, F37)', () => {
  beforeEach(() => {
    TestBed.resetTestingModule();
    setupSocialTesting({ guest: true });
  });

  it('reads as one sentence with both links (new tab), and binds two ways', () => {
    const fixture = TestBed.createComponent(CheckboxHost);
    fixture.detectChanges();
    const root = fixture.nativeElement as HTMLElement;
    expect(root.textContent!.replace(/\s+/g, ' ').trim()).toBe(
      'أوافق على شروط الاستخدام وقواعد المجتمع، ولا تسامح مطلقًا مع المحتوى المسيء أو المستخدمين المسيئين.',
    );
    const links = [...root.querySelectorAll<HTMLAnchorElement>('a')];
    expect(links.map((a) => [a.getAttribute('href'), a.getAttribute('target')])).toEqual([
      ['/terms', '_blank'],
      ['/community-guidelines', '_blank'],
    ]);
    const box = root.querySelector<HTMLInputElement>('[data-accept-terms]')!;
    expect(box.checked).toBe(false);
    box.click();
    fixture.detectChanges();
    expect(fixture.componentInstance.accepted()).toBe(true);
    fixture.componentInstance.accepted.set(false);
    fixture.detectChanges();
    expect(box.checked).toBe(false);
  });
});

@Component({ template: '' })
class Blank {}

describe('The legal pages in the language the apps ask for (?lang=, F37)', () => {
  const ROUTES: Routes = [
    { path: 'terms', component: LegalPage, data: { page: 'terms' } },
    { path: 'community-guidelines', component: LegalPage, data: { page: 'guidelines' } },
    { path: '**', component: Blank },
  ];

  beforeEach(() => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      imports: [translocoTesting()],
      providers: [provideRouter(ROUTES, withComponentInputBinding()), { provide: PLATFORM_ID, useValue: 'browser' }],
    });
  });
  afterEach(() => {
    document.cookie = 'lang=; Path=/; Max-Age=0';
    history.replaceState(null, '', '/');
    document.documentElement.removeAttribute('lang');
    document.documentElement.removeAttribute('dir');
  });

  const settle = async (harness: RouterTestingHarness) => {
    for (let i = 0; i < 2; i++) {
      await new Promise((resolve) => setTimeout(resolve));
      harness.detectChanges();
    }
  };
  const alternates = () =>
    [...document.head.querySelectorAll('[data-rd-lang-alternates]')].map((l) => [l.getAttribute('rel'), l.getAttribute('hreflang'), l.getAttribute('href')]);

  it('render in that language with canonical and hreflang links; the language button switches by URL, never saving it', async () => {
    document.cookie = 'lang=ar; Path=/';
    await TestBed.inject(LanguageService).init();
    const harness = await RouterTestingHarness.create();
    await harness.navigateByUrl('/community-guidelines?lang=en');
    await settle(harness);
    const root = harness.routeNativeElement!;
    expect(root.querySelector('[data-legal-title]')!.textContent!.trim()).toBe('Community Guidelines');
    expect(root.querySelector('article')!.getAttribute('lang')).toBe('en');
    expect(document.documentElement.getAttribute('lang')).toBe('en');
    expect(document.documentElement.getAttribute('dir')).toBe('ltr');
    expect(TestBed.inject(Title).getTitle()).toBe('Community Guidelines — ReadIn');
    const site = environment.siteUrl;
    expect(alternates()).toEqual([
      ['canonical', null, `${site}/community-guidelines?lang=en`],
      ['alternate', 'ar', `${site}/community-guidelines?lang=ar`],
      ['alternate', 'en', `${site}/community-guidelines?lang=en`],
      ['alternate', 'x-default', `${site}/community-guidelines`],
    ]);
    // The other page and help keep the language.
    const links = [...root.querySelectorAll<HTMLAnchorElement>('[data-legal-links] a')].map((a) => a.getAttribute('href'));
    expect(links[0]).toBe('/terms?lang=en');
    expect(links[2]).toBe('/support?lang=en');

    const toggle = root.querySelector<HTMLAnchorElement>('[data-legal-language]')!;
    expect(toggle.textContent!.trim()).toBe('العربية');
    expect(toggle.getAttribute('href')).toBe('/community-guidelines?lang=ar');
    expect(toggle.getAttribute('hreflang')).toBe('ar');
    toggle.click();
    await settle(harness);
    expect(TestBed.inject(Router).url).toBe('/community-guidelines?lang=ar');
    expect(harness.routeNativeElement!.querySelector('[data-legal-title]')!.textContent!.trim()).toBe('قواعد المجتمع');
    expect(document.documentElement.getAttribute('dir')).toBe('rtl');
    expect(alternates()[0]).toEqual(['canonical', null, `${site}/community-guidelines?lang=ar`]);
    expect(document.cookie).toContain('lang=ar');

    // Another ?lang= page, then a page without it: the links go and the saved language is back.
    await harness.navigateByUrl('/terms?lang=en');
    await settle(harness);
    expect(TestBed.inject(LanguageService).lang()).toBe('en');
    expect(document.cookie).not.toContain('lang=en');
    await harness.navigateByUrl('/explore');
    await settle(harness);
    expect(alternates()).toEqual([]);
    expect(TestBed.inject(LanguageService).lang()).toBe('ar');
  });

  it('without ?lang= the page shows the saved language, and its canonical names it', async () => {
    document.cookie = 'lang=en; Path=/';
    await TestBed.inject(LanguageService).init();
    const harness = await RouterTestingHarness.create();
    await harness.navigateByUrl('/terms');
    await settle(harness);
    expect(harness.routeNativeElement!.querySelector('[data-legal-title]')!.textContent!.trim()).toBe('Terms of Use');
    expect(alternates()[0]).toEqual(['canonical', null, `${environment.siteUrl}/terms?lang=en`]);
  });
});
