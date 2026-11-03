import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/auth/data/datasources/apple_sign_in_data_source.dart';
import 'package:readin/features/auth/domain/entities/external_credential.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

AuthorizationCredentialAppleID _credential({String? identityToken = 'apple-id-token', String? givenName, String? familyName}) =>
    AuthorizationCredentialAppleID(
      userIdentifier: '001234.abcd',
      givenName: givenName,
      familyName: familyName,
      authorizationCode: 'code',
      email: null,
      identityToken: identityToken,
      state: null,
    );

void main() {
  final requests = <({List<AppleIDAuthorizationScopes> scopes, String? nonce})>[];
  late AuthorizationCredentialAppleID response;
  late Object? error;

  AppleSignInDataSource source() => AppleSignInDataSource.withRequest(({required scopes, nonce}) async {
        requests.add((scopes: scopes, nonce: nonce));
        if (error != null) throw error!;
        return response;
      });

  setUp(() {
    requests.clear();
    response = _credential(givenName: 'Mona', familyName: 'Adel');
    error = null;
  });

  test('sends Apple the SHA-256 of the nonce and the API the raw nonce', () async {
    final credential = (await source().signInWithApple())!;

    expect(credential.provider, ExternalProvider.apple);
    expect(credential.idToken, 'apple-id-token');
    expect(credential.nonce, hasLength(32));
    expect(requests.single.nonce, sha256.convert(utf8.encode(credential.nonce!)).toString());
    expect(requests.single.scopes, [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName]);
  });

  test('uses a fresh nonce for every attempt', () async {
    final data = source();

    final first = await data.signInWithApple();
    final second = await data.signInWithApple();

    expect(first!.nonce, isNot(second!.nonce));
  });

  test('passes the name Apple shares on the first authorization', () async {
    expect((await source().signInWithApple())!.displayName, 'Mona Adel');

    response = _credential();
    expect((await source().signInWithApple())!.displayName, isNull);
  });

  test('returns null when the user cancels', () async {
    error = const SignInWithAppleAuthorizationException(code: AuthorizationErrorCode.canceled, message: 'canceled');

    expect(await source().signInWithApple(), isNull);
  });

  test('rethrows other Apple failures', () async {
    error = const SignInWithAppleAuthorizationException(code: AuthorizationErrorCode.failed, message: 'failed');

    await expectLater(source().signInWithApple(), throwsA(isA<SignInWithAppleAuthorizationException>()));
  });

  test('fails when Apple returns no identity token', () async {
    response = _credential(identityToken: null);

    await expectLater(source().signInWithApple(), throwsA(isA<SignInWithAppleAuthorizationException>()));
  });

  test('is offered on iOS only', () {
    expect(source().isSupported, isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(source().isSupported, isTrue);
  });
}
