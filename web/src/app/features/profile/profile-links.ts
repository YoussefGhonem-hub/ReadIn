import { ProfileLinks } from '../../core/api/models';
import { safeHttpUrl } from '../../shared/rdoc/rdoc.utils';
import { LINK_KINDS, LinkKind } from './profile-icons';

/** The API's limit for a link (`validation.url`). */
export const MAX_LINK_LENGTH = 2048;

export interface ProfileLink {
  kind: LinkKind;
  url: string;
  /** "github.com/mona": what the reader sees (always LTR). */
  label: string;
}

/** What gets saved for a link field: empty → null, a bare "github.com/mona" gets `https://`. */
export function normalizeLink(value: string | null | undefined): string | null {
  const trimmed = (value ?? '').trim();
  if (!trimmed) return null;
  return /^[a-z][a-z0-9+.-]*:/i.test(trimmed) ? trimmed : `https://${trimmed}`;
}

/** The API accepts absolute https URLs up to 2048 characters (null = no link). */
export function isValidLink(value: string | null): boolean {
  if (value === null) return true;
  if (value.length > MAX_LINK_LENGTH) return false;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && url.hostname.includes('.');
  } catch {
    return false;
  }
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

/** The profile's links in a fixed order, keeping only http(s) URLs (user content is never trusted as a scheme). */
export function profileLinks(links: ProfileLinks | null | undefined): ProfileLink[] {
  return LINK_KINDS.flatMap((kind) => {
    const url = safeHttpUrl(links?.[kind]);
    return url ? [{ kind, url, label: linkLabel(url) }] : [];
  });
}
