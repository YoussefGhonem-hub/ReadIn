export interface AppEnvironment {
  production: boolean;
  /** Public origin of the web app, used for canonical/hreflang URLs. */
  siteUrl: string;
  /** ReadIn API base, including `/api/v1`. */
  apiBaseUrl: string;
  /** Base URL that `rdoc-asset://` image paths resolve against. */
  assetsBaseUrl: string;
  firebase: { apiKey: string; authDomain: string; projectId: string; appId: string };
  /** Firebase Auth emulator URL, or null to use real Firebase. */
  authEmulatorUrl: string | null;
}
