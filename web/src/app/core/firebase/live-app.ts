import type { FirebaseApp } from 'firebase/app';
import { environment } from '../../../environments/environment';

/**
 * Name of the Firebase app used for the Realtime Database and web push (SPEC §21). It is separate from the default
 * app, so the Realtime Database's custom-token session never replaces any other Firebase session in the page.
 */
export const LIVE_APP_NAME = 'readin-live';

/** Loads the Firebase SDK on first use (browser only, never during SSR) and returns the live app. */
export async function liveFirebaseApp(): Promise<FirebaseApp> {
  const { getApps, initializeApp } = await import('firebase/app');
  return getApps().find((app) => app.name === LIVE_APP_NAME) ?? initializeApp(environment.firebase, LIVE_APP_NAME);
}
