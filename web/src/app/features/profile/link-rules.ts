import { LinkPlatform } from '../../core/api/models';

/**
 * The rules of a profile's social links and title (SPEC F14; contract Profile → "Title and social links"), the same
 * checks the API makes (`ProfileLinkRules`, `HeadlineRules` in ReadIn.Domain), so the editor shows each error under its
 * field before saving. The server stays the judge: its codes come back the same way (`errors["links[2].url"]`).
 */

/** Every platform, in the SPEC's order (the editor's picker). */
export const LINK_PLATFORMS: readonly LinkPlatform[] = [
  'linkedin',
  'x',
  'instagram',
  'facebook',
  'youtube',
  'tiktok',
  'snapchat',
  'threads',
  'telegram',
  'github',
  'medium',
  'behance',
  'website',
  'other',
];

/** A named platform's hosts: the host itself or any subdomain of it. `website` and `other` take any https host. */
export const PLATFORM_HOSTS: Readonly<Partial<Record<LinkPlatform, readonly string[]>>> = {
  linkedin: ['linkedin.com', 'lnkd.in'],
  x: ['x.com', 'twitter.com'],
  instagram: ['instagram.com', 'instagr.am'],
  facebook: ['facebook.com', 'fb.com', 'fb.me'],
  youtube: ['youtube.com', 'youtu.be'],
  tiktok: ['tiktok.com'],
  snapchat: ['snapchat.com'],
  threads: ['threads.net', 'threads.com'],
  telegram: ['t.me', 'telegram.me'],
  github: ['github.com'],
  medium: ['medium.com'],
  behance: ['behance.net'],
};

/** What a new link's field suggests, per platform. */
export const LINK_PLACEHOLDERS: Readonly<Record<LinkPlatform, string>> = {
  linkedin: 'https://www.linkedin.com/in/you',
  x: 'https://x.com/you',
  instagram: 'https://instagram.com/you',
  facebook: 'https://facebook.com/you',
  youtube: 'https://youtube.com/@you',
  tiktok: 'https://tiktok.com/@you',
  snapchat: 'https://snapchat.com/add/you',
  threads: 'https://threads.net/@you',
  telegram: 'https://t.me/you',
  github: 'https://github.com/you',
  medium: 'https://medium.com/@you',
  behance: 'https://behance.net/you',
  website: 'https://example.com',
  other: 'https://example.com/you',
};

export const MAX_LINKS = 8;
export const MAX_LINK_URL = 500;
export const MIN_LINK_LABEL = 2;
export const MAX_LINK_LABEL = 30;
export const MAX_HEADLINE = 120;

/** The validation codes of a link (the API's `link.*`, plus `validation.required` for an empty URL). */
export type LinkCode =
  | 'link.too_many'
  | 'link.platform_invalid'
  | 'link.duplicate_platform'
  | 'validation.required'
  | 'link.too_long'
  | 'link.https_required'
  | 'link.url_invalid'
  | 'link.host_mismatch'
  | 'link.label_required'
  | 'link.label_invalid'
  | 'link.label_not_allowed';

export type HeadlineCode = 'profile.headline_too_long' | 'profile.headline_invalid';

/** A link being edited: what the member picked and typed. */
export interface LinkDraft {
  platform: LinkPlatform | null;
  url: string;
  label: string;
}

/** The codes per link and part, plus `list` for the whole list (too many). */
export interface LinkErrors {
  list: LinkCode | null;
  items: { platform: LinkCode | null; url: LinkCode | null; label: LinkCode | null }[];
}

/**
 * Code point ranges a one-line text may not hold: line breaks, tabs and other control characters (C0, DEL, C1), the
 * line/paragraph separators (U+2028/9), direction marks and overrides (U+200E/F, U+202A–E) and isolates (U+2066–9):
 * the clients isolate names and titles themselves.
 */
const UNCLEAN_RANGES: readonly (readonly [number, number])[] = [
  [0x0000, 0x001f],
  [0x007f, 0x009f],
  [0x200e, 0x200f],
  [0x2028, 0x2029],
  [0x202a, 0x202e],
  [0x2066, 0x2069],
];
const IPV4 = /^\d{1,3}(\.\d{1,3}){3}$/;

/** No line breaks, control or direction characters (the API's `TextRules.IsOneCleanLine`). */
export function isOneCleanLine(text: string): boolean {
  for (const char of text) {
    const code = char.codePointAt(0) ?? 0;
    if (UNCLEAN_RANGES.some(([from, to]) => code >= from && code <= to)) return false;
  }
  return true;
}

export function isLinkPlatform(value: unknown): value is LinkPlatform {
  return typeof value === 'string' && (LINK_PLATFORMS as readonly string[]).includes(value);
}

/** Trimmed, with `https://` added when there is no scheme (`instagram.com/name` → `https://instagram.com/name`). */
export function normalizeLinkUrl(value: string | null | undefined): string {
  const trimmed = (value ?? '').trim();
  if (!trimmed) return '';
  return trimmed.includes('://') ? trimmed : `https://${trimmed}`;
}

/** `host` is one of the platform's hosts or a subdomain of one; always true for website and other. */
export function platformAllowsHost(platform: LinkPlatform, host: string): boolean {
  const hosts = PLATFORM_HOSTS[platform];
  if (!hosts) return true;
  const clean = host.replace(/\.+$/, '').toLowerCase();
  return hosts.some((h) => clean === h || clean.endsWith(`.${h}`));
}

/** The first rule a (normalized) URL breaks for its platform, or null. */
export function linkUrlProblem(platform: LinkPlatform | null, url: string): LinkCode | null {
  if (!url) return 'validation.required';
  if (url.length > MAX_LINK_URL) return 'link.too_long';
  const scheme = url.slice(0, url.indexOf('://'));
  if (scheme.toLowerCase() !== 'https') return 'link.https_required';
  if (/\s/.test(url) || !isOneCleanLine(url)) return 'link.url_invalid';
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return 'link.url_invalid';
  }
  if (parsed.protocol !== 'https:' || parsed.username || parsed.password || parsed.port) return 'link.url_invalid';
  const host = parsed.hostname.replace(/\.+$/, '');
  if (!host.includes('.') || host.startsWith('[') || IPV4.test(host)) return 'link.url_invalid';
  return platform && !platformAllowsHost(platform, host) ? 'link.host_mismatch' : null;
}

/** `other` needs a label of 2–30 characters on one line; the other platforms take none. */
export function linkLabelProblem(platform: LinkPlatform | null, label: string): LinkCode | null {
  const trimmed = label.trim();
  if (platform !== 'other') return trimmed && platform ? 'link.label_not_allowed' : null;
  if (!trimmed) return 'link.label_required';
  if (trimmed.length < MIN_LINK_LABEL || trimmed.length > MAX_LINK_LABEL || !isOneCleanLine(trimmed)) return 'link.label_invalid';
  return null;
}

/**
 * Checks the whole list in order, like the API: at most 8, one per named platform (Other may repeat). Each link is
 * checked as it will be sent (`toLinkInputs`): a label only counts on `other`.
 */
export function checkLinks(links: readonly LinkDraft[]): LinkErrors {
  const seen = new Set<LinkPlatform>();
  const items = links.map((link) => {
    let platform: LinkCode | null = null;
    if (!link.platform) platform = 'link.platform_invalid';
    else if (link.platform !== 'other' && seen.has(link.platform)) platform = 'link.duplicate_platform';
    if (link.platform) seen.add(link.platform);
    const label = link.platform === 'other' ? link.label : '';
    return { platform, url: linkUrlProblem(link.platform, normalizeLinkUrl(link.url)), label: linkLabelProblem(link.platform, label) };
  });
  return { list: links.length > MAX_LINKS ? 'link.too_many' : null, items };
}

/** The `links` of `PATCH /me`: normalized URLs, a trimmed label for `other` only. */
export function toLinkInputs(links: readonly LinkDraft[]): { platform: LinkPlatform; url: string; label?: string }[] {
  return links.flatMap((link) =>
    link.platform
      ? [{ platform: link.platform, url: normalizeLinkUrl(link.url), ...(link.platform === 'other' ? { label: link.label.trim() } : {}) }]
      : [],
  );
}

export function hasLinkErrors(errors: LinkErrors): boolean {
  return !!errors.list || errors.items.some((e) => e.platform || e.url || e.label);
}

/** Trimmed; empty → null (the API clears the title then). */
export function normalizeHeadline(value: string | null | undefined): string | null {
  const trimmed = (value ?? '').trim();
  return trimmed || null;
}

/** The first rule a title breaks, or null (≤ 120 after trimming, one clean line). */
export function headlineProblem(value: string | null | undefined): HeadlineCode | null {
  const headline = normalizeHeadline(value);
  if (headline === null) return null;
  if (headline.length > MAX_HEADLINE) return 'profile.headline_too_long';
  return isOneCleanLine(headline) ? null : 'profile.headline_invalid';
}
