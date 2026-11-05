import {
  LINK_PLATFORMS,
  checkLinks,
  hasLinkErrors,
  headlineProblem,
  isOneCleanLine,
  linkLabelProblem,
  linkUrlProblem,
  normalizeHeadline,
  normalizeLinkUrl,
  platformAllowsHost,
  toLinkInputs,
} from './link-rules';

const char = (code: number) => String.fromCodePoint(code);

/** The client copy of the API's link and title rules (contract: Profile → "Title and social links"). */
describe('link rules (F14)', () => {
  it('has the 14 platforms in the SPEC order', () => {
    expect(LINK_PLATFORMS).toEqual(['linkedin', 'x', 'instagram', 'facebook', 'youtube', 'tiktok', 'snapchat', 'threads', 'telegram', 'github', 'medium', 'behance', 'website', 'other']);
  });

  it('adds https:// to an address without a scheme, like the server', () => {
    expect(normalizeLinkUrl('  instagram.com/name ')).toBe('https://instagram.com/name');
    expect(normalizeLinkUrl('https://x.com/mona')).toBe('https://x.com/mona');
    expect(normalizeLinkUrl('http://mona.dev')).toBe('http://mona.dev');
    expect(normalizeLinkUrl('')).toBe('');
    expect(normalizeLinkUrl(null)).toBe('');
  });

  it('accepts a platform’s own hosts and their subdomains only; website and other take any host', () => {
    expect(platformAllowsHost('x', 'twitter.com')).toBe(true);
    expect(platformAllowsHost('x', 'mobile.twitter.com')).toBe(true);
    expect(platformAllowsHost('linkedin', 'eg.linkedin.com')).toBe(true);
    expect(platformAllowsHost('medium', 'mona.medium.com')).toBe(true);
    expect(platformAllowsHost('telegram', 't.me')).toBe(true);
    expect(platformAllowsHost('instagram', 'notinstagram.com')).toBe(false);
    expect(platformAllowsHost('instagram', 'instagram.com.evil.io')).toBe(false);
    expect(platformAllowsHost('website', 'anything.example')).toBe(true);
    expect(platformAllowsHost('other', 'anything.example')).toBe(true);
  });

  it('checks a URL in the API’s order: required, length, https, a real host, the platform’s site', () => {
    expect(linkUrlProblem('github', '')).toBe('validation.required');
    expect(linkUrlProblem('website', `https://mona.dev/${'a'.repeat(490)}`)).toBe('link.too_long');
    expect(linkUrlProblem('website', 'http://mona.dev')).toBe('link.https_required');
    expect(linkUrlProblem('website', 'ftp://mona.dev')).toBe('link.https_required');
    expect(linkUrlProblem('website', 'https://mona dev.com')).toBe('link.url_invalid');
    expect(linkUrlProblem('website', 'https://localhost')).toBe('link.url_invalid');
    expect(linkUrlProblem('website', 'https://192.168.1.10/x')).toBe('link.url_invalid');
    expect(linkUrlProblem('website', 'https://mona.dev:8443')).toBe('link.url_invalid');
    expect(linkUrlProblem('website', 'https://user:secret@mona.dev')).toBe('link.url_invalid');
    expect(linkUrlProblem('instagram', 'https://facebook.com/mona')).toBe('link.host_mismatch');
    expect(linkUrlProblem('instagram', 'https://www.instagram.com/mona')).toBeNull();
    expect(linkUrlProblem('website', 'https://mona.dev:443/')).toBeNull(); // the default port
    expect(linkUrlProblem('website', 'https://مثال.مصر/')).toBeNull(); // an Arabic domain
  });

  it('Other needs a name of 2–30 characters on one line; the named platforms take none', () => {
    expect(linkLabelProblem('other', '')).toBe('link.label_required');
    expect(linkLabelProblem('other', '   ')).toBe('link.label_required');
    expect(linkLabelProblem('other', 'A')).toBe('link.label_invalid');
    expect(linkLabelProblem('other', 'x'.repeat(31))).toBe('link.label_invalid');
    expect(linkLabelProblem('other', `My${char(0x202e)}cast`)).toBe('link.label_invalid');
    expect(linkLabelProblem('other', 'البودكاست')).toBeNull();
    expect(linkLabelProblem('github', 'Mine')).toBe('link.label_not_allowed');
    expect(linkLabelProblem('github', '')).toBeNull();
  });

  it('checks the whole list: at most 8, one per named platform, Other may repeat', () => {
    const ok = checkLinks([
      { platform: 'github', url: 'github.com/mona', label: '' },
      { platform: 'other', url: 'https://a.dev', label: 'Talks' },
      { platform: 'other', url: 'https://b.dev', label: 'Podcast' },
    ]);
    expect(hasLinkErrors(ok)).toBe(false);

    const bad = checkLinks([
      { platform: 'x', url: 'https://x.com/a', label: '' },
      { platform: 'x', url: 'https://instagram.com/a', label: '' },
      { platform: null, url: '', label: '' },
    ]);
    expect(bad.items).toEqual([
      { platform: null, url: null, label: null },
      { platform: 'link.duplicate_platform', url: 'link.host_mismatch', label: null },
      { platform: 'link.platform_invalid', url: 'validation.required', label: null },
    ]);
    const nine = Array.from({ length: 9 }, (_, i) => ({ platform: 'other' as const, url: `https://site${i}.dev`, label: `Site ${i}` }));
    expect(checkLinks(nine).list).toBe('link.too_many');
    expect(checkLinks(nine.slice(0, 8)).list).toBeNull();
    // A label left on a named platform isn't sent, so it isn't an error.
    expect(checkLinks([{ platform: 'github', url: 'https://github.com/a', label: 'old' }]).items[0].label).toBeNull();
  });

  it('sends normalized URLs, and a trimmed label for Other only', () => {
    expect(
      toLinkInputs([
        { platform: 'github', url: ' github.com/mona ', label: 'ignored' },
        { platform: 'other', url: 'mona.dev/talks', label: '  Talks ' },
      ]),
    ).toEqual([
      { platform: 'github', url: 'https://github.com/mona' },
      { platform: 'other', url: 'https://mona.dev/talks', label: 'Talks' },
    ]);
  });

  it('a title is optional, at most 120 characters after trimming, on one clean line', () => {
    expect(normalizeHeadline('  ')).toBeNull();
    expect(normalizeHeadline(' Senior Engineer ')).toBe('Senior Engineer');
    expect(headlineProblem(null)).toBeNull();
    expect(headlineProblem('')).toBeNull();
    expect(headlineProblem(`  ${'a'.repeat(120)}  `)).toBeNull();
    expect(headlineProblem('a'.repeat(121))).toBe('profile.headline_too_long');
    expect(headlineProblem('Senior\tEngineer')).toBe('profile.headline_invalid');
    expect(headlineProblem(`Senior${char(0x2028)}Engineer`)).toBe('profile.headline_invalid');
    expect(headlineProblem(`${char(0x2067)}مهندس${char(0x2069)}`)).toBe('profile.headline_invalid');
    expect(headlineProblem('مهندس .NET | Angular')).toBeNull();
    expect(isOneCleanLine(`a${char(0x200f)}b`)).toBe(false);
    expect(isOneCleanLine('Full Stack .NET 🚀')).toBe(true);
  });
});
