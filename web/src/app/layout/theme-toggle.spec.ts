import { TestBed } from '@angular/core/testing';
import { setupSocialTesting, TEST_API, problem } from '../../testing/social-testing';
import { ThemeService } from '../core/theme/theme.service';
import { ThemeToggle } from './theme-toggle';

function clearCookie(): void {
  document.cookie = 'theme=; Path=/; Max-Age=0';
}

function stubMatchMedia(prefersDark: boolean): void {
  Object.defineProperty(window, 'matchMedia', {
    configurable: true,
    writable: true,
    value: (query: string) => ({
      matches: query.includes('dark') ? prefersDark : false,
      media: query,
      addEventListener: () => undefined,
      removeEventListener: () => undefined,
    }),
  });
}

describe('ThemeToggle', () => {
  beforeEach(() => {
    clearCookie();
    document.documentElement.removeAttribute('data-theme');
    stubMatchMedia(false);
    TestBed.resetTestingModule();
  });

  afterEach(() => clearCookie());

  function render(options: { guest?: boolean; theme?: 'light' | 'dark' | 'system'; variant?: 'icon' | 'stacked' } = {}) {
    if (options.theme) document.cookie = `theme=${options.theme}; Path=/`;
    const testing = setupSocialTesting({ guest: options.guest });
    const fixture = TestBed.createComponent(ThemeToggle);
    if (options.variant) fixture.componentRef.setInput('variant', options.variant);
    fixture.detectChanges();
    const button = (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>('[data-theme-toggle]')!;
    return { ...testing, fixture, button, theme: TestBed.inject(ThemeService) };
  }

  it('light: offers dark, and one click switches to dark and saves it to the profile', async () => {
    const { fixture, button, theme, http } = render({ theme: 'light' });
    expect(button.getAttribute('aria-pressed')).toBe('false');
    expect(button.getAttribute('aria-label')).toBe('التبديل إلى الوضع الداكن');

    button.click();
    expect(theme.preference()).toBe('dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
    expect(document.cookie).toContain('theme=dark');
    const req = http.expectOne({ method: 'PUT', url: `${TEST_API}/me/preferences` });
    expect(req.request.body.theme).toBe('dark');
    req.flush(null);

    fixture.detectChanges();
    expect(button.getAttribute('aria-pressed')).toBe('true');
    expect(button.getAttribute('aria-label')).toBe('التبديل إلى الوضع الفاتح');
  });

  it('dark: one click switches to light', () => {
    const { button, theme, http } = render({ theme: 'dark' });
    expect(button.getAttribute('aria-pressed')).toBe('true');
    button.click();
    expect(theme.preference()).toBe('light');
    http.expectOne({ method: 'PUT', url: `${TEST_API}/me/preferences` }).flush(null);
  });

  it('system resolves first: a dark system switches to light, a light one to dark', () => {
    stubMatchMedia(true);
    let rendered = render({ theme: 'system' });
    expect(rendered.button.getAttribute('aria-pressed')).toBe('true');
    rendered.button.click();
    expect(rendered.theme.preference()).toBe('light');
    rendered.http.expectOne({ method: 'PUT', url: `${TEST_API}/me/preferences` }).flush(null);

    clearCookie();
    TestBed.resetTestingModule();
    stubMatchMedia(false);
    rendered = render({ theme: 'system' });
    expect(rendered.button.getAttribute('aria-pressed')).toBe('false');
    rendered.button.click();
    expect(rendered.theme.preference()).toBe('dark');
    rendered.http.expectOne({ method: 'PUT', url: `${TEST_API}/me/preferences` }).flush(null);
  });

  it('guests: the cookie only, no request', () => {
    const { button, theme, http } = render({ guest: true, theme: 'light' });
    button.click();
    expect(theme.preference()).toBe('dark');
    expect(document.cookie).toContain('theme=dark');
    http.expectNone(`${TEST_API}/me/preferences`);
  });

  it('a failed save keeps the new theme and shows the error', async () => {
    const { button, theme, http, toasts } = render({ theme: 'light' });
    const error = vi.spyOn(toasts, 'error');
    button.click();
    http.expectOne({ method: 'PUT', url: `${TEST_API}/me/preferences` }).flush(problem(500, 'server.error'), { status: 500, statusText: 'Server Error' });
    await vi.waitFor(() => expect(error).toHaveBeenCalledTimes(1));
    expect(theme.preference()).toBe('dark');
  });

  it('stacked: the label "Theme" under the icon, and a name that starts with it', () => {
    const { button } = render({ theme: 'light', variant: 'stacked' });
    expect(button.textContent!.trim()).toBe('المظهر');
    expect(button.getAttribute('aria-label')).toBe('المظهر: التبديل إلى الوضع الداكن');
    expect(button.getAttribute('aria-pressed')).toBe('false');
  });
});
