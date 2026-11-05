import { LinkPlatform, ProfileLinkDto, ProfileLinks } from '../../core/api/models';
import { safeHttpUrl } from '../../shared/rdoc/rdoc.utils';
import { isLinkPlatform } from './link-rules';

export interface ProfileLink {
  platform: LinkPlatform;
  url: string;
  /** The member's name for an `other` link (its accessible name); null on the named platforms. */
  label: string | null;
  /** "github.com/mona": the address as the reader sees it (always LTR). */
  display: string;
}

/** "https://www.github.com/mona/" → "github.com/mona". */
export function linkLabel(url: string): string {
  try {
    const parsed = new URL(url);
    const path = `${parsed.pathname}${parsed.search}`.replace(/\/+$/, '');
    return `${parsed.hostname.replace(/^www\./, '')}${path}`;
  } catch {
    return url;
  }
}

/**
 * The `links` of a profile as an array: the API sends `ProfileLinkDto[]`; an API older than the profile step sent
 * `{ github, linkedin, website }`, read here in the order the migration keeps (GitHub, LinkedIn, website).
 */
export function profileLinksOf(links: ProfileLinkDto[] | ProfileLinks | null | undefined): ProfileLinkDto[] {
  if (Array.isArray(links)) return links;
  if (!links || typeof links !== 'object') return [];
  return (['github', 'linkedin', 'website'] as const).flatMap((platform) => {
    const url = links[platform];
    return url ? [{ platform, url, label: null }] : [];
  });
}

/**
 * The profile's links in the member's order, keeping only https/http URLs of a known platform (user content is never
 * trusted as a scheme); an `other` link without a label is shown as "Other".
 */
export function profileLinks(links: ProfileLinkDto[] | ProfileLinks | null | undefined): ProfileLink[] {
  return profileLinksOf(links).flatMap((link) => {
    const url = safeHttpUrl(link?.url);
    if (!url || !isLinkPlatform(link.platform)) return [];
    const label = link.platform === 'other' ? link.label?.trim() || null : null;
    return [{ platform: link.platform, url, label, display: linkLabel(url) }];
  });
}
