import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/article/presentation/pages/article_page.dart';
import '../features/auth/presentation/pages/auth_pages.dart';
import '../features/auth/presentation/session/session_cubit.dart';
import '../features/editor/presentation/pages/editor_page.dart';
import '../features/explore/presentation/pages/explore_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/saved/presentation/pages/saved_page.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import 'main_shell.dart';
import 'splash_page.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signIn = '/auth/sign-in';
  static const signUp = '/auth/sign-up';
  static const forgotPassword = '/auth/forgot-password';
  static const home = '/home';
  static const explore = '/explore';
  static const write = '/write';
  static const saved = '/saved';
  static const profile = '/profile';
  static const settings = '/settings';
  static const notifications = '/notifications';

  /// Deep link `readin.app/a/{slug}` (SPEC §3.3, §8.2).
  static String article(String slug) => '/a/$slug';
}

/// Pure redirect logic, unit-testable without a widget tree.
String? resolveRedirect({required Uri uri, required SessionState session, required AppSettings settings}) {
  final location = uri.path;
  final atSplash = location == AppRoutes.splash;
  if (session.status == SessionStatus.unknown) {
    return atSplash ? null : Uri(path: AppRoutes.splash, queryParameters: {'from': uri.toString()}).toString();
  }

  final target = atSplash ? (uri.queryParameters['from'] ?? AppRoutes.home) : uri.toString();
  final targetPath = Uri.parse(target).path;
  final isAuthRoute = targetPath.startsWith('/auth');
  final isOnboarding = targetPath == AppRoutes.onboarding;
  final isArticle = targetPath.startsWith('/a/');

  if (session.needsOnboarding && !isOnboarding) return AppRoutes.onboarding;
  if (session.isAuthenticated && isAuthRoute) return AppRoutes.home;
  if (!session.isAuthenticated && !settings.welcomeSeen && !isOnboarding && !isAuthRoute && !isArticle) {
    return AppRoutes.onboarding;
  }
  return atSplash ? target : null;
}

GoRouter buildRouter({required SessionCubit session, required SettingsCubit settings}) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.home,
    refreshListenable: _StreamsListenable([session.stream, settings.stream]),
    redirect: (context, state) => resolveRedirect(uri: state.uri, session: session.state, settings: settings.state),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingPage()),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInPage()),
      GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpPage()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordPage()),
      GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage()),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsPage()),
      GoRoute(path: '/a/:slug', builder: (_, state) => ArticlePage(slug: state.pathParameters['slug']!)),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.explore, builder: (_, _) => const ExplorePage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.write, builder: (_, _) => const EditorPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.saved, builder: (_, _) => const SavedPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfilePage())]),
        ],
      ),
    ],
  );
}

/// Re-runs router redirects whenever the session or settings change.
class _StreamsListenable extends ChangeNotifier {
  _StreamsListenable(List<Stream<Object?>> streams) {
    for (final stream in streams) {
      _subscriptions.add(stream.listen((_) => notifyListeners()));
    }
  }

  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
