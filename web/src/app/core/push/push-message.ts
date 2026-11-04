/**
 * A push as the app shows it: an in-app toast in the foreground, a system notification otherwise (SPEC §21.1).
 * `public/firebase-messaging-sw.js` applies the same rules for background notifications; keep the two in step.
 */
export interface PushMessage {
  title: string;
  body: string;
  /** In-app path to open, or null when the push has no (safe) link. */
  path: string | null;
  /** The notification-center row behind the push (F17), marked read when the push is tapped. */
  notificationId: string | null;
}

interface RawPush {
  notification?: { title?: unknown; body?: unknown; click_action?: unknown };
  data?: Record<string, unknown>;
  fcmOptions?: { link?: unknown };
}

/**
 * The query parameter the service worker adds when a tapped push opens a new tab, so the page can mark that
 * notification read (`POST /me/notifications/{id}/read`) once the session is restored. The page removes it at once.
 */
export const NOTIFICATION_PARAM = 'notification';

/** Reads an FCM web-push payload (`notification` and/or `data`). Returns null when it has nothing to show. */
export function toPushMessage(raw: unknown, origin: string, fallbackLang: 'ar' | 'en'): PushMessage | null {
  if (!raw || typeof raw !== 'object') return null;
  const { notification, data, fcmOptions } = raw as RawPush;
  const title = text(notification?.title) ?? text(data?.['title']);
  const body = text(notification?.body) ?? text(data?.['body']) ?? '';
  if (!title && !body) return null;
  const link = text(data?.['link']) ?? text(fcmOptions?.link) ?? text(notification?.click_action);
  const lang = data?.['lang'] === 'en' || data?.['lang'] === 'ar' ? data['lang'] : fallbackLang;
  return { title: title ?? '', body, path: pushLinkToPath(link, origin, lang), notificationId: pushNotificationId(raw) };
}

/** The push's `data.type` (e.g. `moderation_notice`, F22), or null. */
export function pushType(raw: unknown): string | null {
  if (!raw || typeof raw !== 'object') return null;
  return text((raw as RawPush).data?.['type']);
}

/** The push's `data.notificationId` (F17), or null. */
export function pushNotificationId(raw: unknown): string | null {
  if (!raw || typeof raw !== 'object') return null;
  return text((raw as RawPush).data?.['notificationId']);
}

/**
 * Turns a push or notification link into an in-app path. Deep links map to the web routes (SPEC §23):
 * `readin://a/{slug}#comment-{id}` → `/{lang}/a/{slug}#comment-{id}`, `readin://u/{username}[/followers]` →
 * `/@{username}[/followers]`, `readin://settings/account` → `/settings#account`, and the rest to the same path
 * (`readin://notifications`, `readin://me/stats`). Same-origin URLs and absolute paths are kept; anything else is
 * dropped, so a push can never open another site.
 */
export function pushLinkToPath(link: string | null | undefined, origin: string, lang: 'ar' | 'en'): string | null {
  if (!link) return null;
  if (link.startsWith('readin://')) return deepLinkToPath(link.slice('readin://'.length), lang);
  if (link.startsWith('/')) return safePath(link);
  try {
    const url = new URL(link);
    return url.origin === origin ? safePath(`${url.pathname}${url.search}${url.hash}`) : null;
  } catch {
    return null;
  }
}

function deepLinkToPath(rest: string, lang: 'ar' | 'en'): string | null {
  if (rest.startsWith('a/')) return `/${lang}/${rest}`;
  if (rest.startsWith('u/')) return rest.length > 2 ? safePath(`/@${rest.slice(2)}`) : null;
  if (rest === 'settings/account') return '/settings#account';
  return safePath(`/${rest}`);
}

function safePath(path: string): string | null {
  // `//host` and `/\host` are protocol-relative URLs to another site.
  return path.startsWith('//') || path.startsWith('/\\') ? null : path;
}

function text(value: unknown): string | null {
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}
