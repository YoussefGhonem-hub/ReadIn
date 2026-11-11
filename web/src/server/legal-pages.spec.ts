import { LEGAL_STATIC_PAGES, legalStaticFile } from './legal-pages';

describe('legal static pages (F37)', () => {
  it('cover the privacy policy and the account deletion page', () => {
    expect(LEGAL_STATIC_PAGES).toEqual(['/privacy', '/delete-account']);
  });

  it('are served from the copies in web/public/legal/', () => {
    expect(legalStaticFile('/privacy')).toBe('legal/privacy.html');
    expect(legalStaticFile('/delete-account')).toBe('legal/delete-account.html');
  });
});
