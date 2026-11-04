/**
 * The two files a phone fetches from the web domain before it lets the app open that domain's links (SPEC F24,
 * docs/setup/app-links.md): Android's Digital Asset Links (`/.well-known/assetlinks.json`) and Apple's
 * `/.well-known/apple-app-site-association`. The SSR server (server.ts) serves them from its environment, so the same
 * build works on any domain and with any signing key:
 *
 * - `ANDROID_APP_ID`: the Android application id (default `app.readin.readin`);
 * - `ANDROID_CERT_SHA256`: the SHA-256 fingerprints of the certificates the installed app is signed with, comma
 *   separated (the Play app signing key, and the upload key for builds installed outside Play). Unset: 404, since
 *   Android can't verify anything without one;
 * - `IOS_APP_IDS`: `{TeamID}.{bundle id}` values, comma separated (default `7A25UFD8VC.app.readin.readin`); empty: 404.
 *
 * Pure functions: no Node APIs, so the unit tests run them as they are.
 */

/** The article paths the apps open: the web's article URLs, one per language (`/ar/a/{slug}`, `/en/a/{slug}`). */
export const APP_LINK_ARTICLE_PATHS = ['/ar/a/*', '/en/a/*'] as const;

export interface AppLinksConfig {
  androidPackage: string;
  androidCertSha256: string[];
  iosAppIds: string[];
  /** Values that were ignored because they don't look right; the server logs them at startup. */
  ignored: string[];
}

const DEFAULT_ANDROID_PACKAGE = 'app.readin.readin';
const DEFAULT_IOS_APP_ID = '7A25UFD8VC.app.readin.readin';

const ANDROID_PACKAGE = /^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$/;
const CERT_SHA256 = /^([0-9A-F]{2}:){31}[0-9A-F]{2}$/;
const IOS_APP_ID = /^[A-Z0-9]{10}\.[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$/;

function list(value: string | undefined): string[] {
  return (value ?? '')
    .split(',')
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}

/** Reads the configuration from environment variables (see the file comment). */
export function appLinksConfig(env: Record<string, string | undefined>): AppLinksConfig {
  const ignored: string[] = [];

  const packageName = env['ANDROID_APP_ID']?.trim() || DEFAULT_ANDROID_PACKAGE;
  const androidPackage = ANDROID_PACKAGE.test(packageName) ? packageName : DEFAULT_ANDROID_PACKAGE;
  if (androidPackage !== packageName) ignored.push(`ANDROID_APP_ID=${packageName}`);

  const androidCertSha256: string[] = [];
  for (const raw of list(env['ANDROID_CERT_SHA256'])) {
    // Accept the fingerprint as keytool or the Play Console prints it, with or without colons, in any case.
    const hex = raw.replace(/:/g, '').toUpperCase();
    const fingerprint = hex.match(/.{1,2}/g)?.join(':') ?? '';
    if (CERT_SHA256.test(fingerprint)) {
      if (!androidCertSha256.includes(fingerprint)) androidCertSha256.push(fingerprint);
    } else {
      ignored.push(`ANDROID_CERT_SHA256 item ${raw}`);
    }
  }

  const iosAppIds: string[] = [];
  for (const id of env['IOS_APP_IDS'] === undefined ? [DEFAULT_IOS_APP_ID] : list(env['IOS_APP_IDS'])) {
    if (IOS_APP_ID.test(id)) {
      if (!iosAppIds.includes(id)) iosAppIds.push(id);
    } else {
      ignored.push(`IOS_APP_IDS item ${id}`);
    }
  }

  return { androidPackage, androidCertSha256, iosAppIds, ignored };
}

/** `/.well-known/assetlinks.json`, or null (404) while no signing certificate is configured. */
export function assetLinks(config: AppLinksConfig): unknown[] | null {
  if (config.androidCertSha256.length === 0) return null;
  return [
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: config.androidPackage,
        sha256_cert_fingerprints: config.androidCertSha256,
      },
    },
  ];
}

/** `/.well-known/apple-app-site-association`, or null (404) when no app id is configured. */
export function appleAppSiteAssociation(config: AppLinksConfig): unknown | null {
  if (config.iosAppIds.length === 0) return null;
  return {
    applinks: {
      details: [
        {
          appIDs: config.iosAppIds,
          components: APP_LINK_ARTICLE_PATHS.map((path) => ({ '/': path })),
        },
      ],
    },
  };
}
