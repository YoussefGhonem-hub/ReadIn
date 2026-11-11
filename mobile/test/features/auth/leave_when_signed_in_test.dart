import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:readin/features/admin/presentation/admin_routes.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/auth/presentation/widgets/leave_when_signed_in.dart';

import '../../helpers/admin_fakes.dart';
import '../../helpers/social_fakes.dart';

const _member = Me(
  id: 'u-1',
  phoneNumber: '+201229391144',
  displayName: 'Youssef',
  username: 'yough',
  onboardingCompleted: true,
);

/// A guest's Sign in opened with `context.push` over Home (Home's button, the sign-in prompt…): the router's redirect
/// reads Home's location there, so the screen itself has to close once the session starts.
void main() {
  late MockSessionCubit session;
  late StreamController<SessionState> changes;

  setUp(() {
    session = MockSessionCubit();
    changes = StreamController<SessionState>();
    whenListen(session, changes.stream, initialState: const SessionState(status: SessionStatus.guest));
  });

  tearDown(() => changes.close());

  /// The app's rule (router.dart): a signed-in user on a sign-in screen goes Home. It can't see a pushed Sign in.
  String? signedInLeaveAuth(BuildContext _, GoRouterState state) =>
      session.state.isAuthenticated && state.uri.path.startsWith('/auth/') ? '/home' : null;

  Future<GoRouter> pumpApp(WidgetTester tester, {GoRouterRedirect? redirect}) async {
    final router = GoRouter(
      initialLocation: '/home',
      redirect: redirect ?? signedInLeaveAuth,
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(onPressed: () => context.push('/auth/sign-in'), child: const Text('Home')),
          ),
        ),
        GoRoute(
          path: '/auth/sign-in',
          builder: (context, _) => LeaveWhenSignedIn(
            child: Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Link your account'))),
                ),
                child: const Text('Sign in'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/onboarding', builder: (_, _) => const Scaffold(body: Text('Onboarding'))),
        GoRoute(path: AdminRoutes.consoleDashboard, builder: (_, _) => const Scaffold(body: Text('Dashboard'))),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(BlocProvider<SessionCubit>.value(value: session, child: MaterialApp.router(routerConfig: router)));
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    return router;
  }

  Future<void> signIn(WidgetTester tester, Me me) async {
    changes.add(SessionState(status: SessionStatus.authenticated, me: me));
    await tester.pumpAndSettle();
  }

  testWidgets('a pushed Sign in closes once the session starts, back to the screen under it', (tester) async {
    final router = await pumpApp(tester);

    await signIn(tester, _member);

    expect(find.text('Sign in'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(router.state.uri.path, '/home');
  });

  testWidgets('a screen opened over it (linking Google or Apple) closes with it', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Link your account'), findsOneWidget);

    await signIn(tester, _member);

    expect(find.text('Link your account'), findsNothing);
    expect(find.text('Sign in'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a gate the redirect moved to stays: nothing is closed after it', (tester) async {
    final router = await pumpApp(
      tester,
      redirect: (_, state) =>
          session.state.isAuthenticated && state.uri.path != '/onboarding' ? '/onboarding' : null,
    );

    await signIn(tester, const Me(id: 'u-2', phoneNumber: '+201000000002', displayName: 'New', username: 'new'));

    expect(find.text('Onboarding'), findsOneWidget);
    expect(router.state.uri.path, '/onboarding');
  });

  testWidgets("an admin lands on the console's dashboard", (tester) async {
    final router = await pumpApp(tester);

    await signIn(tester, adminMe());

    expect(find.text('Dashboard'), findsOneWidget);
    expect(router.state.uri.path, AdminRoutes.consoleDashboard);
  });

  testWidgets('a guest stays on Sign in', (tester) async {
    await pumpApp(tester);

    changes.add(const SessionState(status: SessionStatus.guest));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
  });
}
