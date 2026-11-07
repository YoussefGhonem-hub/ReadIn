import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/app_update/data/datasources/app_update_api.dart';
import 'package:readin/features/app_update/data/datasources/update_policy_cache.dart';
import 'package:readin/features/app_update/data/models/update_policy_models.dart';
import 'package:readin/features/app_update/data/repositories/app_update_repository_impl.dart';
import 'package:readin/features/app_update/domain/entities/update_policy.dart';

import '../../helpers/app_update_fakes.dart';
import '../../helpers/fake_auth.dart';

const policyJson = {
  'ios': {'minimumVersion': '1.2.0', 'storeUrl': appStoreUrl},
  'android': {'minimumVersion': '1.2.0+14', 'storeUrl': null},
};

void main() {
  group('the policy', () {
    test('reads both platforms', () {
      expect(
        UpdatePolicyModel.fromJson(policyJson).toEntity(),
        const UpdatePolicy(
          ios: PlatformUpdatePolicy(minimumVersion: '1.2.0', storeUrl: appStoreUrl),
          android: PlatformUpdatePolicy(minimumVersion: '1.2.0+14'),
        ),
      );
    });

    test('a platform left out, or without a minimum, supports every version', () {
      expect(UpdatePolicyModel.fromJson(const {}).toEntity(), const UpdatePolicy());
      expect(
        UpdatePolicyModel.fromJson(const {
          'ios': {'minimumVersion': null, 'storeUrl': null},
        }).toEntity(),
        const UpdatePolicy(),
      );
    });

    test('a body of the wrong shape is unreadable', () {
      expect(() => UpdatePolicyModel.fromJson(const {'ios': 'everything'}), throwsA(isA<TypeError>()));
      expect(
        () => UpdatePolicyModel.fromJson(const {
          'android': {'minimumVersion': 2},
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('UpdateRequirement.of', () {
    UpdateRequirement? of(InstalledApp app, {String? minimum, String? storeUrl}) {
      final rule = PlatformUpdatePolicy(minimumVersion: minimum, storeUrl: storeUrl);
      return UpdateRequirement.of(UpdatePolicy(ios: rule, android: rule), app);
    }

    test('nothing when the installed version is supported', () {
      expect(of(androidApp, minimum: '1.1.0'), isNull);
      expect(of(iosApp, minimum: '1.0', storeUrl: appStoreUrl), isNull);
      expect(of(androidApp), isNull);
    });

    test('Android: the policy store page, else the app on Google Play', () {
      expect(of(androidApp, minimum: '1.2.0', storeUrl: 'https://example.test/readin.apk')?.storeUrl,
          'https://example.test/readin.apk');
      expect(of(androidApp, minimum: '1.2.0')?.storeUrl, playStoreUrl);
      expect(of(androidApp, minimum: '1.2.0', storeUrl: '  ')?.storeUrl, playStoreUrl);
    });

    test('iOS: the policy store page, else no button', () {
      expect(of(iosApp, minimum: '1.2.0', storeUrl: appStoreUrl), const UpdateRequirement(storeUrl: appStoreUrl));
      expect(of(iosApp, minimum: '1.2.0'), const UpdateRequirement());
    });

    test('each platform follows its own minimum', () {
      const policy = UpdatePolicy(android: PlatformUpdatePolicy(minimumVersion: '2.0.0'));
      expect(UpdateRequirement.of(policy, androidApp), isNotNull);
      expect(UpdateRequirement.of(policy, iosApp), isNull);
    });
  });

  group('the saved policy', () {
    test('comes back as it was saved', () async {
      final store = InMemoryKeyValueStore();
      final cache = UpdatePolicyCache(store);
      expect(cache.read(), isNull);

      await cache.write(UpdatePolicyModel.fromJson(policyJson));

      expect(UpdatePolicyCache(store).read()?.toEntity(), UpdatePolicyModel.fromJson(policyJson).toEntity());
    });

    test('anything unreadable counts as none', () {
      for (final raw in ['not json', '[1, 2]', '"text"', '{"ios": 3}', '{"android": {"minimumVersion": false}}']) {
        expect(UpdatePolicyCache(InMemoryKeyValueStore({UpdatePolicyCache.key: raw})).read(), isNull, reason: raw);
      }
    });
  });

  group('the repository', () {
    late InMemoryKeyValueStore store;

    AppUpdateRepositoryImpl repository(ScriptedAdapter adapter) {
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))..httpClientAdapter = adapter;
      return AppUpdateRepositoryImpl(AppUpdateApi(dio), UpdatePolicyCache(store), FakeInstalledApp());
    }

    setUp(() => store = InMemoryKeyValueStore());

    test('asks GET /app/update-policy and saves the answer', () async {
      final adapter = ScriptedAdapter((_) => (200, policyJson));
      final repo = repository(adapter);

      final result = await repo.fetchPolicy();

      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, '/app/update-policy');
      expect(result.valueOrNull, UpdatePolicyModel.fromJson(policyJson).toEntity());
      expect(repo.cachedPolicy(), result.valueOrNull);
      expect(await repo.installedApp(), androidApp);
    });

    test('offline, or an unreadable answer: an error, and the saved policy stays', () async {
      await repository(ScriptedAdapter((_) => (200, policyJson))).fetchPolicy();

      final offline = await repository(ScriptedAdapter((o) => throw DioException.connectionError(
            requestOptions: o,
            reason: 'offline',
          ))).fetchPolicy();
      final serverError = await repository(ScriptedAdapter((_) => (503, null))).fetchPolicy();
      final captivePortal = await repository(ScriptedAdapter((_) => (200, '<html>Sign in to the Wi-Fi</html>'))).fetchPolicy();
      final wrongShape = await repository(ScriptedAdapter((_) => (200, {'ios': 'all'}))).fetchPolicy();

      expect(offline.failureOrNull?.code, FailureCodes.networkOffline);
      expect(serverError.isOk, isFalse);
      expect(captivePortal.isOk, isFalse);
      expect(wrongShape.isOk, isFalse);
      expect(UpdatePolicyCache(store).read()?.toEntity(), UpdatePolicyModel.fromJson(policyJson).toEntity());
    });
  });
}
