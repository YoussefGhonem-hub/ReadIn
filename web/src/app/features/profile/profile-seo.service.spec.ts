import { DOCUMENT } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Meta, Title } from '@angular/platform-browser';
import { testProfile } from '../../../testing/profile-testing';
import { translocoTesting } from '../../../testing/transloco-testing';
import { environment } from '../../../environments/environment';
import { ProfileSeoService } from './profile-seo.service';

describe('ProfileSeoService (SPEC §23)', () => {
  beforeEach(() => {
    TestBed.resetTestingModule();
    TestBed.configureTestingModule({ imports: [translocoTesting()] });
  });

  it('sets the title, Open Graph profile tags, canonical URL and ProfilePage JSON-LD, and clears them', () => {
    const seo = TestBed.inject(ProfileSeoService);
    const document = TestBed.inject(DOCUMENT);
    const meta = TestBed.inject(Meta);
    seo.apply(
      testProfile({
        bio: 'Writes about </script> and Angular.',
        avatarUrl: 'https://cdn.test/a_256.webp',
        avatarVariants: { '64': 'https://cdn.test/a_64.webp', '128': 'https://cdn.test/a_128.webp', '256': 'https://cdn.test/a_256.webp', '512': 'https://cdn.test/a_512.webp' },
      }),
    );

    expect(TestBed.inject(Title).getTitle()).toBe('Karim Hassan (@karim) — ReadIn');
    expect(meta.getTag('property="og:type"')!.content).toBe('profile');
    expect(meta.getTag('property="og:image"')!.content).toBe('https://cdn.test/a_512.webp');
    expect(meta.getTag('property="profile:username"')!.content).toBe('karim');
    // The title (F14), then the bio.
    expect(meta.getTag('name="description"')!.content).toBe('Frontend lead | Angular و performance · Writes about </script> and Angular.');
    expect(document.head.querySelector('link[rel="canonical"]')!.getAttribute('href')).toBe(`${environment.siteUrl}/@karim`);
    const script = document.head.querySelector('script[type="application/ld+json"]')!;
    expect(script.textContent).not.toContain('</script>');
    const data = JSON.parse(script.textContent!);
    expect(data['@type']).toBe('ProfilePage');
    expect(data.mainEntity).toMatchObject({
      name: 'Karim Hassan',
      alternateName: '@karim',
      jobTitle: 'Frontend lead | Angular و performance',
      sameAs: ['https://github.com/karim', 'https://karim.dev/'],
    });

    seo.clear();
    expect(document.head.querySelector('link[rel="canonical"]')).toBeNull();
    expect(meta.getTag('property="og:type"')).toBeNull();
  });

  it('falls back to a translated description without a title or a bio', () => {
    TestBed.inject(ProfileSeoService).apply(testProfile({ bio: null, headline: 'Writer' }));
    expect(TestBed.inject(Meta).getTag('name="description"')!.content).toBe('Writer');
    TestBed.inject(ProfileSeoService).apply(testProfile({ bio: null, headline: null }));
    expect(TestBed.inject(Meta).getTag('name="description"')!.content).toBe('مقالات Karim Hassan على ReadIn.');
    TestBed.inject(ProfileSeoService).clear();
  });
});
