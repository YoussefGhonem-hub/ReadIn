import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/formatters.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:readin/features/auth/presentation/cubit/form_support.dart';
import 'package:readin/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:readin/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:readin/features/auth/presentation/pages/sign_in_page.dart';
import 'package:readin/features/auth/presentation/widgets/auth_widgets.dart';

import '../../helpers/test_app.dart';

class MockSignInCubit extends MockCubit<SignInState> implements SignInCubit {}

class MockForgotPasswordCubit extends MockCubit<ForgotPasswordState> implements ForgotPasswordCubit {}

void main() {
  late MockSignInCubit cubit;

  setUp(() {
    cubit = MockSignInCubit();
    when(() => cubit.submit(
          phoneE164: any(named: 'phoneE164'),
          phoneEmpty: any(named: 'phoneEmpty'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, SignInState state, {Widget view = const SignInView()}) async {
    usePhoneSurface(tester);
    whenListen(cubit, const Stream<SignInState>.empty(), initialState: state);
    await tester.pumpWidget(testApp(
      BlocProvider<SignInCubit>.value(value: cubit, child: view),
      variant: const Variant(AppLocales.en, Brightness.light),
    ));
  }

  testWidgets('submits the number as E.164 with the password', (tester) async {
    await pump(tester, const SignInState());
    await tester.enterText(find.byType(TextField).at(0), '010 0123 4567');
    await tester.enterText(find.byType(TextField).at(1), 'reading4life');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));

    verify(() => cubit.submit(phoneE164: '+201001234567', phoneEmpty: false, password: 'reading4life')).called(1);
  });

  testWidgets('while submitting the button is disabled (no double submit)', (tester) async {
    await pump(tester, const SignInState(status: FormStatus.submitting));
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('pre-fills the number and confirms the password reset', (tester) async {
    await pump(tester, const SignInState(), view: const SignInView(args: SignInArgs(phone: '+12025550110', passwordReset: true)));
    expect(find.text('(202) 555-0110'), findsOneWidget);
    expect(find.text('Password changed. Sign in with your new password.'), findsOneWidget);
  });

  testWidgets('a finished password reset comes back with the number and the banner', (tester) async {
    usePhoneSurface(tester);
    whenListen(cubit, const Stream<SignInState>.empty(), initialState: const SignInState());
    final forgot = MockForgotPasswordCubit();
    final steps = StreamController<ForgotPasswordState>.broadcast();
    addTearDown(steps.close);
    whenListen(forgot, steps.stream, initialState: const ForgotPasswordState(step: ForgotStep.newPassword));
    final router = GoRouter(
      initialLocation: '/auth/sign-in',
      routes: [
        GoRoute(path: '/auth/sign-in', builder: (_, _) => BlocProvider<SignInCubit>.value(value: cubit, child: const SignInView())),
        GoRoute(
          path: '/auth/forgot-password',
          builder: (_, _) => BlocProvider<ForgotPasswordCubit>.value(value: forgot, child: const ForgotPasswordView()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(AppLocales.en),
      locale: AppLocales.en,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ));

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordView), findsOneWidget);

    steps.add(const ForgotPasswordState(step: ForgotStep.done, status: FormStatus.success, phone: '+12025550110'));
    // The password field gets the focus back, so its caret blinks: step through the route transition instead of settling.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(ForgotPasswordView), findsNothing);
    expect(find.text('(202) 555-0110'), findsOneWidget);
    expect(find.text('Password changed. Sign in with your new password.'), findsOneWidget);
  });

  testWidgets('a wrong number or password says so above the form, as one message (SPEC §9.5)', (tester) async {
    await pump(tester, const SignInState(failure: Failure(FailureCodes.authInvalidCredentials, statusCode: 401)));

    expect(find.text('The phone number or password is incorrect.'), findsOneWidget);
  });

  testWidgets('other ways to sign in go under an "or" divider; the dev panel only when asked', (tester) async {
    await pump(tester, const SignInState());
    expect(find.byType(OrDivider), findsNothing);
    expect(find.text('Demo accounts'), findsNothing);

    await pump(
      tester,
      const SignInState(),
      view: SignInView(showDevLogin: true, alternatives: [OutlinedButton(onPressed: () {}, child: const Text('Continue with X'))]),
    );
    expect(find.byType(OrDivider), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Continue with X')).dy, greaterThan(tester.getTopLeft(find.byType(OrDivider)).dy));
    expect(find.text('Demo accounts'), findsOneWidget);
  });

  group('a suspended account (F22)', () {
    testWidgets('sent here after a suspension: says until when, with contact support, until the next attempt', (tester) async {
      final until = DateTime.utc(2026, 11, 9, 12);
      final reason = Failure(FailureCodes.userSuspended, statusCode: 403, suspendedUntil: until);
      await pump(tester, const SignInState(), view: SignInView(args: SignInArgs(endedBy: reason)));
      final message = 'This account is suspended until ${formatDateTime(until, 'en')}. Contact support.';

      expect(find.text(message), findsOneWidget);
      expect(find.text('Contact support'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '010 0123 4567');
      await tester.enterText(find.byType(TextField).at(1), 'reading4life');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();
      expect(find.text(message), findsNothing);
    });

    testWidgets('signing in to a permanently suspended account says so', (tester) async {
      await pump(tester, const SignInState(failure: Failure(FailureCodes.userSuspended, statusCode: 403)));

      expect(find.text('This account is permanently suspended. Contact support.'), findsOneWidget);
    });
  });
}
