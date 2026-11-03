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
  /**
   * Firebase Auth emulator URL, or null to use the real Firebase project. Firebase Auth only exchanges the custom
   * token for the Realtime Database (ADR 0008); it is never a ReadIn sign-in.
   */
  authEmulatorUrl: string | null;
  /** Where "Forgot the PIN too?" sends people (ADR 0009: an Admin resets the account); also the email route to delete. */
  supportEmail: string;
  /** The public "Delete your account" page (`public/delete-account.html`): what is deleted, and the email route. */
  accountDeletionUrl: string;
  /**
   * Google Identity Services web client id (a public identifier, ADR 0012). Empty hides "Continue with Google"; the
   * button also needs the API to list `google` in `GET /auth/config` → `externalProviders`.
   */
  googleWebClientId: string;
  /** Sign in with Apple Services ID for the web. Empty (none created yet) hides "Continue with Apple". */
  appleServicesId: string;
}
