import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/current_locale.dart';
import 'package:readin/core/phone/countries.dart';
import 'package:readin/core/security/credential_rules.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/auth/domain/entities/auth_config.dart';
import 'package:readin/features/auth/domain/entities/external_credential.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/repositories/auth_repository.dart';
import 'package:readin/features/auth/domain/repositories/external_identity_repository.dart';
import 'package:readin/features/auth/domain/usecases/auth_usecases.dart';
import 'package:readin/features/auth/presentation/cubit/external_sign_in_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/form_support.dart';
import 'package:readin/features/auth/presentation/cubit/linked_accounts_cubit.dart';

import '../../helpers/fixtures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockIdentities extends Mock implements ExternalIdentityRepository {}

class MockObtain extends Mock implements ObtainExternalCredential {}

class MockSignInWithExternal extends Mock implements SignInWithExternal {}

class MockConfirmWithLinkedProvider extends Mock implements ConfirmWithLinkedProvider {}

class MockLinkExternalLogin extends Mock implements LinkExternalLogin {}

class MockUnlinkExternalLogin extends Mock implements UnlinkExternalLogin {}

class MockGetExternalProviders extends Mock implements GetExternalProviders {}

class FixedLocale extends Mock implements CurrentLocale {}

const google = ExternalCredential(provider: ExternalProvider.google, idToken: 'google-id-token');
const apple = ExternalCredential(provider: ExternalProvider.apple, idToken: 'apple-id-token', nonce: 'raw');
const notLinked = Failure(FailureCodes.authExternalNotLinked, statusCode: 404);

const googleOnly = Me(
  id: 'u-g',
  displayName: 'Mona',
  username: 'mona',
  hasPassword: false,
  externalLogins: [ExternalLogin(provider: 'google', email: 'mona@gmail.com')],
);

void main() {
  setUpAll(() => registerFallbackValue(google));

  group('GetExternalProviders / ConfirmWithLinkedProvider', () {
    late MockAuthRepository auth;
    late MockIdentities identities;

    setUp(() {
      auth = MockAuthRepository();
      identities = MockIdentities();
      when(() => identities.supports(ExternalProvider.google)).thenReturn(true);
      when(() => identities.supports(ExternalProvider.apple)).thenReturn(false); // Android
    });

    test('show only what the server configured and this device can do', () async {
      when(() => auth.getConfig())
          .thenAnswer((_) async => const AuthConfig(externalProviders: [ExternalProvider.google, ExternalProvider.apple]));
      expect(await GetExternalProviders(auth, identities)(), [ExternalProvider.google]);

      when(() => auth.getConfig()).thenAnswer((_) async => AuthConfig.defaults);
      expect(await GetExternalProviders(auth, identities)(), isEmpty);
    });

    test('confirm with a linked provider this device can show', () async {
      when(() => identities.obtain(ExternalProvider.google)).thenAnswer((_) async => const Ok(google));
      final confirm = ConfirmWithLinkedProvider(identities);

      expect((await confirm(googleOnly)).valueOrNull, google);

      const appleOnly = Me(id: 'u-a', displayName: 'A', username: 'a', hasPassword: false, externalLogins: [
        ExternalLogin(provider: 'apple'),
      ]);
      expect(confirm.providerFor(appleOnly), isNull);
      expect((await confirm(appleOnly)).failureOrNull?.code, FailureCodes.authConfirmationRequired);
    });
  });

  group('ExternalSignInCubit', () {
    late MockGetExternalProviders providers;
    late MockObtain obtain;
    late MockSignInWithExternal signIn;
    late FixedLocale locale;
    late PhoneCountryMemory countries;

    setUp(() {
      providers = MockGetExternalProviders();
      obtain = MockObtain();
      signIn = MockSignInWithExternal();
      locale = FixedLocale();
      countries = PhoneCountryMemory(InMemoryKeyValueStore());
      when(() => locale.languageCode).thenReturn('ar');
      when(() => providers()).thenAnswer((_) async => [ExternalProvider.google, ExternalProvider.apple]);
    });

    ExternalSignInCubit build() => ExternalSignInCubit(providers, obtain, signIn, locale, countries);

    const ready = ExternalSignInState(providers: [ExternalProvider.google, ExternalProvider.apple]);
    const busyGoogle = ExternalSignInState(
      providers: [ExternalProvider.google, ExternalProvider.apple],
      status: FormStatus.submitting,
      busy: ExternalProvider.google,
    );

    blocTest<ExternalSignInCubit, ExternalSignInState>(
      'loads the buttons',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => const [ready],
    );

    blocTest<ExternalSignInCubit, ExternalSignInState>(
      'closing the provider sheet changes nothing',
      setUp: () => when(() => obtain(ExternalProvider.google)).thenAnswer((_) async => const Ok(null)),
      build: build,
      seed: () => ready,
      act: (cubit) => cubit.start(ExternalProvider.google),
      expect: () => const [busyGoogle, ready],
      verify: (_) => verifyNever(() => signIn(any(), uiLanguage: any(named: 'uiLanguage'))),
    );

    blocTest<ExternalSignInCubit, ExternalSignInState>(
      'a linked identity signs in',
      setUp: () {
        when(() => obtain(ExternalProvider.apple)).thenAnswer((_) async => const Ok(apple));
        when(() => signIn(apple, uiLanguage: 'ar')).thenAnswer((_) async => const Ok(sampleMe));
      },
      build: build,
      seed: () => ready,
      act: (cubit) => cubit.start(ExternalProvider.apple),
      skip: 1,
      expect: () => const [
        ExternalSignInState(providers: [ExternalProvider.google, ExternalProvider.apple], status: FormStatus.success),
      ],
    );

    blocTest<ExternalSignInCubit, ExternalSignInState>(
      'a provider failure shows under the buttons',
      setUp: () => when(() => obtain(ExternalProvider.google))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.authExternalProviderFailed))),
      build: build,
      seed: () => ready,
      act: (cubit) => cubit.start(ExternalProvider.google),
      skip: 1,
      expect: () => const [
        ExternalSignInState(
          providers: [ExternalProvider.google, ExternalProvider.apple],
          failure: Failure(FailureCodes.authExternalProviderFailed),
        ),
      ],
    );

    blocTest<ExternalSignInCubit, ExternalSignInState>(
      'a new identity asks how to continue, then creates the account',
      setUp: () {
        when(() => obtain(ExternalProvider.google)).thenAnswer((_) async => const Ok(google));
        when(() => signIn(google, uiLanguage: 'ar')).thenAnswer((_) async => const Err(notLinked));
        when(() => signIn(google, uiLanguage: 'ar', createAccount: true)).thenAnswer((_) async => const Ok(sampleMe));
      },
      build: build,
      seed: () => ready,
      act: (cubit) async {
        await cubit.start(ExternalProvider.google);
        await cubit.createAccount();
      },
      skip: 1,
      expect: () => const [
        ExternalSignInState(providers: [ExternalProvider.google, ExternalProvider.apple], notLinked: google),
        ExternalSignInState(
          providers: [ExternalProvider.google, ExternalProvider.apple],
          status: FormStatus.submitting,
          busy: ExternalProvider.google,
          notLinked: google,
        ),
        ExternalSignInState(
          providers: [ExternalProvider.google, ExternalProvider.apple],
          status: FormStatus.success,
          notLinked: google,
        ),
      ],
    );

    blocTest<ExternalSignInCubit, ExternalSignInState>(
      '"I already have an account" validates, maps a wrong password, then links and signs in',
      setUp: () {
        when(() => signIn(google, uiLanguage: 'ar', link: (phoneNumber: '+201001234567', password: 'nope')))
            .thenAnswer((_) async => const Err(Failure(FailureCodes.authInvalidCredentials, statusCode: 401)));
        when(() => signIn(google, uiLanguage: 'ar', link: (phoneNumber: '+201001234567', password: 'right-1')))
            .thenAnswer((_) async => const Ok(sampleMe));
      },
      build: build,
      seed: () => const ExternalSignInState(notLinked: google),
      act: (cubit) async {
        await cubit.link(phoneE164: null, phoneEmpty: true, password: '');
        await cubit.link(phoneE164: '+201001234567', phoneEmpty: false, password: 'nope');
        await cubit.link(phoneE164: '+201001234567', phoneEmpty: false, password: 'right-1');
      },
      expect: () => const [
        ExternalSignInState(
          notLinked: google,
          linkErrors: {Fields.phone: CredentialCodes.required, Fields.password: CredentialCodes.required},
        ),
        ExternalSignInState(notLinked: google, status: FormStatus.submitting),
        ExternalSignInState(notLinked: google, linkFailure: Failure(FailureCodes.authInvalidCredentials, statusCode: 401)),
        ExternalSignInState(notLinked: google, status: FormStatus.submitting),
        ExternalSignInState(notLinked: google, status: FormStatus.success),
      ],
      verify: (_) => expect(countries.initial(deviceRegion: 'US'), 'EG'),
    );
  });

  group('LinkedAccountsCubit', () {
    late MockGetExternalProviders providers;
    late MockObtain obtain;
    late MockConfirmWithLinkedProvider confirmWith;
    late MockLinkExternalLogin link;
    late MockUnlinkExternalLogin unlink;

    setUp(() {
      providers = MockGetExternalProviders();
      obtain = MockObtain();
      confirmWith = MockConfirmWithLinkedProvider();
      link = MockLinkExternalLogin();
      unlink = MockUnlinkExternalLogin();
      when(() => providers()).thenAnswer((_) async => [ExternalProvider.google, ExternalProvider.apple]);
    });

    LinkedAccountsCubit build() => LinkedAccountsCubit(providers, obtain, confirmWith, link, unlink);
    const both = [ExternalProvider.google, ExternalProvider.apple];

    blocTest<LinkedAccountsCubit, LinkedAccountsState>(
      'with a password: the provider sheet, then the password dialog, then the link',
      setUp: () {
        when(() => obtain(ExternalProvider.google)).thenAnswer((_) async => const Ok(google));
        when(() => link(google, password: 'secret-1')).thenAnswer((_) async => const Ok(sampleMe));
      },
      build: build,
      seed: () => const LinkedAccountsState(providers: both),
      act: (cubit) async {
        await cubit.link(ExternalProvider.google, sampleMe);
        await cubit.confirmWithPassword('secret-1');
      },
      expect: () => const [
        LinkedAccountsState(providers: both, busy: ExternalProvider.google),
        LinkedAccountsState(providers: both, awaitingPassword: ExternalProvider.google),
        LinkedAccountsState(providers: both, busy: ExternalProvider.google),
        LinkedAccountsState(providers: both, change: (provider: ExternalProvider.google, linked: true)),
      ],
    );

    blocTest<LinkedAccountsCubit, LinkedAccountsState>(
      'cancelling the password dialog links nothing',
      setUp: () => when(() => obtain(ExternalProvider.google)).thenAnswer((_) async => const Ok(google)),
      build: build,
      seed: () => const LinkedAccountsState(providers: both),
      act: (cubit) async {
        await cubit.link(ExternalProvider.google, sampleMe);
        await cubit.confirmWithPassword(null);
      },
      skip: 2,
      expect: () => const [LinkedAccountsState(providers: both)],
      verify: (_) => verifyNever(() => link(any(), password: any(named: 'password'))),
    );

    blocTest<LinkedAccountsCubit, LinkedAccountsState>(
      'without a password: a linked provider confirms',
      setUp: () {
        when(() => obtain(ExternalProvider.apple)).thenAnswer((_) async => const Ok(apple));
        when(() => confirmWith(googleOnly)).thenAnswer((_) async => const Ok(google));
        when(() => link(apple, external: google)).thenAnswer((_) async => const Ok(googleOnly));
      },
      build: build,
      seed: () => const LinkedAccountsState(providers: both),
      act: (cubit) => cubit.link(ExternalProvider.apple, googleOnly),
      expect: () => const [
        LinkedAccountsState(providers: both, busy: ExternalProvider.apple),
        LinkedAccountsState(providers: both, change: (provider: ExternalProvider.apple, linked: true)),
      ],
    );

    blocTest<LinkedAccountsCubit, LinkedAccountsState>(
      'the last way to sign in is not unlinked',
      setUp: () => when(() => unlink(ExternalProvider.google))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.authLastSignInMethod, statusCode: 400))),
      build: build,
      seed: () => const LinkedAccountsState(providers: both),
      act: (cubit) => cubit.unlink(ExternalProvider.google),
      expect: () => const [
        LinkedAccountsState(providers: both, busy: ExternalProvider.google),
        LinkedAccountsState(providers: both, failure: Failure(FailureCodes.authLastSignInMethod, statusCode: 400)),
      ],
    );
  });
}
