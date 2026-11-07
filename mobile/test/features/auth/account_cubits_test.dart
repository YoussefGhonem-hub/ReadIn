import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/phone/countries.dart';
import 'package:readin/core/security/credential_rules.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/auth/domain/entities/auth_config.dart';
import 'package:readin/features/auth/domain/entities/external_credential.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/usecases/auth_usecases.dart';
import 'package:readin/features/auth/presentation/cubit/account_security_cubits.dart';
import 'package:readin/features/auth/presentation/cubit/complete_profile_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/form_support.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/media/domain/usecases/media_usecases.dart';

import '../../helpers/fixtures.dart';

class MockGetAuthConfig extends Mock implements GetAuthConfig {}

class MockSetRecoveryPin extends Mock implements SetRecoveryPin {}

class MockChangeRecoveryPin extends Mock implements ChangeRecoveryPin {}

class MockChangePassword extends Mock implements ChangePassword {}

class MockChangePhoneNumber extends Mock implements ChangePhoneNumber {}

class MockConfirmWithLinkedProvider extends Mock implements ConfirmWithLinkedProvider {}

class MockAddPhoneSignIn extends Mock implements AddPhoneSignIn {}

class MockCompleteProfile extends Mock implements CompleteProfile {}

class MockCheckUsername extends Mock implements CheckUsername {}

class MockPickImages extends Mock implements PickImages {}

class MockUploadImage extends Mock implements UploadImage {}

const phone = '+201001234567';
const wrongPassword = Failure(FailureCodes.authWrongPassword, statusCode: 400);
const lockedOut = Failure(FailureCodes.authLockedOut, statusCode: 429);

/// An account created with Google: no phone, password or PIN.
const googleOnly = Me(
  id: 'u-g',
  displayName: 'Mona',
  username: 'mona',
  hasPassword: false,
  hasRecoveryPin: false,
  externalLogins: [ExternalLogin(provider: 'google', email: 'mona@gmail.com')],
);
const googleToken = ExternalCredential(provider: ExternalProvider.google, idToken: 'google-id-token');

void main() {
  late MockGetAuthConfig config;

  setUpAll(() {
    registerFallbackValue(const PickedMediaFile(path: 'a.jpg', name: 'a.jpg', sizeBytes: 1));
    registerFallbackValue(sampleMe);
    registerFallbackValue(googleToken);
  });

  setUp(() {
    config = MockGetAuthConfig();
    when(() => config()).thenAnswer((_) async => AuthConfig.defaults);
  });

  group('SetRecoveryPinCubit', () {
    late MockSetRecoveryPin setPin;
    setUp(() => setPin = MockSetRecoveryPin());

    blocTest<SetRecoveryPinCubit, AccountFormState>(
      'accepts the last digits of the phone number live and saves them; only non-digits are flagged',
      setUp: () => when(() => setPin('4567')).thenAnswer((_) async => const Ok(sampleMe)),
      build: () => SetRecoveryPinCubit(config, setPin),
      act: (cubit) async {
        cubit
          ..pinChanged('45a7')
          ..pinChanged('4567'); // the last digits of +201001234567
        await cubit.submit(pin: '4567', confirmPin: '4567');
      },
      expect: () => const [
        AccountFormState(errors: {Fields.pin: CredentialCodes.pinDigitsOnly}),
        AccountFormState(),
        AccountFormState(status: FormStatus.submitting),
        AccountFormState(status: FormStatus.success),
      ],
      verify: (_) => verify(() => setPin('4567')).called(1),
    );
  });

  group('ChangeRecoveryPinCubit', () {
    late MockChangeRecoveryPin changePin;
    setUp(() => changePin = MockChangeRecoveryPin());

    blocTest<ChangeRecoveryPinCubit, AccountFormState>(
      'needs the current password; 1111 is accepted and sent; a wrong password is shown on that field',
      setUp: () => when(() => changePin(currentPassword: 'nope', newPin: '1111')).thenAnswer((_) async => const Err(wrongPassword)),
      build: () => ChangeRecoveryPinCubit(config, changePin),
      act: (cubit) async {
        await cubit.submit(currentPassword: '', pin: '1111', confirmPin: '');
        await cubit.submit(currentPassword: 'nope', pin: '1111', confirmPin: '1111');
      },
      expect: () => const [
        AccountFormState(errors: {
          Fields.currentPassword: CredentialCodes.required,
          Fields.confirmPin: CredentialCodes.required,
        }),
        AccountFormState(status: FormStatus.submitting),
        AccountFormState(errors: {Fields.currentPassword: FailureCodes.authWrongPassword}),
      ],
    );
  });

  group('ChangePasswordCubit', () {
    late MockChangePassword change;
    setUp(() => change = MockChangePassword());

    blocTest<ChangePasswordCubit, AccountFormState>(
      'checks the rules, then maps a lockout to the whole form',
      setUp: () => when(() => change(currentPassword: 'old-pass1', newPassword: 'reading4life')).thenAnswer((_) async => const Err(lockedOut)),
      build: () => ChangePasswordCubit(config, change),
      act: (cubit) async {
        await cubit.submit(currentPassword: 'old-pass1', newPassword: 'abcdefgh', confirmPassword: 'abcdefgh');
        await cubit.submit(currentPassword: 'old-pass1', newPassword: 'reading4life', confirmPassword: 'reading4life');
      },
      expect: () => const [
        AccountFormState(errors: {Fields.password: CredentialCodes.passwordDigitRequired}),
        AccountFormState(status: FormStatus.submitting),
        AccountFormState(failure: lockedOut),
      ],
    );

    blocTest<ChangePasswordCubit, AccountFormState>(
      'succeeds',
      setUp: () => when(() => change(currentPassword: 'old-pass1', newPassword: 'reading4life')).thenAnswer((_) async => const Ok(sampleMe)),
      build: () => ChangePasswordCubit(config, change),
      act: (cubit) => cubit.submit(currentPassword: 'old-pass1', newPassword: 'reading4life', confirmPassword: 'reading4life'),
      expect: () => const [AccountFormState(status: FormStatus.submitting), AccountFormState(status: FormStatus.success)],
    );
  });

  group('ChangePhoneCubit', () {
    late MockChangePhoneNumber change;
    late PhoneCountryMemory countries;
    setUp(() {
      change = MockChangePhoneNumber();
      countries = PhoneCountryMemory(InMemoryKeyValueStore());
    });

    blocTest<ChangePhoneCubit, AccountFormState>(
      'refuses the current number, then asks to confirm the new one',
      build: () => ChangePhoneCubit(config, change, countries),
      act: (cubit) => cubit
        ..review(phoneE164: '+12025550110', phoneEmpty: false, currentPassword: 'x', currentPhone: '+12025550110')
        ..review(phoneE164: phone, phoneEmpty: false, currentPassword: 'secret-1', currentPhone: '+12025550110'),
      expect: () => const [
        AccountFormState(errors: {Fields.phone: FailureCodes.authPhoneUnchanged}),
        AccountFormState(confirming: true),
      ],
    );

    blocTest<ChangePhoneCubit, AccountFormState>(
      'auth.phone_taken lands on the number',
      setUp: () => when(() => change(newPhoneNumber: phone, currentPassword: 'secret-1'))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.authPhoneTaken, statusCode: 409))),
      build: () => ChangePhoneCubit(config, change, countries),
      act: (cubit) async {
        cubit.review(phoneE164: phone, phoneEmpty: false, currentPassword: 'secret-1', currentPhone: '+12025550110');
        await cubit.confirm();
      },
      skip: 2,
      expect: () => const [AccountFormState(errors: {Fields.phone: FailureCodes.authPhoneTaken})],
    );

    blocTest<ChangePhoneCubit, AccountFormState>(
      'changes the number',
      setUp: () => when(() => change(newPhoneNumber: phone, currentPassword: 'secret-1')).thenAnswer((_) async => const Ok(sampleMe)),
      build: () => ChangePhoneCubit(config, change, countries),
      act: (cubit) async {
        cubit.review(phoneE164: phone, phoneEmpty: false, currentPassword: 'secret-1', currentPhone: '+12025550110');
        await cubit.confirm();
      },
      skip: 2,
      expect: () => const [AccountFormState(status: FormStatus.success)],
      verify: (_) => expect(countries.initial(deviceRegion: 'US'), 'EG'),
    );
  });

  group('AddPhoneSignInCubit', () {
    late MockAddPhoneSignIn add;
    late MockConfirmWithLinkedProvider confirmWith;
    late PhoneCountryMemory countries;
    setUp(() {
      add = MockAddPhoneSignIn();
      confirmWith = MockConfirmWithLinkedProvider();
      countries = PhoneCountryMemory(InMemoryKeyValueStore());
    });

    void review(AddPhoneSignInCubit cubit, {String pin = '4831', String confirmPin = '4831'}) => cubit.review(
          phoneE164: phone,
          phoneEmpty: false,
          password: 'reading4life',
          confirmPassword: 'reading4life',
          pin: pin,
          confirmPin: confirmPin,
        );

    blocTest<AddPhoneSignInCubit, AccountFormState>(
      'checks the PIN length and confirmation, then asks to confirm the number; 1234 is accepted and sent',
      setUp: () {
        when(() => confirmWith(googleOnly)).thenAnswer((_) async => const Ok(googleToken));
        when(() => add(phoneNumber: phone, password: 'reading4life', recoveryPin: '1234', external: googleToken))
            .thenAnswer((_) async => const Ok(sampleMe));
      },
      build: () => AddPhoneSignInCubit(config, add, confirmWith, countries),
      act: (cubit) async {
        review(cubit, pin: '123', confirmPin: '123');
        review(cubit, pin: '1234', confirmPin: '1230');
        review(cubit, pin: '1234', confirmPin: '1234');
        await cubit.confirm(googleOnly);
      },
      expect: () => const [
        AccountFormState(errors: {Fields.pin: CredentialCodes.pinLength}),
        AccountFormState(errors: {Fields.confirmPin: CredentialCodes.pinMismatch}),
        AccountFormState(confirming: true),
        AccountFormState(status: FormStatus.submitting),
        AccountFormState(status: FormStatus.success),
      ],
      verify: (_) => verify(() => add(phoneNumber: phone, password: 'reading4life', recoveryPin: '1234', external: googleToken)).called(1),
    );

    blocTest<AddPhoneSignInCubit, AccountFormState>(
      'confirms with the linked provider, then adds the phone sign in',
      setUp: () {
        when(() => confirmWith(googleOnly)).thenAnswer((_) async => const Ok(googleToken));
        when(() => add(phoneNumber: phone, password: 'reading4life', recoveryPin: '4831', external: googleToken))
            .thenAnswer((_) async => const Ok(sampleMe));
      },
      build: () => AddPhoneSignInCubit(config, add, confirmWith, countries),
      act: (cubit) async {
        review(cubit);
        await cubit.confirm(googleOnly);
      },
      skip: 1,
      expect: () => const [
        AccountFormState(status: FormStatus.submitting),
        AccountFormState(status: FormStatus.success),
      ],
      verify: (_) => expect(countries.initial(deviceRegion: 'US'), 'EG'),
    );

    blocTest<AddPhoneSignInCubit, AccountFormState>(
      'auth.phone_taken lands on the number',
      setUp: () {
        when(() => confirmWith(googleOnly)).thenAnswer((_) async => const Ok(googleToken));
        when(() => add(phoneNumber: phone, password: 'reading4life', recoveryPin: '4831', external: googleToken))
            .thenAnswer((_) async => const Err(Failure(FailureCodes.authPhoneTaken, statusCode: 409)));
      },
      build: () => AddPhoneSignInCubit(config, add, confirmWith, countries),
      act: (cubit) async {
        review(cubit);
        await cubit.confirm(googleOnly);
      },
      skip: 2,
      expect: () => const [AccountFormState(errors: {Fields.phone: FailureCodes.authPhoneTaken})],
    );

    blocTest<AddPhoneSignInCubit, AccountFormState>(
      'shows why the provider could not confirm',
      setUp: () => when(() => confirmWith(googleOnly))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.authExternalProviderFailed))),
      build: () => AddPhoneSignInCubit(config, add, confirmWith, countries),
      act: (cubit) async {
        review(cubit);
        await cubit.confirm(googleOnly);
      },
      skip: 2,
      expect: () => const [AccountFormState(failure: Failure(FailureCodes.authExternalProviderFailed))],
    );
  });

  group('CompleteProfileCubit', () {
    late MockCompleteProfile complete;
    late MockCheckUsername check;
    late MockPickImages pick;
    late MockUploadImage upload;

    setUp(() {
      complete = MockCompleteProfile();
      check = MockCheckUsername();
      pick = MockPickImages();
      upload = MockUploadImage();
    });

    CompleteProfileCubit build() => CompleteProfileCubit(complete, check, pick, upload);

    test('does not offer the placeholder handle from sign up', () {
      const placeholder = Me(id: 'u', displayName: 'reader_ab12cd34ef', username: 'reader_ab12cd34ef', isProfileComplete: false);
      expect(CompleteProfileCubit.initialUsername(placeholder), '');
      expect(CompleteProfileCubit.initialDisplayName(placeholder), '');
      expect(CompleteProfileCubit.initialUsername(sampleMe), 'reader1');
    });

    testWidgets('checks the username once typing pauses, and ignores stale answers', (tester) async {
      when(() => check('youssef')).thenAnswer((_) async => const Ok(UsernameAvailability(username: 'youssef', valid: true, available: false)));
      when(() => check('youssef_h')).thenAnswer((_) async => const Ok(UsernameAvailability(username: 'youssef_h', valid: true, available: true)));
      final cubit = build();
      cubit.usernameChanged('Yo');
      expect(cubit.state.usernameStatus, UsernameStatus.invalid);
      cubit
        ..usernameChanged('youssef')
        ..usernameChanged('youssef_h');
      expect(cubit.state.usernameStatus, UsernameStatus.checking);
      await tester.pump(CompleteProfileCubit.debounce);
      await tester.pump();
      verifyNever(() => check('youssef'));
      expect(cubit.state.usernameStatus, UsernameStatus.available);

      cubit.usernameChanged('youssef');
      await tester.pump(CompleteProfileCubit.debounce);
      await tester.pump();
      expect(cubit.state.usernameStatus, UsernameStatus.taken);
      await cubit.close();
    });

    blocTest<CompleteProfileCubit, CompleteProfileState>(
      'validates the name and a taken username before saving',
      build: build,
      seed: () => const CompleteProfileState(username: 'youssef', usernameStatus: UsernameStatus.taken),
      act: (cubit) => cubit.submit(displayName: ' Y '),
      expect: () => const [
        CompleteProfileState(
          username: 'youssef',
          usernameStatus: UsernameStatus.taken,
          errors: {Fields.displayName: FailureCodes.validationMinLength, Fields.username: FailureCodes.usernameTaken},
        ),
      ],
    );

    blocTest<CompleteProfileCubit, CompleteProfileState>(
      'uploads the avatar with purpose avatar and saves the profile with it',
      setUp: () {
        when(() => pick(limit: 1)).thenAnswer((_) async => const [PickedMediaFile(path: 'me.jpg', name: 'me.jpg', sizeBytes: 10)]);
        when(() => upload(any(), purpose: 'avatar')).thenAnswer((_) async => const Ok(MediaAsset(
              id: 'm1',
              kind: MediaKind.image,
              status: MediaStatus.ready,
              variants: [
                MediaVariant(width: 64, height: 64, url: 'https://api.test/uploads/a64.webp'),
                MediaVariant(width: 256, height: 256, url: 'https://api.test/uploads/a256.webp'),
                MediaVariant(width: 512, height: 512, url: 'https://api.test/uploads/a512.webp'),
              ],
            )));
        when(() => complete(displayName: 'Youssef', username: 'youssef_h', avatarUrl: 'https://api.test/uploads/a256.webp'))
            .thenAnswer((_) async => const Ok(sampleMe));
      },
      build: build,
      seed: () => const CompleteProfileState(username: 'youssef_h', usernameStatus: UsernameStatus.available),
      act: (cubit) async {
        await cubit.pickAvatar();
        await cubit.submit(displayName: 'Youssef');
      },
      expect: () => const [
        CompleteProfileState(username: 'youssef_h', usernameStatus: UsernameStatus.available, uploadingAvatar: true),
        CompleteProfileState(username: 'youssef_h', usernameStatus: UsernameStatus.available, avatarUrl: 'https://api.test/uploads/a256.webp'),
        CompleteProfileState(
          username: 'youssef_h',
          usernameStatus: UsernameStatus.available,
          avatarUrl: 'https://api.test/uploads/a256.webp',
          status: FormStatus.submitting,
        ),
        CompleteProfileState(
          username: 'youssef_h',
          usernameStatus: UsernameStatus.available,
          avatarUrl: 'https://api.test/uploads/a256.webp',
          status: FormStatus.success,
        ),
      ],
    );

    blocTest<CompleteProfileCubit, CompleteProfileState>(
      'the optional title (F14): one line of at most 120 characters, checked before saving',
      build: build,
      seed: () => const CompleteProfileState(username: 'youssef_h', usernameStatus: UsernameStatus.available),
      act: (cubit) async {
        await cubit.submit(displayName: 'Youssef', headline: 'x' * 121);
        await cubit.submit(displayName: 'Youssef', headline: 'Flutter\nEngineer');
      },
      expect: () => const [
        CompleteProfileState(
          username: 'youssef_h',
          usernameStatus: UsernameStatus.available,
          errors: {CompleteProfileCubit.headlineField: FailureCodes.profileHeadlineTooLong},
        ),
        CompleteProfileState(
          username: 'youssef_h',
          usernameStatus: UsernameStatus.available,
          errors: {CompleteProfileCubit.headlineField: FailureCodes.profileHeadlineInvalid},
        ),
      ],
      verify: (_) => verifyNever(() => complete(
            displayName: any(named: 'displayName'),
            username: any(named: 'username'),
            avatarUrl: any(named: 'avatarUrl'),
            headline: any(named: 'headline'),
          )),
    );

    blocTest<CompleteProfileCubit, CompleteProfileState>(
      'saves the title trimmed; a blank one is left out; a server error lands on the field',
      setUp: () {
        when(() => complete(displayName: 'Youssef', username: 'youssef_h', headline: 'Flutter Engineer | Dart'))
            .thenAnswer((_) async => const Err(Failure(
                  FailureCodes.validationFailed,
                  statusCode: 400,
                  fieldErrors: {'headline': [FailureCodes.profileHeadlineInvalid]},
                )));
      },
      build: build,
      seed: () => const CompleteProfileState(username: 'youssef_h', usernameStatus: UsernameStatus.available),
      act: (cubit) => cubit.submit(displayName: 'Youssef', headline: '  Flutter Engineer | Dart '),
      skip: 1,
      expect: () => const [
        CompleteProfileState(
          username: 'youssef_h',
          usernameStatus: UsernameStatus.available,
          errors: {CompleteProfileCubit.headlineField: FailureCodes.profileHeadlineInvalid},
        ),
      ],
    );

    blocTest<CompleteProfileCubit, CompleteProfileState>(
      'user.username_taken from the server marks the handle as taken',
      setUp: () => when(() => complete(displayName: 'Youssef', username: 'youssef', avatarUrl: null))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.usernameTaken, statusCode: 409))),
      build: build,
      seed: () => const CompleteProfileState(username: 'youssef', usernameStatus: UsernameStatus.available),
      act: (cubit) => cubit.submit(displayName: 'Youssef'),
      skip: 1,
      expect: () => const [
        CompleteProfileState(
          username: 'youssef',
          usernameStatus: UsernameStatus.taken,
          errors: {Fields.username: FailureCodes.usernameTaken},
        ),
      ],
    );
  });
}
