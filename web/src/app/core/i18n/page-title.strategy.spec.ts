import { Component, Injectable, inject, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Title } from '@angular/platform-browser';
import { TitleStrategy, provideRouter } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';
import { TranslocoService } from '@jsverse/transloco';
import { translocoTesting } from '../../../testing/transloco-testing';
import { LanguageService, UiLanguage } from './language.service';
import { PageTitleStrategy } from './page-title.strategy';

@Component({ selector: 'rd-test-page', template: '' })
class TestPage {}

/** A page that sets its own title, like the article reader or Settings. */
@Component({ selector: 'rd-own-title-page', template: '' })
class OwnTitlePage {
  constructor() {
    inject(Title).setTitle('Clean Architecture — ReadIn');
  }
}

/** The UI language without cookies or `<html>` attributes. */
@Injectable()
class LanguageStub {
  private readonly transloco = inject(TranslocoService);
  readonly lang = signal<UiLanguage>('ar');

  set(lang: UiLanguage): void {
    this.transloco.setActiveLang(lang);
    this.lang.set(lang);
  }
}

describe('PageTitleStrategy (route titles are i18n keys)', () => {
  beforeEach(() => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({
      imports: [translocoTesting()],
      providers: [
        provideRouter([
          { path: 'auth/sign-in', component: TestPage, title: 'pageTitles.signIn' },
          { path: 'onboarding', component: TestPage, title: 'pageTitles.onboarding' },
          { path: 'a', component: OwnTitlePage },
        ]),
        { provide: TitleStrategy, useExisting: PageTitleStrategy },
        LanguageStub,
        { provide: LanguageService, useExisting: LanguageStub },
      ],
    });
  });

  it('translates the route title in the UI language and follows a language change', async () => {
    const title = TestBed.inject(Title);
    const router = await RouterTestingHarness.create();
    await router.navigateByUrl('/auth/sign-in');
    expect(title.getTitle()).toBe('تسجيل الدخول — ReadIn');

    TestBed.inject(LanguageStub).set('en');
    TestBed.tick();
    expect(title.getTitle()).toBe('Sign in — ReadIn');

    await router.navigateByUrl('/onboarding');
    expect(title.getTitle()).toBe('Get started — ReadIn');
  });

  it('leaves pages without a route title alone, also when the language changes', async () => {
    const title = TestBed.inject(Title);
    const router = await RouterTestingHarness.create();
    await router.navigateByUrl('/auth/sign-in');
    await router.navigateByUrl('/a');
    expect(title.getTitle()).toBe('Clean Architecture — ReadIn');

    TestBed.inject(LanguageStub).set('en');
    TestBed.tick();
    expect(title.getTitle()).toBe('Clean Architecture — ReadIn');
  });
});
