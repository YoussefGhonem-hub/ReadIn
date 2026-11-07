import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/app_update/data/datasources/app_update_api.dart';
import 'package:readin/features/app_update/data/datasources/update_policy_cache.dart';
import 'package:readin/features/app_update/data/repositories/app_update_repository_impl.dart';
import 'package:readin/features/app_update/domain/entities/update_policy.dart';
import 'package:readin/features/app_update/domain/usecases/check_app_update.dart';
import 'package:readin/features/app_update/presentation/cubit/app_update_cubit.dart';

import '../../helpers/app_update_fakes.dart';
import '../../helpers/fake_auth.dart';

/// `GET /app/update-policy` answering with an Android minimum ([minimum]: null for none), or offline.
class PolicyServer {
  String? minimum = '1.0.0';
  String? storeUrl;
  bool offline = false;
  late final adapter = ScriptedAdapter((o) {
    if (offline) throw DioException.connectionError(requestOptions: o, reason: 'offline');
    return (
      200,
      {
        'android': {'minimumVersion': minimum, 'storeUrl': storeUrl},
        'ios': {'minimumVersion': null, 'storeUrl': null},
      },
    );
  });

  int get calls => adapter.requests.length;
}

void main() {
  late PolicyServer server;
  late InMemoryKeyValueStore store; // the device's storage, kept from one launch to the next
  late FakeInstalledApp installed;
  late DateTime now;

  setUp(() {
    server = PolicyServer();
    store = InMemoryKeyValueStore();
    installed = FakeInstalledApp(androidApp); // 1.1.0+7
    now = DateTime.utc(2026, 11, 7, 9);
  });

  /// The app as it starts: a new cubit over the same storage.
  AppUpdateCubit launch() {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))..httpClientAdapter = server.adapter;
    final repository = AppUpdateRepositoryImpl(AppUpdateApi(dio), UpdatePolicyCache(store), installed);
    final cubit = AppUpdateCubit(CheckAppUpdate(repository), clock: () => now);
    addTearDown(cubit.close);
    return cubit;
  }

  test('required: the server\'s minimum is above this version', () async {
    server.minimum = '1.2.0';
    final cubit = launch();

    await cubit.start();

    expect(cubit.state.mustUpdate, isTrue);
    expect(cubit.state.requirement, const UpdateRequirement(storeUrl: playStoreUrl));
    expect(server.calls, 1);
  });

  test('required by build: same version, an older build', () async {
    server
      ..minimum = '1.1.0+8'
      ..storeUrl = 'https://example.test/store';
    final cubit = launch();

    await cubit.start();

    expect(cubit.state.requirement, const UpdateRequirement(storeUrl: 'https://example.test/store'));
  });

  test('not required: this version is still supported', () async {
    for (final minimum in [null, '1.0.0', '1.1.0', '1.1.0+7', 'not-a-version']) {
      server.minimum = minimum;
      final cubit = launch();
      await cubit.start();
      expect(cubit.state.mustUpdate, isFalse, reason: minimum);
    }
  });

  test('offline at startup: the policy saved by an earlier launch still blocks', () async {
    server.minimum = '1.2.0';
    await launch().start(); // online: told to update, and the policy is saved
    server.offline = true;

    final offline = launch();
    final states = <AppUpdateState>[];
    offline.stream.listen(states.add);
    await offline.start();

    expect(offline.state.mustUpdate, isTrue);
    expect(states, [const AppUpdateState(requirement: UpdateRequirement(storeUrl: playStoreUrl))]);
  });

  test('offline with nothing saved: a network error never blocks', () async {
    server.offline = true;
    final cubit = launch();

    await cubit.start();

    expect(cubit.state.mustUpdate, isFalse);
  });

  test('a later answer lifts the block when the minimum was lowered; an error never does', () async {
    server.minimum = '1.2.0';
    final cubit = launch();
    await cubit.start();

    server.offline = true;
    now = now.add(const Duration(minutes: 31));
    await cubit.resumed();
    expect(cubit.state.mustUpdate, isTrue);

    server
      ..offline = false
      ..minimum = '1.0.0';
    now = now.add(const Duration(minutes: 31));
    await cubit.resumed();
    expect(cubit.state.mustUpdate, isFalse);

    server.offline = true;
    final next = launch();
    await next.start();
    expect(next.state.mustUpdate, isFalse, reason: 'the lowered minimum was saved');
  });

  test('back in the foreground: checks again at most once every 30 minutes', () async {
    final cubit = launch();
    await cubit.resumed(); // before start: nothing to repeat yet
    expect(server.calls, 0);

    await cubit.start();
    await cubit.start(); // once per launch
    expect(server.calls, 1);

    for (final (minutes, calls) in [(10, 1), (29, 1), (30, 2), (45, 2), (59, 2), (60, 3), (61, 3)]) {
      now = DateTime.utc(2026, 11, 7, 9).add(Duration(minutes: minutes));
      await cubit.resumed();
      expect(server.calls, calls, reason: 'at +$minutes min');
    }
  });

  test('a resume during a check does not start another', () async {
    final cubit = launch();
    final first = cubit.start();
    now = now.add(const Duration(hours: 1));
    await cubit.resumed();
    await first;
    expect(server.calls, 1);
  });

  test('not a phone: never asks the server and never blocks', () async {
    installed.app = null;
    server.minimum = '9.0.0';
    final cubit = launch();

    await cubit.start();

    expect(server.calls, 0);
    expect(cubit.state.mustUpdate, isFalse);
  });
}
