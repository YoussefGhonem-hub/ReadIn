/*
 * ReadIn web push (SPEC §21.1). Firebase Cloud Messaging delivers the push here; this worker hands it to a
 * visible tab (shown as an in-app toast by PushService) or shows a system notification, and opens the right
 * page when the notification is tapped. Link rules mirror src/app/core/push/push-message.ts.
 * Plain JS with no imports: the page registers this file with the FCM token, the SDK is not needed here.
 */
const PUSH_MESSAGE_TYPE = 'readin:push';
const OPEN_MESSAGE_TYPE = 'readin:open';

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
  const path = (event.notification.data && event.notification.data.path) || '/notifications';
  event.waitUntil(openPath(path));
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
    data: { path: toPath(link, lang) },
  });
}

async function openPath(path) {
  const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
  const tab = windows.find((client) => new URL(client.url).origin === self.location.origin);
  if (tab) {
    // This worker does not control the page (its scope is separate), so the open tab routes itself.
    tab.postMessage({ type: OPEN_MESSAGE_TYPE, path });
    await tab.focus();
    return;
  }
  await self.clients.openWindow(new URL(path, self.location.origin).href);
}

function toPath(link, lang) {
  if (!link) return null;
  if (link.startsWith('readin://')) {
    const rest = link.slice('readin://'.length);
    return rest.startsWith('a/') ? `/${lang}/${rest}` : safePath(`/${rest}`);
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
