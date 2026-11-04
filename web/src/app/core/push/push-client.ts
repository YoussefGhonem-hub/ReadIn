import { InjectionToken } from '@angular/core';
import { environment } from '../../../environments/environment';
import { liveFirebaseApp } from '../firebase/live-app';

export type PushPermission = 'unsupported' | 'default' | 'granted' | 'denied';

/** The service worker that receives pushes; its own scope keeps it away from page requests. */
export const PUSH_WORKER_URL = '/firebase-messaging-sw.js';
export const PUSH_WORKER_SCOPE = '/firebase-cloud-messaging-push-scope';
/** Messages from the worker (see `public/firebase-messaging-sw.js`). */
export type WorkerMessage =
  /** A push that arrived while this tab was visible, so the worker showed no notification. */
  | { type: 'push'; payload: unknown }
  /** A notification was tapped while this tab was open: route to `path` and mark its notification read (F17). */
  | { type: 'open'; path: string; notificationId: string | null };

const WORKER_MESSAGE_TYPES: Record<string, WorkerMessage['type']> = { 'readin:push': 'push', 'readin:open': 'open' };

/** Browser web push through Firebase Cloud Messaging; tests replace it with a fake. */
export interface PushClient {
  /** False during SSR, in browsers without web push, and where no VAPID key is configured (the emulator). */
  isSupported(): Promise<boolean>;
  permission(): PushPermission;
  requestPermission(): Promise<PushPermission>;
  /** Registers the service worker and returns this browser's FCM token. */
  getToken(): Promise<string>;
  /** Invalidates the token, so this browser gets no more pushes for the previous account. */
  deleteToken(): Promise<void>;
  onWorkerMessage(next: (message: WorkerMessage) => void): () => void;
}

export const PUSH_CLIENT = new InjectionToken<PushClient>('PUSH_CLIENT', {
  providedIn: 'root',
  factory: () => browserPushClient,
});

const browserPushClient: PushClient = {
  async isSupported() {
    if (typeof window === 'undefined' || !environment.firebaseVapidKey) return false;
    if (!('serviceWorker' in navigator) || !('Notification' in window) || !('PushManager' in window)) return false;
    try {
      return await (await import('firebase/messaging')).isSupported();
    } catch {
      return false;
    }
  },

  permission() {
    return typeof Notification === 'undefined' ? 'unsupported' : Notification.permission;
  },

  async requestPermission() {
    return typeof Notification === 'undefined' ? 'unsupported' : Notification.requestPermission();
  },

  async getToken() {
    const [app, messaging] = await Promise.all([liveFirebaseApp(), import('firebase/messaging')]);
    const serviceWorkerRegistration = await navigator.serviceWorker.register(PUSH_WORKER_URL, { scope: PUSH_WORKER_SCOPE });
    return messaging.getToken(messaging.getMessaging(app), {
      vapidKey: environment.firebaseVapidKey ?? undefined,
      serviceWorkerRegistration,
    });
  },

  async deleteToken() {
    const [app, messaging] = await Promise.all([liveFirebaseApp(), import('firebase/messaging')]);
    await messaging.deleteToken(messaging.getMessaging(app));
  },

  onWorkerMessage(next) {
    const listener = (event: MessageEvent) => {
      const data = event.data as { type?: unknown; payload?: unknown; path?: unknown; notificationId?: unknown } | null;
      const type = typeof data?.type === 'string' ? WORKER_MESSAGE_TYPES[data.type] : undefined;
      if (type === 'push') next({ type, payload: data?.payload });
      else if (type === 'open' && typeof data?.path === 'string') {
        next({ type, path: data.path, notificationId: typeof data.notificationId === 'string' && data.notificationId ? data.notificationId : null });
      }
    };
    navigator.serviceWorker.addEventListener('message', listener);
    navigator.serviceWorker.startMessages();
    return () => navigator.serviceWorker.removeEventListener('message', listener);
  },
};
