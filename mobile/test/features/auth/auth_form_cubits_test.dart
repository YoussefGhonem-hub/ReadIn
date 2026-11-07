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
import 'package:readin/features/auth/domain/usecases/auth_usecases.dart';
import 'package:readin/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/form_support.dart';
import 'package:readin/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/sign_up_cubit.dart';

import '../../helpers/fixtures.dart';

class MockSignIn extends Mock implements SignIn {}

class MockRegister extends Mock implements Register {}

class MockGetAuthConfig extends Mock implements GetAuthConfig {}

class MockVerifyRecoveryPin extends Mock implements VerifyRecoveryPin {}

class MockResetPassword extends Mock implements ResetPassword {}

const phone = '+201001234567';

Failure validation(Map<String, List<String>> errors) =>
    Failure(FailureCodes.validationFailed, statusCode: 400, fieldErrors: errors);

void main() {
  late PhoneCountryMemory countries;
  late MockGetAuthConfig config;

  setUp(() {
    countries = PhoneCountryMemory(InMemoryKeyValueStore());
    config = MockGetAuthConfig();
    when(() => config()).thenAnswer((_) async => AuthConfig.defaults);
  });

  group('SignInCubit', () {
    late MockSignIn signIn;
    setUp(() => signIn = MockSignIn());

    blocTest<SignInCubit, SignInState>(
      'validates the number and the password before calling the API',
      build: () => SignInCubit(signIn, countries),
      act: (cubit) async {
        await cubit.submit(phoneE164: null, phoneEmpty: true, password: '');
        await cubit.submit(phoneE164: null, phoneEmpty: false, password: 'x');
      },
      expect: () => const [
        SignInState(errors: {Fields.phone: CredentialCodes.required, Fields.password: CredentialCodes.required}),
        SignInState(errors: {Fields.phone: CredentialCodes.phoneInvalid}),
      ],
      verify: (_) => verifyNever(() => signIn(phoneNumber: any(named: 'phoneNumber'), password: any(named: 'password'))),
    );

    blocTest<SignInCubit, SignInState>(
      'signs in and remembers the country',
      setUp: () => when(() => signIn(phoneNumber: phone, password: 'reading4life')).thenAnswer((_) async => const Ok(sampleMe)),
      build: () => SignInCubit(signIn, countries),
      act: (cubit) => cubit.submit(phoneE164: phone, phoneEmpty: false, password: 'reading4life'),
      expect: () => const [SignInState(status: FormStatus.submitting), SignInState(status: FormStatus.success)],
      verify: (_) => expect(countries.initial(deviceRegion: 'US'), 'EG'),
    );

    for (final code in ['auth.invalid_credentials', 'auth.locked_out', 'user.suspended', 'rate_limited']) {
      blocTest<SignInCubit, SignInState>(
        'shows $code for the whole form',
        setUp: () => when(() => signIn(phoneNumber: phone, password: 'reading4life'))
            .thenAnswer((_) async => Err(Failure(code, statusCode: 401))),
        build: () => SignInCubit(signIn, countries),
        act: (cubit) => cubit.submit(phoneE164: phone, phoneEmpty: false, password: 'reading4life'),
        skip: 1,
        expect: () => [SignInState(failure: Failure(code, statusCode: 401))],
      );
    }

    test('ignores a second submit while the first is running (no double submit)', () async {
      when(() => signIn(phoneNumber: phone, password: 'p')).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const Ok(sampleMe);
      });
      final cubit = SignInCubit(signIn, countries);
      await Future.wait([
        cubit.submit(phoneE164: phone, phoneEmpty: false, password: 'p'),
        cubit.submit(phoneE164: phone, phoneEmpty: false, password: 'p'),
      ]);
      verify(() => signIn(phoneNumber: phone, password: 'p')).called(1);
      await cubit.close();
    });
  });

  group('SignUpCubit', () {
    late MockRegister register;
    setUp(() => register = MockRegister());

    SignUpCubit build() => SignUpCubit(register, config, CurrentLocale(), countries);

    blocTest<SignUpCubit, SignUpState>(
      'step 1 checks the number, the password rules and the confirmation',
      build: build,
      act: (cubit) => cubit
        ..submitCredentials(phoneE164: null, phoneEmpty: false, password: 'short', confirmPassword: 'other')
        ..submitCredentials(phoneE164: phone, phoneEmpty: false, password: 'x1001234567', confirmPassword: 'x1001234567'),
      expect: () => const [
        SignUpState(errors: {
          Fields.phone: CredentialCodes.phoneInvalid,
          Fields.password: CredentialCodes.passwordTooShort,
          Fields.confirmPassword: CredentialCodes.passwordMismatch,
        }),
        SignUpState(errors: {Fields.password: CredentialCodes.passwordContainsPhone}),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'step 2 accepts any digits (1234 included), live and on submit, and rejects mismatched PINs',
      build: build,
      act: (cubit) => cubit
        ..submitCredentials(phoneE164: phone, phoneEmpty: false, password: 'reading4life', confirmPassword: 'reading4life')
        ..pinChanged('12')
        ..pinChanged('12a4')
        ..pinChanged('1234')
        ..submitPin(pin: '1234', confirmPin: '1235')
        ..submitPin(pin: '1234', confirmPin: '1234'),
      expect: () => const [
        SignUpState(step: SignUpStep.pin, phone: phone),
        SignUpState(step: SignUpStep.pin, phone: phone, errors: {Fields.pin: CredentialCodes.pinDigitsOnly}),
        SignUpState(step: SignUpStep.pin, phone: phone),
        SignUpState(step: SignUpStep.pin, phone: phone, errors: {Fields.confirmPin: CredentialCodes.pinMismatch}),
        SignUpState(step: SignUpStep.pin, phone: phone, confirming: true),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      'the PIN may repeat the first digits of the password: it is registered as typed',
      setUp: () => when(() => register(phoneNumber: phone, password: '7391reading', recoveryPin: '7391', uiLanguage: 'ar'))
          .thenAnswer((_) async => const Ok(sampleMe)),
      build: build,
      act: (cubit) async {
        cubit
          ..submitCredentials(phoneE164: phone, phoneEmpty: false, password: '7391reading', confirmPassword: '7391reading')
          ..submitPin(pin: '٧٣٩١', confirmPin: '7391');
        await cubit.register();
      },
      skip: 1,
      expect: () => const [
        SignUpState(step: SignUpStep.pin, phone: phone, confirming: true),
        SignUpState(step: SignUpStep.pin, phone: phone, status: FormStatus.submitting),
        SignUpState(step: SignUpStep.pin, phone: phone, status: FormStatus.success),
      ],
      verify: (_) => verify(() => register(phoneNumber: phone, password: '7391reading', recoveryPin: '7391', uiLanguage: 'ar')).called(1),
    );

    blocTest<SignUpCubit, SignUpState>(
      'confirms the number, then registers with the normalized PIN',
      setUp: () => when(() => register(phoneNumber: phone, password: 'reading4life', recoveryPin: '4831', uiLanguage: 'ar'))
          .thenAnswer((_) async => const Ok(sampleMe)),
      build: build,
      act: (cubit) async {
        cubit
          ..submitCredentials(phoneE164: phone, phoneEmpty: false, password: 'reading4life', confirmPassword: 'reading4life')
          ..submitPin(pin: '٤٨٣١', confirmPin: '4831');
        await cubit.register();
      },
      expect: () => const [
        SignUpState(step: SignUpStep.pin, phone: phone),
        SignUpState(step: SignUpStep.pin, phone: phone, confirming: true),
        SignUpState(step: SignUpStep.pin, phone: phone, status: FormStatus.submitting),
        SignUpState(step: SignUpStep.pin, phone: phone, status: FormStatus.success),
      ],
    );

    blocTest<SignUpCubit, SignUpState>(
      '"تعديل" goes back to the number',
      build: build,
      act: (cubit) => cubit
        ..submitCredentials(phoneE164: phone, phoneEmpty: false, password: 'reading4life', confirmPassword: 'reading4life')
        ..submitPin(pin: '4831', confirmPin: '4831')
        ..editNumber(),
      skip: 2,
      expect: () => const [SignUpState(phone: phone)],
    );

    blocTest<SignUpCubit, SignUpState>(
      'auth.phone_taken goes back to step 1 with the Sign in action',
      setUp: () => when(() => register(
            phoneNumber: any(named: 'phoneNumber'),
            password: any(named: 'password'),
            recoveryPin: any(named: 'recoveryPin'),
            uiLanguage: any(named: 'uiLanguage'),
          )).thenAnswer((_) async => const Err(Failure(FailureCodes.authPhoneTaken, statusCode: 409))),
      build: build,
      act: (cubit) async {
        cubit
          ..submitCredentials(phoneE164: phone, phoneEmpty: false, password: 'reading4life', confirmPassword: 'reading4life')
          ..submitPin(pin: '4831', confirmPin: '4831');
        await cubit.register();
      },
      skip: 3,
      verify: (cubit) => expect(cubit.state.phoneTaken, isTrue),
      expect: () => const [SignUpState(phone: phone, errors: {Fields.phone: FailureCodes.authPhoneTaken})],
    );

    blocTest<SignUpCubit, SignUpState>(
      'maps server validation errors to their step',
      setUp: () => when(() => register(
            phoneNumber: any(named: 'phoneNumber'),
            password: any(named: 'password'),
            recoveryPin: any(named: 'recoveryPin'),
            uiLanguage: any(named: 'uiLanguage'),
          )).thenAnswer((_) async => Err(validation({'recoveryPin': ['pin.length']}))),
      build: build,
      act: (cubit) async {
        cubit
          ..submitCredentials(phoneE164: phone, phoneEmpty: false, password: 'reading4life', confirmPassword: 'reading4life')
          ..submitPin(pin: '4831', confirmPin: '4831');
        await cubit.register();
      },
      skip: 3,
      expect: () => const [SignUpState(step: SignUpStep.pin, phone: phone, errors: {Fields.pin: CredentialCodes.pinLength})],
    );

    blocTest<SignUpCubit, SignUpState>(
      'uses the PIN length from /auth/config',
      setUp: () => when(() => config()).thenAnswer((_) async => const AuthConfig(pinLength: 6)),
      build: build,
      act: (cubit) async {
        await cubit.loadConfig();
        cubit
          ..submitCredentials(phoneE164: phone, phoneEmpty: false, password: 'reading4life', confirmPassword: 'reading4life')
          ..submitPin(pin: '4831', confirmPin: '4831');
      },
      skip: 2,
      expect: () => const [
        SignUpState(
          step: SignUpStep.pin,
          phone: phone,
          config: AuthConfig(pinLength: 6),
          errors: {Fields.pin: CredentialCodes.pinLength},
        ),
      ],
    );
  });

  group('ForgotPasswordCubit', () {
    late MockVerifyRecoveryPin verifyPin;
    late MockResetPassword reset;
    setUp(() {
      verifyPin = MockVerifyRecoveryPin();
      reset = MockResetPassword();
    });

    ForgotPasswordCubit build() => ForgotPasswordCubit(verifyPin, reset, config);

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'step 1 needs the number and every PIN digit; any digits are sent (1234 included)',
      setUp: () => when(() => verifyPin(phoneNumber: phone, pin: '1234')).thenAnswer((_) async => const Ok('token')),
      build: build,
      act: (cubit) async {
        await cubit.submitVerification(phoneE164: null, phoneEmpty: true, pin: '12');
        await cubit.submitVerification(phoneE164: phone, phoneEmpty: false, pin: '١٢٣٤');
      },
      expect: () => const [
        ForgotPasswordState(errors: {Fields.phone: CredentialCodes.required, Fields.pin: CredentialCodes.pinLength}),
        ForgotPasswordState(status: FormStatus.submitting),
        ForgotPasswordState(step: ForgotStep.newPassword, phone: phone),
      ],
    );

    for (final code in ['auth.recovery_invalid', 'auth.recovery_locked', 'auth.recovery_disabled']) {
      blocTest<ForgotPasswordCubit, ForgotPasswordState>(
        'shows $code',
        setUp: () => when(() => verifyPin(phoneNumber: phone, pin: '4831')).thenAnswer((_) async => Err(Failure(code))),
        build: build,
        act: (cubit) => cubit.submitVerification(phoneE164: phone, phoneEmpty: false, pin: '4831'),
        skip: 1,
        expect: () => [ForgotPasswordState(failure: Failure(code))],
      );
    }

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'step 2 resets the password and ends with the number for Sign in',
      setUp: () {
        when(() => verifyPin(phoneNumber: phone, pin: '4831')).thenAnswer((_) async => const Ok('token'));
        when(() => reset(resetToken: 'token', newPassword: 'reading4life')).thenAnswer((_) async => const Ok(null));
      },
      build: build,
      act: (cubit) async {
        await cubit.submitVerification(phoneE164: phone, phoneEmpty: false, pin: '4831');
        await cubit.submitNewPassword(password: 'reading4life', confirmPassword: 'nope');
        await cubit.submitNewPassword(password: 'reading4life', confirmPassword: 'reading4life');
      },
      skip: 2,
      expect: () => const [
        ForgotPasswordState(step: ForgotStep.newPassword, phone: phone, errors: {Fields.confirmPassword: CredentialCodes.passwordMismatch}),
        ForgotPasswordState(step: ForgotStep.newPassword, phone: phone, status: FormStatus.submitting),
        ForgotPasswordState(step: ForgotStep.done, phone: phone, status: FormStatus.success),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'an expired reset token goes back to step 1 ("انتهت المهلة، ابدأ من الأول")',
      setUp: () {
        when(() => verifyPin(phoneNumber: phone, pin: '4831')).thenAnswer((_) async => const Ok('token'));
        when(() => reset(resetToken: 'token', newPassword: 'reading4life'))
            .thenAnswer((_) async => const Err(Failure(FailureCodes.authResetTokenInvalid, statusCode: 400)));
      },
      build: build,
      act: (cubit) async {
        await cubit.submitVerification(phoneE164: phone, phoneEmpty: false, pin: '4831');
        await cubit.submitNewPassword(password: 'reading4life', confirmPassword: 'reading4life');
      },
      skip: 3,
      expect: () => const [
        ForgotPasswordState(phone: phone, failure: Failure(FailureCodes.authResetTokenInvalid, statusCode: 400)),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'new password rules errors from the server go to the field',
      setUp: () {
        when(() => verifyPin(phoneNumber: phone, pin: '4831')).thenAnswer((_) async => const Ok('token'));
        when(() => reset(resetToken: 'token', newPassword: 'reading4life'))
            .thenAnswer((_) async => Err(validation({'newPassword': ['password.too_common']})));
      },
      build: build,
      act: (cubit) async {
        await cubit.submitVerification(phoneE164: phone, phoneEmpty: false, pin: '4831');
        await cubit.submitNewPassword(password: 'reading4life', confirmPassword: 'reading4life');
      },
      skip: 3,
      expect: () => const [
        ForgotPasswordState(step: ForgotStep.newPassword, phone: phone, errors: {Fields.password: 'password.too_common'}),
      ],
    );
  });
}
