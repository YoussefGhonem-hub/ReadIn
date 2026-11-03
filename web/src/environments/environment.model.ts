export interface AppEnvironment {
  production: boolean;
  /** Public origin of the web app, used for canonical/hreflang URLs. */
  siteUrl: string;
  /** ReadIn API base, including `/api/v1`. */
  apiBaseUrl: string;
  /** Origin that `rdoc-asset://` paths resolve against: the API, which serves `/uploads` (ADR 0010). */
  assetsBaseUrl: string;
  /**
   * Public Firebase web config: the emulator project in development, the single real project in production
   * (ADR 0005). Firebase is used only for web push and the Realtime Database (SPEC §21).
   */
  firebase: {
    apiKey: string;
    authDomain: string;
    projectId: string;
    appId: string;
    databaseURL: string;
    messagingSenderId: string;
  };
  /** Public VAPID key for web push (FCM), or null where push is unavailable (the emulator has no FCM). */
  firebaseVapidKey: string | null;
  /** Realtime Database emulator `host:port`, or null to use the real project. */
  databaseEmulatorHost: string | null;
  /** Firebase Auth emulator URL, or null to use the real Firebase project. */
  authEmulatorUrl: string | null;
}
