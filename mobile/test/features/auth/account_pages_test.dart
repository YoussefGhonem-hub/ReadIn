import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/auth/presentation/cubit/account_security_cubits.dart';
import 'package:readin/features/auth/presentation/cubit/form_support.dart';
import 'package:readin/features/auth/presentation/pages/account_pages.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

class MockChangePasswordCubit extends MockCubit<AccountFormState> implements ChangePasswordCubit {}

class MockSessionCubit extends MockCubit<SessionState> implements SessionCubit {}

void main() {
  late MockChangePasswordCubit cubit;
  late MockSessionCubit session;
  late StreamController<AccountFormState> states;

  setUp(() {
    cubit = MockChangePasswordCubit();
    session = MockSessionCubit();
    states = StreamController<AccountFormState>.broadcast();
    whenListen(cubit, states.stream, initialState: const AccountFormState());
    whenListen(session, const Stream<SessionState>.empty(),
        initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
  });

  tearDown(() => unawaited(states.close()));

  Future<void> pumpRouter(WidgetTester tester, {required bool mandatory}) async {
    usePhoneSurface(tester);
    final router = GoRouter(
      initialLocation: mandatory ? '/account/password' : '/settings',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const Scaffold(body: Text('home'))),
        GoRoute(
          path: '/settings',
          builder: (context, _) => Scaffold(
            body: TextButton(onPressed: () => context.push('/account/password'), child: const Text('settings')),
          ),
        ),
        GoRoute(
          path: '/account/password',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<SessionCubit>.value(value: session),
              BlocProvider<ChangePasswordCubit>.value(value: cubit),
            ],
            child: ChangePasswordView(mandatory: mandatory),
          ),
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
    await tester.pumpAndSettle();
  }

  testWidgets('the mandatory screen moves on once the password changed', (tester) async {
    await pumpRouter(tester, mandatory: true);
    expect(find.text('Your password was reset. Choose a new one to continue.'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);

    states.add(const AccountFormState(status: FormStatus.success));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('Password changed.'), findsOneWidget);
  });

  testWidgets('from Settings it goes back with a confirmation', (tester) async {
    await pumpRouter(tester, mandatory: false);
    await tester.tap(find.text('settings'));
    await tester.pumpAndSettle();
    expect(find.text('Your other devices will be signed out.'), findsOneWidget);

    states.add(const AccountFormState(status: FormStatus.success));
    await tester.pumpAndSettle();

    expect(find.text('settings'), findsOneWidget);
    expect(find.text('Password changed.'), findsOneWidget);
  });
}
