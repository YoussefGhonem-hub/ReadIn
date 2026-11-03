import { TestBed } from '@angular/core/testing';
import { ThemeService } from './theme.service';

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

describe('ThemeService', () => {
  beforeEach(() => {
    clearCookie();
    document.documentElement.removeAttribute('data-theme');
    stubMatchMedia(false);
    TestBed.resetTestingModule();
  });

  afterEach(() => clearCookie());

  it('defaults to system and renders data-theme="system"', () => {
    const theme = TestBed.inject(ThemeService);
    expect(theme.preference()).toBe('system');
    expect(document.documentElement.getAttribute('data-theme')).toBe('system');
    expect(theme.resolved()).toBe('light');
  });

  it('restores the preference from the theme cookie (no flash on reload)', () => {
    document.cookie = 'theme=dark; Path=/';
    const theme = TestBed.inject(ThemeService);
    expect(theme.preference()).toBe('dark');
    expect(theme.resolved()).toBe('dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
  });

  it('ignores unknown cookie values', () => {
    document.cookie = 'theme=sepia; Path=/';
    expect(TestBed.inject(ThemeService).preference()).toBe('system');
  });

  it('resolves system preference from prefers-color-scheme', () => {
    stubMatchMedia(true);
    const theme = TestBed.inject(ThemeService);
    expect(theme.preference()).toBe('system');
    expect(theme.resolved()).toBe('dark');
  });

  it('setPreference updates the attribute and persists the cookie', () => {
    const theme = TestBed.inject(ThemeService);
    theme.setPreference('dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
    expect(document.cookie).toContain('theme=dark');

    theme.setPreference('light');
    expect(theme.resolved()).toBe('light');
    expect(document.documentElement.getAttribute('data-theme')).toBe('light');
    expect(document.cookie).toContain('theme=light');
  });
});
