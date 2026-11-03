import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/security/credential_rules.dart';
import 'package:readin/features/auth/domain/entities/external_credential.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/usecases/auth_usecases.dart';
import 'package:readin/features/auth/presentation/cubit/delete_account_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/form_support.dart';

import '../../helpers/fixtures.dart';

class MockDeleteAccount extends Mock implements DeleteAccount {}

class MockConfirmWithLinkedProvider extends Mock implements ConfirmWithLinkedProvider {}

/// An account created with Google: no phone, password or PIN.
const googleOnly = Me(
  id: 'u-g',
  displayName: 'Mona',
  username: 'mona',
  hasPassword: false,
  hasRecoveryPin: false,
  externalLogins: [ExternalLogin(provider: 'google', email: 'mona@gmail.com')],
);

/// A phone account that also signs in with Apple.
const withApple = Me(
  id: 'u-a',
  phoneNumber: '+201001234567',
  displayName: 'Omar',
  username: 'omar',
  externalLogins: [ExternalLogin(provider: 'apple')],
);

const googleToken = ExternalCredential(provider: ExternalProvider.google, idToken: 'google-id-token');
const appleToken = ExternalCredential(
  provider: ExternalProvider.apple,
  idToken: 'apple-id-token',
  nonce: 'raw-nonce',
  authorizationCode: 'apple-authorization-code',
);

const wrongPassword = Failure(FailureCodes.authWrongPassword, statusCode: 400);
const appleNeeded = Failure(FailureCodes.authAppleConfirmationRequired, statusCode: 400);
const unavailable = Failure(FailureCodes.accountDeletionUnavailable, statusCode: 503);
const offline = Failure(FailureCodes.networkOffline);

void main() {
  late MockDeleteAccount delete;
  late MockConfirmWithLinkedProvider confirmWith;

  setUpAll(() {
    registerFallbackValue(ExternalProvider.google);
    registerFallbackValue(sampleMe);
    registerFallbackValue(appleToken);
  });

  setUp(() {
    delete = MockDeleteAccount();
    confirmWith = MockConfirmWithLinkedProvider();
    when(() => confirmWith.providersFor(any())).thenAnswer((invocation) {
      final me = invocation.positionalArguments.single as Me;
      return me.externalLogins.map((login) => login.kind).nonNulls.toList();
    });
    when(() => confirmWith.supports(any())).thenReturn(true);
  });

  DeleteAccountCubit build(Me me) => DeleteAccountCubit(delete, confirmWith)..load(me);

  /// Reads, ticks the box and asks for the final dialog.
  void readAndReview(DeleteAccountCubit cubit, {String password = 'secret-1'}) {
    cubit
      ..proceed()
      ..setUnderstood(true)
      ..review(password: password);
  }

  group('load', () {
    test('a password account confirms with its password, and with Apple when Apple is linked', () {
      expect(build(sampleMe).state, const DeleteAccountState());
      expect(build(withApple).state, const DeleteAccountState(providers: [ExternalProvider.apple]));
    });

    test('an account without a password confirms with each linked account this device can show', () {
      expect(build(googleOnly).state, const DeleteAccountState(hasPassword: false, providers: [ExternalProvider.google]));

      when(() => confirmWith.providersFor(any())).thenReturn(const []); // Apple-only, on Android
      expect(build(googleOnly).state.providers, isEmpty);
    });

    test('an unknown account (offline) confirms with the password', () {
      final cubit = DeleteAccountCubit(delete, confirmWith)..load(null);
      expect(cubit.state, const DeleteAccountState());
    });
  });

  group('password', () {
    test('needs "I understand" and the password before the final dialog', () {
      final cubit = build(sampleMe)..proceed();

      cubit.review(password: 'secret-1');
      expect(cubit.state.confirming, isFalse, reason: 'the box is not ticked');

      cubit
        ..setUnderstood(true)
        ..review(password: '');
      expect(cubit.state.passwordError, CredentialCodes.required);
      expect(cubit.state.confirming, isFalse);

      cubit.review(password: 'secret-1');
      expect(cubit.state.confirming, isTrue);
      expect(cubit.state.passwordError, isNull);
      verifyZeroInteractions(delete);
    });

    test('cancelling the final dialog deletes nothing', () {
      final cubit = build(sampleMe);
      readAndReview(cubit);

      cubit.cancelConfirmation();

      expect(cubit.state.confirming, isFalse);
      verifyZeroInteractions(delete);
    });

    blocTest<DeleteAccountCubit, DeleteAccountState>(
      '"Delete forever" sends the password and reports the deletion',
      setUp: () => when(() => delete(password: 'secret-1')).thenAnswer((_) async => const Ok(null)),
      build: () => build(sampleMe),
      act: (cubit) async {
        readAndReview(cubit);
        expect(await cubit.confirm(), isTrue);
      },
      skip: 3,
      expect: () => const [
        DeleteAccountState(step: DeleteAccountStep.confirm, understood: true),
        DeleteAccountState(step: DeleteAccountStep.confirm, understood: true, status: FormStatus.submitting),
        DeleteAccountState(step: DeleteAccountStep.confirm, understood: true, status: FormStatus.success),
      ],
      verify: (_) {
        verify(() => delete(password: 'secret-1')).called(1);
        verifyNever(() => confirmWith.using(any()));
      },
    );

    blocTest<DeleteAccountCubit, DeleteAccountState>(
      'a wrong password stays on the confirm step, on the field',
      setUp: () => when(() => delete(password: 'nope')).thenAnswer((_) async => const Err(wrongPassword)),
      build: () => build(sampleMe),
      act: (cubit) async {
        readAndReview(cubit, password: 'nope');
        expect(await cubit.confirm(), isFalse);
      },
      skip: 5,
      expect: () => const [
        DeleteAccountState(
          step: DeleteAccountStep.confirm,
          understood: true,
          passwordError: FailureCodes.authWrongPassword,
        ),
      ],
      verify: (cubit) => expect(cubit.state.canRetry, isFalse),
    );
  });

  group('Google / Apple', () {
    test('an account without a password deletes with the fresh token of the provider it confirmed with', () async {
      when(() => confirmWith.using(ExternalProvider.google)).thenAnswer((_) async => const Ok(googleToken));
      when(() => delete(external: googleToken)).thenAnswer((_) async => const Ok(null));
      final cubit = build(googleOnly)
        ..proceed()
        ..setUnderstood(true);

      cubit.review(password: '');
      expect(cubit.state.failure?.code, FailureCodes.authConfirmationRequired, reason: 'never on the session alone');

      await cubit.confirmWith(ExternalProvider.google);
      expect(cubit.state.confirmedWith, ExternalProvider.google);
      cubit.review(password: '');

      expect(await cubit.confirm(), isTrue);
      verify(() => delete(external: googleToken)).called(1);
    });

    test('Apple sends its authorization code with the token', () async {
      when(() => confirmWith.using(ExternalProvider.apple)).thenAnswer((_) async => const Ok(appleToken));
      when(() => delete(external: any(named: 'external'))).thenAnswer((_) async => const Ok(null));
      final cubit = build(withApple)..proceed();

      await cubit.confirmWith(ExternalProvider.apple);
      cubit
        ..setUnderstood(true)
        ..review(password: ''); // Apple replaces the password
      await cubit.confirm();

      final sent = verify(() => delete(external: captureAny(named: 'external'))).captured.single as ExternalCredential;
      expect(sent.provider, ExternalProvider.apple);
      expect(sent.authorizationCode, 'apple-authorization-code');
      expect(sent.nonce, 'raw-nonce');
      verifyNever(() => delete(password: any(named: 'password')));
    });

    blocTest<DeleteAccountCubit, DeleteAccountState>(
      'closing the provider sheet deletes nothing',
      setUp: () => when(() => confirmWith.using(ExternalProvider.google)).thenAnswer((_) async => const Ok(null)),
      build: () => build(googleOnly),
      act: (cubit) => cubit.confirmWith(ExternalProvider.google),
      expect: () => const [
        DeleteAccountState(hasPassword: false, providers: [ExternalProvider.google], busyProvider: ExternalProvider.google),
        DeleteAccountState(hasPassword: false, providers: [ExternalProvider.google]),
      ],
      verify: (_) => verifyZeroInteractions(delete),
    );

    test('another Google account, or a token the API rejects, must confirm again', () async {
      when(() => confirmWith.using(ExternalProvider.google)).thenAnswer((_) async => const Ok(googleToken));
      when(() => delete(external: googleToken))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.authExternalMismatch, statusCode: 400)));
      final cubit = build(googleOnly)
        ..proceed()
        ..setUnderstood(true);
      await cubit.confirmWith(ExternalProvider.google);
      cubit.review(password: '');

      expect(await cubit.confirm(), isFalse);

      expect(cubit.state.failure?.code, FailureCodes.authExternalMismatch);
      expect(cubit.state.confirmedWith, isNull);
      expect(cubit.state.canDelete, isFalse);
      expect(cubit.state.step, DeleteAccountStep.confirm);
    });
  });

  group('auth.apple_confirmation_required', () {
    test("opens Apple's sheet by itself and sends a fresh Apple confirmation with its code", () async {
      when(() => delete(password: 'secret-1')).thenAnswer((_) async => const Err(appleNeeded));
      when(() => confirmWith.using(ExternalProvider.apple)).thenAnswer((_) async => const Ok(appleToken));
      when(() => delete(external: appleToken)).thenAnswer((_) async => const Ok(null));
      final cubit = build(withApple);
      readAndReview(cubit);

      expect(await cubit.confirm(), isTrue);

      verifyInOrder([
        () => delete(password: 'secret-1'),
        () => confirmWith.using(ExternalProvider.apple),
        () => delete(external: appleToken),
      ]);
      expect(cubit.state.deleted, isTrue);
    });

    test('closing the Apple sheet says why Apple is needed and offers it', () async {
      when(() => delete(password: 'secret-1')).thenAnswer((_) async => const Err(appleNeeded));
      when(() => confirmWith.using(ExternalProvider.apple)).thenAnswer((_) async => const Ok(null));
      final cubit = build(sampleMe); // Apple linked on the server but not yet in this copy of the account
      readAndReview(cubit);

      expect(await cubit.confirm(), isFalse);

      expect(cubit.state.failure, appleNeeded);
      expect(cubit.state.providers, [ExternalProvider.apple]);
      expect(cubit.state.busy, isFalse);
      verify(() => delete(password: 'secret-1')).called(1);
    });

    test('without Sign in with Apple here (Android) it points to the iPhone app or email', () async {
      when(() => confirmWith.supports(ExternalProvider.apple)).thenReturn(false);
      when(() => delete(password: 'secret-1')).thenAnswer((_) async => const Err(appleNeeded));
      final cubit = build(withApple);
      readAndReview(cubit);

      expect(await cubit.confirm(), isFalse);

      expect(cubit.state.failure?.code, FailureCodes.authAppleUnavailable);
      verifyNever(() => confirmWith.using(any()));
    });

    test('a fresh Apple confirmation that is still refused is not asked again in a loop', () async {
      when(() => confirmWith.using(ExternalProvider.apple)).thenAnswer((_) async => const Ok(appleToken));
      when(() => delete(external: appleToken)).thenAnswer((_) async => const Err(appleNeeded));
      final cubit = build(withApple)..proceed();
      await cubit.confirmWith(ExternalProvider.apple);
      cubit
        ..setUnderstood(true)
        ..review(password: '');

      expect(await cubit.confirm(), isFalse);

      expect(cubit.state.failure, appleNeeded);
      verify(() => confirmWith.using(ExternalProvider.apple)).called(1);
      verify(() => delete(external: appleToken)).called(1);
    });
  });

  group('errors', () {
    test('503: nothing was deleted; Retry sends the same request again', () async {
      final answers = [const Err<void>(unavailable), const Ok<void>(null)];
      when(() => delete(password: 'secret-1')).thenAnswer((_) async => answers.removeAt(0));
      final cubit = build(sampleMe);
      readAndReview(cubit);

      expect(await cubit.confirm(), isFalse);
      expect(cubit.state.failure, unavailable);
      expect(cubit.state.canRetry, isTrue);
      expect(cubit.state.deleted, isFalse, reason: 'a failure never looks like success');

      expect(await cubit.retry(), isTrue);
      expect(cubit.state.deleted, isTrue);
      verify(() => delete(password: 'secret-1')).called(2);
    });

    test('offline: a clear error with Retry, and no request is queued for later', () async {
      when(() => delete(password: 'secret-1')).thenAnswer((_) async => const Err(offline));
      final cubit = build(sampleMe);
      readAndReview(cubit);

      expect(await cubit.confirm(), isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.failure, offline);
      expect(cubit.state.canRetry, isTrue);
      expect(cubit.state.submitting, isFalse);
      verify(() => delete(password: 'secret-1')).called(1);
      verifyNoMoreInteractions(delete);
    });

    test('429: try again later, without Retry', () async {
      when(() => delete(password: 'secret-1'))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.rateLimited, statusCode: 429)));
      final cubit = build(sampleMe);
      readAndReview(cubit);

      await cubit.confirm();

      expect(cubit.state.failure?.code, FailureCodes.rateLimited);
      expect(cubit.state.canRetry, isFalse);
      expect(await cubit.retry(), isFalse);
      verify(() => delete(password: 'secret-1')).called(1);
    });

    test('401: the session had already ended', () async {
      when(() => delete(password: 'secret-1'))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.authUnauthorized, statusCode: 401)));
      final cubit = build(sampleMe);
      readAndReview(cubit);

      await cubit.confirm();

      expect(cubit.state.sessionEnded, isTrue);
      expect(const DeleteAccountState(failure: Failure(FailureCodes.authExternalInvalid, statusCode: 401)).sessionEnded, isFalse);
    });

    test('back to "what happens" forgets the confirmation', () async {
      when(() => confirmWith.using(ExternalProvider.google)).thenAnswer((_) async => const Ok(googleToken));
      final cubit = build(googleOnly)..proceed();
      await cubit.confirmWith(ExternalProvider.google);
      cubit.setUnderstood(true);

      cubit.back();

      expect(cubit.state, const DeleteAccountState(hasPassword: false, providers: [ExternalProvider.google]));
    });
  });
}
