@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/phone/countries.dart';
import 'package:readin/core/security/credential_rules.dart';
import 'package:readin/features/auth/domain/entities/external_credential.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/cubit/account_security_cubits.dart';
import 'package:readin/features/auth/presentation/cubit/complete_profile_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/delete_account_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/external_sign_in_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/form_support.dart';
import 'package:readin/features/auth/presentation/cubit/linked_accounts_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/sign_up_cubit.dart';
import 'package:readin/features/auth/presentation/pages/account_pages.dart';
import 'package:readin/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:readin/features/auth/presentation/pages/delete_account_page.dart';
import 'package:readin/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:readin/features/auth/presentation/pages/link_external_account_page.dart';
import 'package:readin/features/auth/presentation/pages/sign_in_page.dart';
import 'package:readin/features/auth/presentation/pages/sign_up_page.dart';
import 'package:readin/features/auth/presentation/pages/welcome_page.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:readin/features/auth/presentation/widgets/dev_login_panel.dart';
import 'package:readin/features/auth/presentation/widgets/external_sign_in.dart';
import 'package:readin/features/profile/presentation/cubit/privacy_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/features/settings/presentation/pages/settings_page.dart';
import 'package:readin/shared/widgets/inputs/country_picker.dart';

import '../helpers/test_app.dart';

class MockSessionCubit extends MockCubit<SessionState> implements SessionCubit {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockSignInCubit extends MockCubit<SignInState> implements SignInCubit {}

class MockSignUpCubit extends MockCubit<SignUpState> implements SignUpCubit {}

class MockForgotPasswordCubit extends MockCubit<ForgotPasswordState> implements ForgotPasswordCubit {}

class MockCompleteProfileCubit extends MockCubit<CompleteProfileState> implements CompleteProfileCubit {}

class MockSetRecoveryPinCubit extends MockCubit<AccountFormState> implements SetRecoveryPinCubit {}

class MockChangePasswordCubit extends MockCubit<AccountFormState> implements ChangePasswordCubit {}

class MockChangeRecoveryPinCubit extends MockCubit<AccountFormState> implements ChangeRecoveryPinCubit {}

class MockChangePhoneCubit extends MockCubit<AccountFormState> implements ChangePhoneCubit {}

class MockDeleteAccountCubit extends MockCubit<DeleteAccountState> implements DeleteAccountCubit {}

class MockAddPhoneSignInCubit extends MockCubit<AccountFormState> implements AddPhoneSignInCubit {}

class MockExternalSignInCubit extends MockCubit<ExternalSignInState> implements ExternalSignInCubit {}

class MockLinkedAccountsCubit extends MockCubit<LinkedAccountsState> implements LinkedAccountsCubit {}

class MockPrivacyCubit extends MockCubit<PrivacyState> implements PrivacyCubit {}

const bothProviders = [ExternalProvider.google, ExternalProvider.apple];

/// An account created with Google: no phone, password or PIN yet.
final googleOnly = Me(
  id: 'u-3',
  displayName: 'منى عادل',
  username: 'mona',
  onboardingCompleted: true,
  hasPassword: false,
  hasRecoveryPin: false,
  externalLogins: [ExternalLogin(provider: 'google', email: 'mona.adel@gmail.com', linkedAt: DateTime.utc(2026, 11, 3))],
);

const reader = Me(
  id: 'u-1',
  phoneNumber: '+201001234567',
  displayName: 'يوسف حسن',
  username: 'youssef',
  onboardingCompleted: true,
);

const newAccount = Me(
  id: 'u-2',
  phoneNumber: '+201001234567',
  displayName: 'reader_ab12cd34ef',
  username: 'reader_ab12cd34ef',
  isProfileComplete: false,
);

extension Seed<S> on MockCubit<S> {
  void seed(S state) => whenListen(this, Stream<S>.empty(), initialState: state);
}

/// Auth and account screens (SPEC §9.2, F18) in the 4 mandatory variants: ar/en × light/dark (SPEC §8.2).
void main() {
  late MockSessionCubit session;
  late MockSettingsCubit settings;

  setUp(() {
    session = MockSessionCubit();
    settings = MockSettingsCubit();
    whenListen(
      session,
      const Stream<SessionState>.empty(),
      initialState: const SessionState(status: SessionStatus.authenticated, me: reader),
    );
    whenListen(settings, const Stream<AppSettings>.empty(), initialState: const AppSettings(welcomeSeen: true));
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Variant variant,
    Widget child, {
    List<BlocProvider> providers = const [],
  }) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<SettingsCubit>.value(value: settings),
            ...providers,
          ],
          child: child,
        ),
        variant: variant,
      ),
    );
    await tester.pump();
  }

  /// Unfocuses (no blinking caret), lets the bundled flag SVGs decode off the fake clock and finishes animations
  /// (floating labels, the strength meter). [spinning]: a progress indicator never settles, so just step past them.
  Future<void> settle(WidgetTester tester, {bool spinning = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    if (spinning) {
      await tester.pump(const Duration(milliseconds: 400));
    } else {
      await tester.pumpAndSettle();
    }
  }

  Future<void> expectGolden(WidgetTester tester, String name, Variant variant, {bool spinning = false}) async {
    await settle(tester, spinning: spinning);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${name}_${variant.name}.png'));
  }

  for (final variant in Variant.all) {
    testWidgets('welcome ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const WelcomeView(),
        providers: [BlocProvider<ExternalSignInCubit>.value(value: MockExternalSignInCubit()..seed(const ExternalSignInState()))],
      );
      await expectGolden(tester, 'auth_welcome', variant);
    });

    testWidgets('welcome with Google and Apple ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const WelcomeView(),
        providers: [
          BlocProvider<ExternalSignInCubit>.value(
            value: MockExternalSignInCubit()..seed(const ExternalSignInState(providers: bothProviders)),
          ),
        ],
      );
      await expectGolden(tester, 'auth_welcome_external', variant);
    });

    testWidgets('sign in with Google and Apple ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const SignInView(alternatives: [ExternalSignInButtons()]),
        providers: [
          BlocProvider<SignInCubit>.value(value: MockSignInCubit()..seed(const SignInState())),
          BlocProvider<ExternalSignInCubit>.value(
            value: MockExternalSignInCubit()
              ..seed(const ExternalSignInState(
                providers: bothProviders,
                status: FormStatus.submitting,
                busy: ExternalProvider.apple,
              )),
          ),
        ],
      );
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await expectGolden(tester, 'auth_sign_in_external', variant, spinning: true);
    });

    testWidgets('not linked yet ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(onPressed: () => showExternalNotLinkedSheet(context), child: const Text('open')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'auth_external_not_linked', variant);
    });

    testWidgets('link to a phone account ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const LinkExternalAccountView(),
        providers: [
          BlocProvider<ExternalSignInCubit>.value(
            value: MockExternalSignInCubit()
              ..seed(const ExternalSignInState(
                notLinked: ExternalCredential(provider: ExternalProvider.google, idToken: 't'),
                linkFailure: Failure(FailureCodes.authExternalConflict, statusCode: 409),
              )),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField).first, '01001234567');
      await expectGolden(tester, 'auth_link_external', variant);
    });

    testWidgets('sign in ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const SignInView(),
        providers: [BlocProvider<SignInCubit>.value(value: MockSignInCubit()..seed(const SignInState()))],
      );
      await expectGolden(tester, 'auth_sign_in', variant);
    });

    testWidgets('sign in error ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const SignInView(),
        providers: [
          BlocProvider<SignInCubit>.value(
            value: MockSignInCubit()
              ..seed(const SignInState(failure: Failure(FailureCodes.authLockedOut, statusCode: 429))),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField).first, '01001234567');
      await expectGolden(tester, 'auth_sign_in_locked', variant);
    });

    testWidgets('sign in after a reset ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const SignInView(args: SignInArgs(phone: '+12025550110', passwordReset: true)),
        providers: [
          BlocProvider<SignInCubit>.value(
            value: MockSignInCubit()..seed(const SignInState(status: FormStatus.submitting)),
          ),
        ],
      );
      await expectGolden(tester, 'auth_sign_in_reset_submitting', variant, spinning: true);
    });

    testWidgets('sign up, step 1 ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const SignUpView(),
        providers: [
          BlocProvider<SignUpCubit>.value(
            value: MockSignUpCubit()
              ..seed(const SignUpState(errors: {Fields.confirmPassword: CredentialCodes.passwordMismatch})),
          ),
        ],
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '01001234567');
      await tester.enterText(fields.at(1), 'reading4life');
      await tester.enterText(fields.at(2), 'reading4lif');
      await expectGolden(tester, 'auth_sign_up_credentials', variant);
    });

    testWidgets('sign up, number taken ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const SignUpView(),
        providers: [
          BlocProvider<SignUpCubit>.value(
            value: MockSignUpCubit()
              ..seed(const SignUpState(phone: '+201001234567', errors: {Fields.phone: FailureCodes.authPhoneTaken})),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField).first, '01001234567');
      await expectGolden(tester, 'auth_sign_up_phone_taken', variant);
    });

    testWidgets('sign up, step 2 ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const SignUpView(),
        providers: [
          BlocProvider<SignUpCubit>.value(
            value: MockSignUpCubit()
              ..seed(
                const SignUpState(
                  step: SignUpStep.pin,
                  phone: '+201001234567',
                  errors: {Fields.pin: CredentialCodes.pinWeak},
                ),
              ),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.pump();
      await expectGolden(tester, 'auth_sign_up_pin', variant);
    });

    testWidgets('confirm your number ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showConfirmNumberDialog(
                  context,
                  phoneE164: '+201001234567',
                  confirmLabel: context.l10n.confirmNumberYes,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'auth_confirm_number', variant);
    });

    testWidgets('complete profile ${variant.name}', (tester) async {
      whenListen(
        session,
        const Stream<SessionState>.empty(),
        initialState: const SessionState(status: SessionStatus.authenticated, me: newAccount),
      );
      await pumpScreen(
        tester,
        variant,
        const CompleteProfileView(),
        providers: [
          BlocProvider<CompleteProfileCubit>.value(
            value: MockCompleteProfileCubit()
              ..seed(const CompleteProfileState(username: 'youssef_h', usernameStatus: UsernameStatus.available)),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField).at(0), 'Youssef Hassan');
      await tester.enterText(find.byType(TextField).at(1), 'youssef_h');
      await tester.pump();
      await expectGolden(tester, 'auth_complete_profile', variant);
    });

    testWidgets('forgot password, step 1 ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const ForgotPasswordView(phone: '+201001234567'),
        providers: [
          BlocProvider<ForgotPasswordCubit>.value(
            value: MockForgotPasswordCubit()
              ..seed(const ForgotPasswordState(failure: Failure(FailureCodes.authRecoveryInvalid, statusCode: 401))),
          ),
        ],
      );
      await expectGolden(tester, 'auth_forgot_verify', variant);
    });

    testWidgets('forgot password, step 2 ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const ForgotPasswordView(),
        providers: [
          BlocProvider<ForgotPasswordCubit>.value(
            value: MockForgotPasswordCubit()
              ..seed(const ForgotPasswordState(step: ForgotStep.newPassword, phone: '+201001234567')),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField).first, 'Reading4ever!');
      await tester.pump();
      await expectGolden(tester, 'auth_forgot_new_password', variant);
    });

    testWidgets('forgot the PIN too ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(onPressed: () => showContactSupportSheet(context), child: const Text('open')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'auth_contact_support', variant);
    });

    testWidgets('set recovery PIN ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const SetRecoveryPinView(),
        providers: [
          BlocProvider<SetRecoveryPinCubit>.value(value: MockSetRecoveryPinCubit()..seed(const AccountFormState())),
        ],
      );
      await expectGolden(tester, 'auth_set_pin', variant);
    });

    testWidgets('must change password ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const ChangePasswordView(mandatory: true),
        providers: [
          BlocProvider<ChangePasswordCubit>.value(
            value: MockChangePasswordCubit()
              ..seed(const AccountFormState(errors: {Fields.currentPassword: FailureCodes.authWrongPassword})),
          ),
        ],
      );
      await expectGolden(tester, 'account_change_password', variant);
    });

    testWidgets('change PIN ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const ChangeRecoveryPinView(),
        providers: [
          BlocProvider<ChangeRecoveryPinCubit>.value(
            value: MockChangeRecoveryPinCubit()..seed(const AccountFormState()),
          ),
        ],
      );
      await expectGolden(tester, 'account_change_pin', variant);
    });

    testWidgets('change number ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const ChangePhoneView(),
        providers: [
          BlocProvider<ChangePhoneCubit>.value(
            value: MockChangePhoneCubit()
              ..seed(const AccountFormState(errors: {Fields.phone: FailureCodes.authPhoneUnchanged})),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField).first, '01001234567');
      await expectGolden(tester, 'account_change_phone', variant);
    });

    Future<void> pumpDeleteAccount(WidgetTester tester, DeleteAccountState state) => pumpScreen(
          tester,
          variant,
          const DeleteAccountView(),
          providers: [BlocProvider<DeleteAccountCubit>.value(value: MockDeleteAccountCubit()..seed(state))],
        );

    testWidgets('delete account, what happens ${variant.name}', (tester) async {
      await pumpDeleteAccount(tester, const DeleteAccountState());
      await expectGolden(tester, 'account_delete_review', variant);
    });

    testWidgets('delete account, what happens (end) ${variant.name}', (tester) async {
      await pumpDeleteAccount(tester, const DeleteAccountState());
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await expectGolden(tester, 'account_delete_review_end', variant);
    });

    testWidgets('delete account ${variant.name}', (tester) async {
      await pumpDeleteAccount(
        tester,
        const DeleteAccountState(step: DeleteAccountStep.confirm, understood: true, providers: [ExternalProvider.apple]),
      );
      await tester.enterText(find.byType(TextField), 'reading4life');
      await expectGolden(tester, 'account_delete', variant);
    });

    testWidgets('delete a Google-only account ${variant.name}', (tester) async {
      await pumpDeleteAccount(
        tester,
        const DeleteAccountState(step: DeleteAccountStep.confirm, hasPassword: false, providers: bothProviders),
      );
      await expectGolden(tester, 'account_delete_external', variant);
    });

    testWidgets('delete account, deleting ${variant.name}', (tester) async {
      await pumpDeleteAccount(
        tester,
        const DeleteAccountState(
          step: DeleteAccountStep.confirm,
          hasPassword: false,
          providers: bothProviders,
          understood: true,
          confirmedWith: ExternalProvider.apple,
          status: FormStatus.submitting,
        ),
      );
      await expectGolden(tester, 'account_delete_submitting', variant, spinning: true);
    });

    testWidgets('delete account, offline ${variant.name}', (tester) async {
      await pumpDeleteAccount(
        tester,
        const DeleteAccountState(
          step: DeleteAccountStep.confirm,
          understood: true,
          failure: Failure(FailureCodes.networkOffline),
        ),
      );
      await expectGolden(tester, 'account_delete_offline', variant);
    });

    testWidgets('delete account, Apple only on Android ${variant.name}', (tester) async {
      await pumpDeleteAccount(tester, const DeleteAccountState(step: DeleteAccountStep.confirm, hasPassword: false));
      await expectGolden(tester, 'account_delete_apple_unavailable', variant);
    });

    testWidgets('delete account, last confirmation ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(onPressed: () => showDeleteAccountDialog(context), child: const Text('open')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'account_delete_dialog', variant);
    });

    testWidgets('sign in after deleting the account ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const SignInView(args: SignInArgs(accountDeleted: true)),
        providers: [BlocProvider<SignInCubit>.value(value: MockSignInCubit()..seed(const SignInState()))],
      );
      await expectGolden(tester, 'auth_sign_in_account_deleted', variant);
    });

    testWidgets('add a phone number and password ${variant.name}', (tester) async {
      whenListen(
        session,
        const Stream<SessionState>.empty(),
        initialState: SessionState(status: SessionStatus.authenticated, me: googleOnly),
      );
      await pumpScreen(
        tester,
        variant,
        const AddPhoneSignInView(),
        providers: [
          BlocProvider<AddPhoneSignInCubit>.value(
            value: MockAddPhoneSignInCubit()
              ..seed(const AccountFormState(errors: {Fields.phone: FailureCodes.authPhoneTaken})),
          ),
        ],
      );
      await tester.enterText(find.byType(TextField).first, '01001234567');
      await expectGolden(tester, 'account_add_phone_sign_in', variant);
    });

    testWidgets('settings account ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        const SettingsView(),
        providers: [
          BlocProvider<LinkedAccountsCubit>.value(value: MockLinkedAccountsCubit()..seed(const LinkedAccountsState())),
          BlocProvider<PrivacyCubit>.value(value: MockPrivacyCubit()..seed(const PrivacyState())),
        ],
      );
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'settings_account', variant);
    });

    testWidgets('settings account, Google only ${variant.name}', (tester) async {
      whenListen(
        session,
        const Stream<SessionState>.empty(),
        initialState: SessionState(status: SessionStatus.authenticated, me: googleOnly),
      );
      await pumpScreen(
        tester,
        variant,
        const SettingsView(),
        providers: [
          BlocProvider<LinkedAccountsCubit>.value(
            value: MockLinkedAccountsCubit()..seed(const LinkedAccountsState(providers: bothProviders)),
          ),
          BlocProvider<PrivacyCubit>.value(value: MockPrivacyCubit()..seed(const PrivacyState(publicReadingStats: true))),
        ],
      );
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'settings_account_external', variant);
    });

    testWidgets('country picker ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showCountryPicker(context, selected: Countries.byIso2('EG')),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'auth_country_picker', variant);
    });

    testWidgets('dev login panel ${variant.name}', (tester) async {
      await pumpScreen(
        tester,
        variant,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(onPressed: () => showDevLoginSheet(context), child: const Text('open')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await expectGolden(tester, 'auth_dev_login', variant);
    });
  }
}
