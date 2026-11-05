import { expect, test } from '@playwright/test';

/**
 * App Links and Universal Links (SPEC F24, docs/setup/app-links.md): the SSR server answers the two `.well-known` files
 * the phones read before the app may open the web's article links (src/server/app-links.ts). The e2e server runs with
 * no ANDROID_CERT_SHA256 and no IOS_APP_IDS, so Android's file is not served yet and Apple's has the default app id.
 */
test.describe('app links (.well-known)', () => {
  test('apple-app-site-association: JSON at its exact path, the article, tag, field and category paths, no redirect', async ({ request }) => {
    const response = await request.get('/.well-known/apple-app-site-association', { maxRedirects: 0 });
    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toContain('application/json');
    expect(await response.json()).toEqual({
      applinks: {
        details: [
          {
            appIDs: ['7A25UFD8VC.app.readin.readin'],
            components: [{ '/': '/ar/a/*' }, { '/': '/en/a/*' }, { '/': '/tags/*' }, { '/': '/f/*' }, { '/': '/@*/c/*' }],
          },
        ],
      },
    });
  });

  test('assetlinks.json: not served until a signing certificate is configured', async ({ request }) => {
    const response = await request.get('/.well-known/assetlinks.json', { maxRedirects: 0 });
    expect(response.status()).toBe(404);
  });
});
