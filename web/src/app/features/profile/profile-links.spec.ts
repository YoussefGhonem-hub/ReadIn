import { linkLabel, profileLinks, profileLinksOf } from './profile-links';

describe('profile links (F14)', () => {
  it('shows a short address', () => {
    expect(linkLabel('https://www.github.com/mona/')).toBe('github.com/mona');
    expect(linkLabel('https://mona.dev')).toBe('mona.dev');
    expect(linkLabel('not a url')).toBe('not a url');
  });

  it('keeps the member’s order and only http(s) links of a known platform', () => {
    const links = profileLinks([
      { platform: 'x', url: 'https://x.com/mona', label: null },
      { platform: 'github', url: 'https://github.com/mona', label: null },
      { platform: 'other', url: 'https://mona.dev/talks', label: ' Talks ' },
      { platform: 'linkedin', url: 'javascript:alert(1)', label: null },
      // An unknown platform from a newer API is skipped.
      { platform: 'mastodon' as never, url: 'https://mastodon.social/@mona', label: null },
    ]);
    expect(links.map((l) => [l.platform, l.label, l.display])).toEqual([
      ['x', null, 'x.com/mona'],
      ['github', null, 'github.com/mona'],
      ['other', 'Talks', 'mona.dev/talks'],
    ]);
    expect(profileLinks(null)).toEqual([]);
    expect(profileLinks([])).toEqual([]);
  });

  it('reads the object an API older than the profile step sent, in the migration’s order', () => {
    expect(profileLinksOf({ website: 'https://mona.dev', github: 'https://github.com/mona', linkedin: null })).toEqual([
      { platform: 'github', url: 'https://github.com/mona', label: null },
      { platform: 'website', url: 'https://mona.dev', label: null },
    ]);
    expect(profileLinksOf(undefined)).toEqual([]);
  });
});
