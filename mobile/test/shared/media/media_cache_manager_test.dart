import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/config/app_config.dart';
import 'package:readin/shared/media/media_cache_manager.dart';

AppConfig config(Flavor flavor, String apiBaseUrl) =>
    AppConfig(flavor: flavor, apiBaseUrl: apiBaseUrl, useFirebaseEmulator: false, emulatorHost: 'localhost');

/// The dev API names its uploads on `http://localhost:5080` (`Storage:PublicBaseUrl`); a device that reaches the API
/// elsewhere fetches them from there.
void main() {
  group('devApiHost', () {
    test('the Android emulator and a phone on the network reach the dev API by another host', () {
      expect(MediaCacheManager.devApiHost(config(Flavor.dev, 'http://10.0.2.2:5080/api/v1')), '10.0.2.2');
      expect(MediaCacheManager.devApiHost(config(Flavor.dev, 'http://192.168.1.20:5080/api/v1')), '192.168.1.20');
    });

    test('none when the API is on localhost already, or in production', () {
      expect(MediaCacheManager.devApiHost(config(Flavor.dev, 'http://localhost:5080/api/v1')), isNull);
      expect(MediaCacheManager.devApiHost(config(Flavor.dev, 'http://127.0.0.1:5080/api/v1')), isNull);
      expect(MediaCacheManager.devApiHost(config(Flavor.prod, 'https://api.readin.app/api/v1')), isNull);
    });
  });

  group('fetchUrl', () {
    const avatar = 'http://localhost:5080/uploads/avatars/2026/11/5d8b_256.webp';

    test('an upload named on localhost comes from the API host, same port and path', () {
      expect(
        MediaCacheManager.fetchUrl(avatar, apiHost: '10.0.2.2'),
        'http://10.0.2.2:5080/uploads/avatars/2026/11/5d8b_256.webp',
      );
      expect(
        MediaCacheManager.fetchUrl('http://127.0.0.1:5080/uploads/covers/c.webp?v=2', apiHost: '10.0.2.2'),
        'http://10.0.2.2:5080/uploads/covers/c.webp?v=2',
      );
    });

    test('other hosts, and builds without a dev API host, are left alone', () {
      expect(
        MediaCacheManager.fetchUrl('https://api.readin.app/uploads/a.webp', apiHost: '10.0.2.2'),
        'https://api.readin.app/uploads/a.webp',
      );
      expect(MediaCacheManager.fetchUrl(avatar, apiHost: null), avatar);
    });
  });
}
