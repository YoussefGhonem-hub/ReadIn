/**
 * A push as the app shows it: an in-app toast in the foreground, a system notification otherwise (SPEC §21.1).
 * `public/firebase-messaging-sw.js` applies the same rules for background notifications; keep the two in step.
 */
export interface PushMessage {
  title: string;
  body: string;
  /** In-app path to open, or null when the push has no (safe) link. */
  path: string | null;
}

interface RawPush {
  notification?: { title?: unknown; body?: unknown; click_action?: unknown };
  data?: Record<string, unknown>;
  fcmOptions?: { link?: unknown };
}

/** Reads an FCM web-push payload (`notification` and/or `data`). Returns null when it has nothing to show. */
export function toPushMessage(raw: unknown, origin: string, fallbackLang: 'ar' | 'en'): PushMessage | null {
  if (!raw || typeof raw !== 'object') return null;
  const { notification, data, fcmOptions } = raw as RawPush;
  const title = text(notification?.title) ?? text(data?.['title']);
  const body = text(notification?.body) ?? text(data?.['body']) ?? '';
  if (!title && !body) return null;
  const link = text(data?.['link']) ?? text(fcmOptions?.link) ?? text(notification?.click_action);
  const lang = data?.['lang'] === 'en' || data?.['lang'] === 'ar' ? data['lang'] : fallbackLang;
  return { title: title ?? '', body, path: pushLinkToPath(link, origin, lang) };
}

/** The push's `data.type` (e.g. `moderation_notice`, F22), or null. */
export function pushType(raw: unknown): string | null {
  if (!raw || typeof raw !== 'object') return null;
  return text((raw as RawPush).data?.['type']);
}

/**
 * Turns a push link into an in-app path. Deep links (`readin://a/{slug}#comment-{id}`) map to the web routes;
 * same-origin URLs and absolute paths are kept; anything else is dropped, so a push can never open another site.
 */
export function pushLinkToPath(link: string | null | undefined, origin: string, lang: 'ar' | 'en'): string | null {
  if (!link) return null;
  if (link.startsWith('readin://')) {
    const rest = link.slice('readin://'.length);
    if (rest.startsWith('a/')) return `/${lang}/${rest}`;
    return safePath(`/${rest}`);
  }
  if (link.startsWith('/')) return safePath(link);
  try {
    const url = new URL(link);
    return url.origin === origin ? safePath(`${url.pathname}${url.search}${url.hash}`) : null;
  } catch {
    return null;
  }
}

function safePath(path: string): string | null {
  // `//host` and `/\host` are protocol-relative URLs to another site.
  return path.startsWith('//') || path.startsWith('/\\') ? null : path;
}

function text(value: unknown): string | null {
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}
