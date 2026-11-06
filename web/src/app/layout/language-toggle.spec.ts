import { TestBed } from '@angular/core/testing';
import { setupSocialTesting, TEST_API, problem } from '../../testing/social-testing';
import { LanguageService } from '../core/i18n/language.service';
import { LanguageToggle } from './language-toggle';

function clearCookie(): void {
  document.cookie = 'lang=; Path=/; Max-Age=0';
}

describe('LanguageToggle', () => {
  beforeEach(() => {
    clearCookie();
    TestBed.resetTestingModule();
  });

  afterEach(() => {
    clearCookie();
    document.documentElement.setAttribute('lang', 'ar');
    document.documentElement.setAttribute('dir', 'rtl');
  });

  async function render(options: { guest?: boolean; lang?: 'ar' | 'en'; variant?: 'icon' | 'stacked' } = {}) {
    const testing = setupSocialTesting({ guest: options.guest });
    const language = TestBed.inject(LanguageService);
    if (options.lang === 'en') {
      await language.setLanguage('en');
      clearCookie();
    }
    const fixture = TestBed.createComponent(LanguageToggle);
    if (options.variant) fixture.componentRef.setInput('variant', options.variant);
    fixture.detectChanges();
    const button = (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>('[data-language-toggle]')!;
    return { ...testing, fixture, button, language };
  }

  it('Arabic: offers English, and one click switches the interface and saves it to the profile', async () => {
    const { fixture, button, language, http } = await render();
    expect(button.textContent!.trim()).toBe('EN');
    expect(button.getAttribute('aria-label')).toBe('تغيير لغة التطبيق إلى English');

    button.click();
    const req = await vi.waitFor(() => http.expectOne({ method: 'PUT', url: `${TEST_API}/me/preferences` }));
    expect(req.request.body.uiLanguage).toBe('en');
    req.flush(null);

    expect(language.lang()).toBe('en');
    expect(document.documentElement.getAttribute('dir')).toBe('ltr');
    expect(document.documentElement.getAttribute('lang')).toBe('en');
    expect(document.cookie).toContain('lang=en');
    fixture.detectChanges();
    expect(button.textContent!.trim()).toBe('ع');
    expect(button.getAttribute('aria-label')).toBe('Switch the app language to العربية');
  });

  it('English: one click switches back to Arabic, right to left', async () => {
    const { button, language, http } = await render({ lang: 'en' });
    button.click();
    const req = await vi.waitFor(() => http.expectOne({ method: 'PUT', url: `${TEST_API}/me/preferences` }));
    expect(req.request.body.uiLanguage).toBe('ar');
    req.flush(null);
    expect(language.lang()).toBe('ar');
    expect(document.documentElement.getAttribute('dir')).toBe('rtl');
  });

  it('guests: the cookie only, no request', async () => {
    const { button, language, http } = await render({ guest: true });
    button.click();
    await vi.waitFor(() => expect(language.lang()).toBe('en'));
    expect(document.cookie).toContain('lang=en');
    http.expectNone(`${TEST_API}/me/preferences`);
  });

  it('a failed save keeps the new language and shows the error', async () => {
    const { button, language, http, toasts } = await render();
    const error = vi.spyOn(toasts, 'error');
    button.click();
    const req = await vi.waitFor(() => http.expectOne({ method: 'PUT', url: `${TEST_API}/me/preferences` }));
    req.flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    await vi.waitFor(() => expect(error).toHaveBeenCalledTimes(1));
    expect(language.lang()).toBe('en');
  });

  it('stacked: the icon above the other language written in its own script', async () => {
    const { button } = await render({ variant: 'stacked' });
    expect(button.querySelector('svg')).not.toBeNull();
    const name = button.querySelector<HTMLElement>('span[lang]')!;
    expect(name.textContent!.trim()).toBe('English');
    expect(name.getAttribute('lang')).toBe('en');
  });
});
