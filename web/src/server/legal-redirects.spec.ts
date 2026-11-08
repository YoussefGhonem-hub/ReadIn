import { LEGAL_REDIRECTS, legalRedirectUrl } from './legal-redirects';

const FIREBASE = 'https://readin-cca78.firebaseapp.com';

describe('legal redirects (F37)', () => {
  it('cover the privacy policy and the account deletion page', () => {
    expect(LEGAL_REDIRECTS).toEqual(['/privacy', '/delete-account']);
  });

  it('keep the language the app asked for', () => {
    expect(legalRedirectUrl(FIREBASE, '/privacy', '/privacy?lang=en')).toBe(`${FIREBASE}/privacy?lang=en`);
    expect(legalRedirectUrl(FIREBASE, '/delete-account', '/delete-account?lang=ar')).toBe(`${FIREBASE}/delete-account?lang=ar`);
  });

  it('go to the plain page without a query', () => {
    expect(legalRedirectUrl(FIREBASE, '/privacy', '/privacy')).toBe(`${FIREBASE}/privacy`);
  });
});
