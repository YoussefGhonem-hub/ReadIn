import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/auth/data/datasources/auth_api.dart';
import 'package:readin/features/auth/data/datasources/auth_session_store.dart';
import 'package:readin/features/auth/data/datasources/fresh_install_check.dart';

import '../../helpers/fake_auth.dart';

class MockAuthApi extends Mock implements AuthApi {}

/// A Keychain that can't be reached yet (e.g. before the first unlock).
class LockedSecureStore extends FakeSecureStore {
  LockedSecureStore(super.values);

  @override
  Future<void> delete(String key) async => throw StateError('locked');
}

void main() {
  /// What an earlier install left in the Keychain (iOS keeps it after the app is deleted).
  Map<String, String> leftInKeychain() => {
        AuthSessionStore.refreshTokenKey: 'r-old',
        AuthSessionStore.retryKeyKey: '${AuthSessionStore.tokenTag('r-old')}:k-old',
        'other.secret': 'kept',
      };

  test('the first launch of a new install forgets the session an earlier install left, then marks the install', () async {
    final store = InMemoryKeyValueStore();
    final secure = FakeSecureStore(leftInKeychain());

    expect(await FreshInstallCheck(store, secure).run(), isTrue);

    expect(secure.values, {'other.secret': 'kept'});
    expect(store.read<bool>(FreshInstallCheck.markerKey), isTrue);
    expect((await AuthSessionStore(MockAuthApi(), secure).refresh()).valueOrNull, isNull, reason: 'starts signed out');
  });

  test('an update from a build without the marker keeps the session: the store already holds its data', () async {
    for (final earlier in [
      {'settings.welcomeSeen': true, 'settings.theme': 'dark'},
      {'phone.lastCountry': 'EG'},
      {'search.recent': '["flutter"]'},
    ]) {
      final store = InMemoryKeyValueStore(earlier);
      final secure = FakeSecureStore(leftInKeychain());

      expect(await FreshInstallCheck(store, secure).run(), isFalse);

      expect(secure.values, leftInKeychain(), reason: '$earlier');
      expect(store.read<bool>(FreshInstallCheck.markerKey), isTrue);
    }
  });

  test('later launches of the same install never sign out', () async {
    final store = InMemoryKeyValueStore();
    final secure = FakeSecureStore();
    final check = FreshInstallCheck(store, secure);
    await check.run();
    secure.values[AuthSessionStore.refreshTokenKey] = 'r1'; // signed in meanwhile

    expect(await check.run(), isFalse);
    expect(await FreshInstallCheck(store, secure).run(), isFalse);

    expect(secure.values, {AuthSessionStore.refreshTokenKey: 'r1'});
  });

  test('a Keychain that cannot be reached yet: the next launch forgets the session, even with settings saved by then',
      () async {
    final store = InMemoryKeyValueStore();

    expect(await FreshInstallCheck(store, LockedSecureStore(leftInKeychain())).run(), isFalse);
    expect(store.read<bool>(FreshInstallCheck.markerKey), isFalse);

    await store.write('settings.welcomeSeen', true);
    final secure = FakeSecureStore(leftInKeychain());
    expect(await FreshInstallCheck(store, secure).run(), isTrue);

    expect(secure.values, {'other.secret': 'kept'});
    expect(store.read<bool>(FreshInstallCheck.markerKey), isTrue);
  });
}
