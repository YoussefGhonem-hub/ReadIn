/**
 * The privacy policy and the public "Delete your account" page are static, bilingual pages. They are copies of the
 * repo's `public/privacy.html` and `public/delete-account.html` (Firebase Hosting), kept in `web/public/legal/` with
 * `web/public/logo.png` because the build only copies files inside `web/`. Change both copies together. This server
 * serves them on this domain at these paths, so the apps (`WEB_ORIGIN` + `GET /legal`'s `/privacy`; the page reads
 * `?lang=` itself) and the store listings open them on readin.online, with no redirect to another domain (F37, §32).
 */
export const LEGAL_STATIC_PAGES = ['/privacy', '/delete-account'] as const;

export type LegalStaticPage = (typeof LEGAL_STATIC_PAGES)[number];

/** The built file for [path], relative to the browser folder: `/privacy` → `legal/privacy.html`. */
export function legalStaticFile(path: LegalStaticPage): string {
  return `legal${path}.html`;
}
