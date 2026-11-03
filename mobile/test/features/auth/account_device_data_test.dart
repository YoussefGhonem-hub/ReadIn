import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/phone/countries.dart';
import 'package:readin/core/push/push_service.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/auth/data/datasources/account_device_data.dart';
import 'package:readin/features/auth/data/datasources/google_sign_in_data_source.dart';

class MockPushService extends Mock implements PushService {}

class MockGoogleSignIn extends Mock implements GoogleSignInDataSource {}

void main() {
  late MockPushService push;
  late MockGoogleSignIn google;
  late PhoneCountryMemory countries;
  late Directory temp;
  late int imageClears;

  AccountDeviceData build() => AccountDeviceData(
        push,
        google,
        countries,
        clearImages: () async => imageClears++,
        temporaryDirectory: () async => temp,
      );

  setUp(() async {
    push = MockPushService();
    google = MockGoogleSignIn();
    countries = PhoneCountryMemory(InMemoryKeyValueStore());
    await countries.remember('US'); // from the account's number
    imageClears = 0;
    temp = Directory.systemTemp.createTempSync('readin_account_');
    File('${temp.path}/My article.pdf').writeAsStringSync('%PDF');
    Directory('${temp.path}/image_picker').createSync();
    File('${temp.path}/image_picker/photo.jpg').writeAsStringSync('jpg');
    when(() => push.forgetDevice()).thenAnswer((_) async {});
    when(() => google.signOut()).thenAnswer((_) async {});
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('forgets the push token, the Google account, the phone country, images and temporary files', () async {
    await build().forget();

    verify(() => push.forgetDevice()).called(1);
    verify(() => google.signOut()).called(1);
    expect(countries.initial(deviceRegion: 'EG'), 'EG');
    expect(imageClears, 1);
    expect(temp.existsSync(), isTrue);
    expect(temp.listSync(), isEmpty);
  });

  test('every step runs even when one fails', () async {
    when(() => push.forgetDevice()).thenThrow(StateError('no Firebase'));

    await build().forget();

    verify(() => google.signOut()).called(1);
    expect(imageClears, 1);
    expect(temp.listSync(), isEmpty);
  });
}
