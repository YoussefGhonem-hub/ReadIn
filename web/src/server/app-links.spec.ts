import { appLinksConfig, appleAppSiteAssociation, assetLinks } from './app-links';

const FINGERPRINT = '14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5';
const OTHER = 'FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C';

describe('app links (.well-known, F24)', () => {
  describe('assetlinks.json', () => {
    it('is not served until a signing certificate is configured', () => {
      expect(assetLinks(appLinksConfig({}))).toBeNull();
      expect(assetLinks(appLinksConfig({ ANDROID_CERT_SHA256: ' , ' }))).toBeNull();
    });

    it('lets the Android app open the links, for every configured certificate', () => {
      const config = appLinksConfig({ ANDROID_CERT_SHA256: `${FINGERPRINT}, ${OTHER}` });
      expect(assetLinks(config)).toEqual([
        {
          relation: ['delegate_permission/common.handle_all_urls'],
          target: {
            namespace: 'android_app',
            package_name: 'app.readin.readin',
            sha256_cert_fingerprints: [FINGERPRINT, OTHER],
          },
        },
      ]);
    });

    it('accepts a fingerprint without colons or in lower case, once', () => {
      const bare = FINGERPRINT.replace(/:/g, '').toLowerCase();
      const config = appLinksConfig({ ANDROID_CERT_SHA256: `${bare},${FINGERPRINT}` });
      expect(config.androidCertSha256).toEqual([FINGERPRINT]);
      expect(config.ignored).toEqual([]);
    });

    it('ignores and reports values that are not fingerprints or package names', () => {
      const config = appLinksConfig({ ANDROID_CERT_SHA256: `${FINGERPRINT},AB:CD,${FINGERPRINT.replace('14', 'ZZ')}`, ANDROID_APP_ID: 'not a package' });
      expect(config.androidCertSha256).toEqual([FINGERPRINT]);
      expect(config.androidPackage).toBe('app.readin.readin');
      expect(config.ignored).toHaveLength(3);
    });

    it('uses ANDROID_APP_ID for another application id', () => {
      const config = appLinksConfig({ ANDROID_APP_ID: 'app.readin.readin.dev', ANDROID_CERT_SHA256: FINGERPRINT });
      expect((assetLinks(config) as { target: { package_name: string } }[])[0].target.package_name).toBe('app.readin.readin.dev');
    });
  });

  describe('apple-app-site-association', () => {
    it('lets the iOS app open the web article, tag page and field page links by default', () => {
      expect(appleAppSiteAssociation(appLinksConfig({}))).toEqual({
        applinks: {
          details: [
            {
              appIDs: ['7A25UFD8VC.app.readin.readin'],
              components: [{ '/': '/ar/a/*' }, { '/': '/en/a/*' }, { '/': '/tags/*' }, { '/': '/f/*' }],
            },
          ],
        },
      });
    });

    it('takes the app ids from IOS_APP_IDS, and is not served when it is empty', () => {
      const config = appLinksConfig({ IOS_APP_IDS: 'ABCDE12345.app.readin.readin, ABCDE12345.app.readin.beta, nope' });
      expect(config.iosAppIds).toEqual(['ABCDE12345.app.readin.readin', 'ABCDE12345.app.readin.beta']);
      expect(config.ignored).toEqual(['IOS_APP_IDS item nope']);
      expect(appleAppSiteAssociation(appLinksConfig({ IOS_APP_IDS: '' }))).toBeNull();
    });
  });
});
