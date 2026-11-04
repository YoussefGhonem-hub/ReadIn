/*
 * ReadIn web push (SPEC §21.1). Firebase Cloud Messaging delivers the push here; this worker hands it to a
 * visible tab (shown as an in-app toast by PushService) or shows a system notification, and opens the right
 * page when the notification is tapped. Link rules mirror src/app/core/push/push-message.ts.
 * Plain JS with no imports: the page registers this file with the FCM token, the SDK is not needed here.
 */
const PUSH_MESSAGE_TYPE = 'readin:push';
const OPEN_MESSAGE_TYPE = 'readin:open';
/** A new tab learns which notification to mark read from this query parameter (NOTIFICATION_PARAM in push-message.ts). */
const NOTIFICATION_PARAM = 'notification';

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

self.addEventListener('push', (event) => {
  let payload = null;
  try {
    payload = event.data ? event.data.json() : null;
  } catch {
    return;
  }
  if (!payload || typeof payload !== 'object') return;
  event.waitUntil(deliver(payload));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  const path = data.path || '/notifications';
  event.waitUntil(openPath(path, text(data.notificationId)));
});

async function deliver(payload) {
  const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
  const visible = windows.find((client) => client.visibilityState === 'visible');
  if (visible) {
    visible.postMessage({ type: PUSH_MESSAGE_TYPE, payload });
    return;
  }
  const notification = payload.notification || {};
  const data = payload.data || {};
  const title = text(notification.title) || text(data.title);
  const body = text(notification.body) || text(data.body) || '';
  if (!title && !body) return;
  const lang = data.lang === 'en' ? 'en' : 'ar';
  const link = text(data.link) || text(payload.fcmOptions && payload.fcmOptions.link) || text(notification.click_action);
  await self.registration.showNotification(title || 'ReadIn', {
    body,
    icon: '/favicon.ico',
    lang,
    dir: 'auto',
    // Same tag = the newer push replaces the older one (e.g. "Ahmed and 9 others reacted").
    tag: text(data.tag) || undefined,
    // The notification-center row (F17): tapping the push marks it read.
    data: { path: toPath(link, lang), notificationId: text(data.notificationId) },
  });
}

async function openPath(path, notificationId) {
  const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
  const tab = windows.find((client) => new URL(client.url).origin === self.location.origin);
  if (tab) {
    // This worker does not control the page (its scope is separate), so the open tab routes itself and marks it read.
    tab.postMessage({ type: OPEN_MESSAGE_TYPE, path, notificationId });
    await tab.focus();
    return;
  }
  const url = new URL(path, self.location.origin);
  if (notificationId) url.searchParams.set(NOTIFICATION_PARAM, notificationId);
  await self.clients.openWindow(url.href);
}

/** Deep links → web routes, as pushLinkToPath in push-message.ts. */
function toPath(link, lang) {
  if (!link) return null;
  if (link.startsWith('readin://')) {
    const rest = link.slice('readin://'.length);
    if (rest.startsWith('a/')) return `/${lang}/${rest}`;
    if (rest.startsWith('u/')) return rest.length > 2 ? safePath(`/@${rest.slice(2)}`) : null;
    if (rest === 'settings/account') return '/settings#account';
    if (rest === 'verification') return '/verification';
    return safePath(`/${rest}`);
  }
  if (link.startsWith('/')) return safePath(link);
  try {
    const url = new URL(link);
    return url.origin === self.location.origin ? safePath(url.pathname + url.search + url.hash) : null;
  } catch {
    return null;
  }
}

function safePath(path) {
  return path.startsWith('//') || path.startsWith('/\\') ? null : path;
}

function text(value) {
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}
