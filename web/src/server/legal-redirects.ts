/**
 * The privacy policy and the public "Delete your account" page are static pages on Firebase Hosting (repo `public/`),
 * but the apps open them on this domain: the API's `GET /legal` gives `/privacy`, which the mobile app joins to its
 * `WEB_ORIGIN` (F37). These paths send the reader there, with the query (`?lang=en`) kept.
 */
export const LEGAL_REDIRECTS = ['/privacy', '/delete-account'] as const;

/** Where [originalUrl] (`/privacy?lang=en`) on [path] goes on [legalOrigin] (`https://x.firebaseapp.com`). */
export function legalRedirectUrl(legalOrigin: string, path: string, originalUrl: string): string {
  const query = originalUrl.indexOf('?');
  return `${legalOrigin}${path}${query >= 0 ? originalUrl.slice(query) : ''}`;
}
