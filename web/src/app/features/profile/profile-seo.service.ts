import { DOCUMENT, Injectable, inject } from '@angular/core';
import { Meta, Title } from '@angular/platform-browser';
import { TranslocoService } from '@jsverse/transloco';
import { environment } from '../../../environments/environment';
import { ProfileDto } from '../../core/api/models';
import { profileLinks } from './profile-links';

const MARK = 'data-rd-profile-seo';
const META: readonly ['name' | 'property', string][] = [
  ['name', 'description'],
  ['property', 'og:type'],
  ['property', 'og:site_name'],
  ['property', 'og:title'],
  ['property', 'og:description'],
  ['property', 'og:url'],
  ['property', 'og:image'],
  ['property', 'profile:username'],
  ['name', 'twitter:card'],
  ['name', 'twitter:title'],
  ['name', 'twitter:description'],
  ['name', 'twitter:image'],
];

/** Public profile URL (SPEC §23). */
export function profileUrl(username: string): string {
  return `${environment.siteUrl}/@${encodeURIComponent(username)}`;
}

/**
 * Profile SEO (SPEC §23): title, description, canonical, Open Graph `profile` / Twitter card and schema.org
 * `ProfilePage` JSON-LD. Rendered on the server for crawlers; the phone number is never part of a profile.
 */
@Injectable({ providedIn: 'root' })
export class ProfileSeoService {
  private readonly document = inject(DOCUMENT);
  private readonly title = inject(Title);
  private readonly meta = inject(Meta);
  private readonly transloco = inject(TranslocoService);

  apply(profile: ProfileDto): void {
    this.clear();
    const url = profileUrl(profile.username);
    const name = `${profile.displayName} (@${profile.username})`;
    const description = this.description(profile);
    const image = profile.avatarVariants?.['512'] ?? profile.avatarUrl;

    this.title.setTitle(`${name} — ReadIn`);
    this.setMeta('name', 'description', description);
    this.setMeta('property', 'og:type', 'profile');
    this.setMeta('property', 'og:site_name', 'ReadIn');
    this.setMeta('property', 'og:title', name);
    this.setMeta('property', 'og:description', description);
    this.setMeta('property', 'og:url', url);
    this.setMeta('property', 'profile:username', profile.username);
    if (image) {
      this.setMeta('property', 'og:image', image);
      this.setMeta('name', 'twitter:image', image);
    }
    this.setMeta('name', 'twitter:card', 'summary');
    this.setMeta('name', 'twitter:title', name);
    this.setMeta('name', 'twitter:description', description);

    const canonical = this.document.createElement('link');
    canonical.setAttribute('rel', 'canonical');
    canonical.setAttribute('href', url);
    canonical.setAttribute(MARK, '');
    this.document.head.appendChild(canonical);

    const script = this.document.createElement('script');
    script.setAttribute('type', 'application/ld+json');
    script.setAttribute(MARK, '');
    // Escape `<` so a bio can never close the script element.
    script.textContent = JSON.stringify(this.structuredData(profile, url, description, image)).replace(/</g, '\\u003c');
    this.document.head.appendChild(script);
  }

  /** The page title for a missing profile (404). */
  notFound(): void {
    this.clear();
    this.title.setTitle(`${this.transloco.translate('profile.notFound.title')} — ReadIn`);
  }

  clear(): void {
    this.document.head.querySelectorAll(`[${MARK}]`).forEach((el) => el.remove());
    for (const [attr, key] of META) this.meta.removeTag(`${attr}="${key}"`);
  }

  private description(profile: ProfileDto): string {
    const bio = (profile.bio ?? '').replace(/\s+/g, ' ').trim();
    const text = bio || this.transloco.translate('profile.meta.description', { name: profile.displayName });
    return text.length > 160 ? `${text.slice(0, 157)}…` : text;
  }

  private structuredData(profile: ProfileDto, url: string, description: string, image: string | null): Record<string, unknown> {
    const sameAs = profileLinks(profile.links).map((link) => link.url);
    return {
      '@context': 'https://schema.org',
      '@type': 'ProfilePage',
      url,
      dateCreated: profile.joinedAt,
      mainEntity: {
        '@type': 'Person',
        name: profile.displayName,
        alternateName: `@${profile.username}`,
        identifier: profile.username,
        description,
        url,
        ...(image ? { image } : {}),
        ...(sameAs.length ? { sameAs } : {}),
        ...(profile.expertise.length ? { knowsAbout: profile.expertise.map((field) => field.name) } : {}),
        interactionStatistic: [
          { '@type': 'InteractionCounter', interactionType: 'https://schema.org/FollowAction', userInteractionCount: profile.stats.followers },
          { '@type': 'InteractionCounter', interactionType: 'https://schema.org/WriteAction', userInteractionCount: profile.stats.articles },
        ],
      },
    };
  }

  private setMeta(attr: 'name' | 'property', key: string, content: string): void {
    this.meta.updateTag({ [attr]: key, content }, `${attr}="${key}"`);
  }
}
