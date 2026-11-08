import { DOCUMENT, PLATFORM_ID, REQUEST } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { TranslocoService } from '@jsverse/transloco';
import { translocoTesting } from '../../../testing/transloco-testing';
import { LANG_PARAM_PATHS, LanguageService, requestedLanguage } from './language.service';

function clearCookie(): void {
  document.cookie = 'lang=; Path=/; Max-Age=0';
}

describe('UI language and ?lang= pages (F37)', () => {
  afterEach(() => {
    clearCookie();
    history.replaceState(null, '', '/');
    document.documentElement.removeAttribute('lang');
    document.documentElement.removeAttribute('dir');
  });

  it('?lang= is read on the terms, the guidelines and support only, and only as ar or en', () => {
    expect(LANG_PARAM_PATHS).toEqual(['/terms', '/community-guidelines', '/support']);
    expect(requestedLanguage('/terms?lang=en')).toBe('en');
    expect(requestedLanguage('/community-guidelines?lang=ar')).toBe('ar');
    expect(requestedLanguage('/support?x=1&lang=en#form')).toBe('en');
    expect(requestedLanguage('/terms/?lang=en')).toBe('en');
    expect(requestedLanguage('https://readin.online/terms?lang=en')).toBe('en');
    for (const url of ['/terms', '/terms?lang=fr', '/terms?lang=EN', '/terms?lang=', '/?lang=en', '/support/tickets?lang=en', '/ar/a/x?lang=en', null, '']) {
      expect(requestedLanguage(url)).toBeNull();
    }
  });

  describe('on the server', () => {
    function setup(url: string, cookie: string | null) {
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        imports: [translocoTesting()],
        providers: [
          provideRouter([]),
          { provide: PLATFORM_ID, useValue: 'server' },
          { provide: REQUEST, useValue: new Request(url, { headers: cookie ? { cookie } : {} }) },
        ],
      });
      return TestBed.inject(LanguageService);
    }

    it('renders a ?lang= page in that language: strings, <html lang> and dir', async () => {
      const language = setup('https://readin.online/terms?lang=en', 'lang=ar');
      await language.init();
      expect(language.lang()).toBe('en');
      expect(language.dir()).toBe('ltr');
      expect(TestBed.inject(TranslocoService).getActiveLang()).toBe('en');
      const html = TestBed.inject(DOCUMENT).documentElement;
      expect(html.getAttribute('lang')).toBe('en');
      expect(html.getAttribute('dir')).toBe('ltr');
    });

    it('an unknown value, or another page, keeps the usual rules (the cookie, else Arabic)', async () => {
      let language = setup('https://readin.online/terms?lang=fr', 'lang=en');
      await language.init();
      expect(language.lang()).toBe('en');
      language = setup('https://readin.online/settings?lang=en', null);
      await language.init();
      expect(language.lang()).toBe('ar');
      language = setup('https://readin.online/support?lang=ar', 'lang=en');
      await language.init();
      expect(language.lang()).toBe('ar');
      expect(TestBed.inject(DOCUMENT).documentElement.getAttribute('dir')).toBe('rtl');
    });
  });

  describe('in the browser', () => {
    function setup() {
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        imports: [translocoTesting()],
        providers: [{ provide: PLATFORM_ID, useValue: 'browser' }],
      });
      return { language: TestBed.inject(LanguageService) };
    }

    it('starts in the language the URL asks for (as the server did), without saving it', async () => {
      document.cookie = 'lang=ar; Path=/';
      history.replaceState(null, '', '/community-guidelines?lang=en');
      const { language } = setup();
      await language.init();
      expect(language.lang()).toBe('en');
      expect(document.documentElement.getAttribute('dir')).toBe('ltr');
      expect(document.cookie).toContain('lang=ar');
      expect(document.cookie).not.toContain('lang=en');
    });

    it('a page shows its ?lang= while open, and the saved language once closed (showOnly)', async () => {
      document.cookie = 'lang=ar; Path=/';
      history.replaceState(null, '', '/terms?lang=en');
      const { language } = setup();
      await language.init();
      expect(language.lang()).toBe('en');
      await language.showOnly(null);
      expect(language.lang()).toBe('ar');
      expect(document.documentElement.getAttribute('lang')).toBe('ar');
      await language.showOnly('en');
      expect(language.lang()).toBe('en');
      expect(document.cookie).toContain('lang=ar');
      expect(document.cookie).not.toContain('lang=en');
    });

    it('from one ?lang= page to another: the new page wins over the old one restoring the saved language', async () => {
      document.cookie = 'lang=ar; Path=/';
      history.replaceState(null, '', '/terms?lang=en');
      const { language } = setup();
      await language.init();
      // The old page closes (restore) and the new one opens (en) before the first load finishes.
      await Promise.all([language.showOnly(null), language.showOnly('en')]);
      expect(language.lang()).toBe('en');
      expect(TestBed.inject(TranslocoService).getActiveLang()).toBe('en');
      expect(document.documentElement.getAttribute('dir')).toBe('ltr');
    });

    it('picking a language on a ?lang= page saves it, so it stays after leaving', async () => {
      document.cookie = 'lang=ar; Path=/';
      history.replaceState(null, '', '/terms?lang=en');
      const { language } = setup();
      await language.init();
      await language.setLanguage('en');
      expect(document.cookie).toContain('lang=en');
      await language.showOnly(null);
      expect(language.lang()).toBe('en');
    });

    it('without a cookie and without ?lang=, Arabic, and nothing is saved', async () => {
      history.replaceState(null, '', '/terms');
      const { language } = setup();
      await language.init();
      expect(language.lang()).toBe('ar');
      expect(document.cookie).not.toContain('lang=');
    });
  });
});
