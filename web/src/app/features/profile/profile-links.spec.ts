import { isValidLink, linkLabel, normalizeLink, profileLinks } from './profile-links';

describe('profile links (F14)', () => {
  it('normalizes what is typed: empty is no link, a bare address gets https://', () => {
    expect(normalizeLink('')).toBeNull();
    expect(normalizeLink('   ')).toBeNull();
    expect(normalizeLink(null)).toBeNull();
    expect(normalizeLink(' github.com/mona ')).toBe('https://github.com/mona');
    expect(normalizeLink('https://github.com/mona')).toBe('https://github.com/mona');
    expect(normalizeLink('http://mona.dev')).toBe('http://mona.dev');
  });

  it('accepts absolute https URLs up to 2048 characters, like the API', () => {
    expect(isValidLink(null)).toBe(true);
    expect(isValidLink('https://www.linkedin.com/in/mona')).toBe(true);
    expect(isValidLink('http://mona.dev')).toBe(false);
    expect(isValidLink('ftp://mona.dev')).toBe(false);
    expect(isValidLink('https://localhost')).toBe(false);
    expect(isValidLink('https://not a url')).toBe(false);
    expect(isValidLink(`https://mona.dev/${'a'.repeat(2048)}`)).toBe(false);
  });

  it('shows a short label and keeps only http(s) links, in a fixed order', () => {
    expect(linkLabel('https://www.github.com/mona/')).toBe('github.com/mona');
    expect(linkLabel('https://mona.dev')).toBe('mona.dev');
    expect(
      profileLinks({ website: 'https://mona.dev', github: 'https://github.com/mona', linkedin: 'javascript:alert(1)' }).map((l) => [l.kind, l.label]),
    ).toEqual([
      ['github', 'github.com/mona'],
      ['website', 'mona.dev'],
    ]);
    expect(profileLinks(null)).toEqual([]);
  });
});
