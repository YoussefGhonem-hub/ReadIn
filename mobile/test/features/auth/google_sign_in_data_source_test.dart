import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/features/auth/data/datasources/google_sign_in_data_source.dart';
import 'package:readin/features/auth/domain/entities/external_credential.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockAccount extends Mock implements GoogleSignInAccount {}

void main() {
  late _MockGoogleSignIn google;
  late GoogleSignInDataSource source;

  setUp(() {
    google = _MockGoogleSignIn();
    when(() => google.initialize(clientId: any(named: 'clientId'), serverClientId: any(named: 'serverClientId')))
        .thenAnswer((_) async {});
    when(() => google.signOut()).thenAnswer((_) async {});
    source = GoogleSignInDataSource.withClient(google);
  });

  void chooseAccount({String? idToken = 'google-id-token'}) {
    final account = _MockAccount();
    when(() => account.authentication).thenReturn(GoogleSignInAuthentication(idToken: idToken));
    when(() => account.displayName).thenReturn('Mona Adel');
    when(() => google.authenticate()).thenAnswer((_) async => account);
  }

  void failWith(GoogleSignInExceptionCode code) =>
      when(() => google.authenticate()).thenThrow(GoogleSignInException(code: code));

  test('returns the chosen account ID token for the API', () async {
    chooseAccount();

    expect(
      await source.signInWithGoogle(),
      const ExternalCredential(provider: ExternalProvider.google, idToken: 'google-id-token', displayName: 'Mona Adel'),
    );
  });

  test('Android asks for a token issued to the web client', () async {
    chooseAccount();

    await source.signInWithGoogle();

    verify(() => google.initialize(clientId: null, serverClientId: GoogleSignInDataSource.serverClientId)).called(1);
  });

  test('iOS uses its own client', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    chooseAccount();

    await source.signInWithGoogle();

    verify(() => google.initialize(clientId: GoogleSignInDataSource.iosClientId, serverClientId: null)).called(1);
  });

  test('returns null when the user closes the picker', () async {
    failWith(GoogleSignInExceptionCode.canceled);

    expect(await source.signInWithGoogle(), isNull);
  });

  test('rethrows other Google failures', () async {
    failWith(GoogleSignInExceptionCode.clientConfigurationError);

    await expectLater(
      source.signInWithGoogle(),
      throwsA(isA<GoogleSignInException>().having((e) => e.code, 'code', GoogleSignInExceptionCode.clientConfigurationError)),
    );
  });

  test('fails when Google returns no ID token', () async {
    chooseAccount(idToken: null);

    await expectLater(source.signInWithGoogle(), throwsA(isA<GoogleSignInException>()));
  });

  test('initializes once, and again only after a failed initialize', () async {
    var calls = 0;
    when(() => google.initialize(clientId: any(named: 'clientId'), serverClientId: any(named: 'serverClientId')))
        .thenAnswer((_) async {
      if (++calls == 1) throw const GoogleSignInException(code: GoogleSignInExceptionCode.providerConfigurationError);
    });
    chooseAccount();

    await expectLater(source.signInWithGoogle(), throwsA(isA<GoogleSignInException>()));
    await source.signInWithGoogle();
    await source.signInWithGoogle();

    expect(calls, 2);
  });

  test('sign-out failures never reach the caller', () async {
    when(() => google.signOut()).thenThrow(const GoogleSignInException(code: GoogleSignInExceptionCode.unknownError));

    await expectLater(source.signOut(), completes);
  });
}
