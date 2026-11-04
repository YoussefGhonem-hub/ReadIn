import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/article/presentation/pages/article_page.dart';
import '../features/auth/presentation/pages/account_pages.dart';
import '../features/auth/presentation/pages/complete_profile_page.dart';
import '../features/auth/presentation/pages/delete_account_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/auth/presentation/pages/sign_up_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/session/session_cubit.dart';
import '../features/editor/presentation/pages/article_editor_page.dart';
import '../features/editor/presentation/pages/my_articles_page.dart';
import '../features/explore/presentation/pages/explore_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/paths/presentation/pages/path_page.dart';
import '../features/paths/presentation/pages/paths_page.dart';
import '../features/paths/presentation/path_routes.dart';
import '../features/profile/domain/entities/profile.dart';
import '../features/profile/presentation/cubit/follow_list_cubit.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/follow_lists_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/profile_routes.dart';
import '../features/saved/presentation/pages/saved_page.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import 'main_shell.dart';
import 'splash_page.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const signIn = '/auth/sign-in';
  static const signUp = '/auth/sign-up';
  static const forgotPassword = '/auth/forgot-password';
  static const completeProfile = '/account/complete-profile';
  static const setRecoveryPin = '/account/recovery-pin/new';
  static const changeRecoveryPin = '/account/recovery-pin';
  static const changePassword = '/account/password';
  static const changePhone = '/account/phone';
  static const addPhoneSignIn = '/account/phone-sign-in';
  static const deleteAccount = '/account/delete';
  static const home = '/home';
  static const explore = '/explore';
  static const write = EditorRoutes.myArticles;
  static const saved = '/saved';
  static const profile = '/profile';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const editProfile = ProfileRoutes.edit;
  static const paths = PathRoutes.list;

  /// Deep link `readin.app/a/{slug}` (SPEC §3.3, §8.2).
  static String article(String slug) => '/a/$slug';

  /// Anyone's profile (F14).
  static String user(String username) => ProfileRoutes.of(username);

  /// A learning path (F09).
  static String path(String slug) => PathRoutes.of(slug);

  /// `?lang=` of an article link: open that version (`ar-EG` / `en`) rather than the preferred one, e.g. the version
  /// Continue reading resumes (F03). Anything else is ignored.
  static String? articleLanguage(Uri uri) => switch (uri.queryParameters['lang']) {
        final lang? when lang == 'ar-EG' || lang == 'en' => lang,
        _ => null,
      };

  /// Where an [AccountGate] is handled.
  static String forGate(AccountGate gate) => switch (gate) {
        AccountGate.changePassword => changePassword,
        AccountGate.setRecoveryPin => setRecoveryPin,
        AccountGate.completeProfile => completeProfile,
        AccountGate.onboarding => onboarding,
      };
}

/// Pure redirect logic, unit-testable without a widget tree.
///
/// Signed in: the account guards apply first, in the SPEC §9.2 order (change password → set PIN → complete profile →
/// onboarding), and sign-in screens lead home. Guests can browse and read; first-time guests see Welcome, and account
/// screens send them home, except Delete account, which sends them to Sign in: the session ends there when the account
/// is deleted (the screen then shows Sign in with "Your account was deleted.") or had already ended elsewhere.
String? resolveRedirect({required Uri uri, required SessionState session, required AppSettings settings}) {
  final location = uri.path;
  final atSplash = location == AppRoutes.splash;
  if (session.status == SessionStatus.unknown) {
    return atSplash ? null : Uri(path: AppRoutes.splash, queryParameters: {'from': uri.toString()}).toString();
  }

  final target = atSplash ? (uri.queryParameters['from'] ?? AppRoutes.home) : uri.toString();
  final targetPath = Uri.parse(target).path;
  final isAuthRoute = targetPath.startsWith('/auth/') || targetPath == AppRoutes.welcome;
  // The editor (F05) needs an account like the account screens; the Write tab itself shows the sign-in prompt.
  final isAccountRoute =
      targetPath.startsWith('/account/') || targetPath == AppRoutes.editProfile || targetPath.startsWith('${AppRoutes.write}/');
  // Shared links open for first-time guests too, without Welcome first.
  final isArticle = targetPath.startsWith('/a/') || targetPath.startsWith('/u/');
  String? stay() => atSplash ? target : null;

  if (session.isAuthenticated) {
    if (session.gate case final gate?) {
      final gateRoute = AppRoutes.forGate(gate);
      return targetPath == gateRoute ? stay() : gateRoute;
    }
    // Mandatory screens that no longer apply, and the sign-in screens, lead home.
    if (isAuthRoute || targetPath == AppRoutes.setRecoveryPin || targetPath == AppRoutes.completeProfile) {
      return AppRoutes.home;
    }
    return stay();
  }

  if (targetPath == AppRoutes.deleteAccount) return AppRoutes.signIn;
  if (isAccountRoute || targetPath == AppRoutes.onboarding) {
    return settings.welcomeSeen ? AppRoutes.home : AppRoutes.welcome;
  }
  if (!settings.welcomeSeen && !isAuthRoute && !isArticle) return AppRoutes.welcome;
  return stay();
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
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomePage()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingPage()),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (_, state) => SignInPage(args: state.extra is SignInArgs ? state.extra! as SignInArgs : const SignInArgs()),
      ),
      GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpPage()),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, state) => ForgotPasswordPage(phone: state.extra is String ? state.extra! as String : null),
      ),
      GoRoute(path: AppRoutes.completeProfile, builder: (_, _) => const CompleteProfilePage()),
      GoRoute(path: AppRoutes.setRecoveryPin, builder: (_, _) => const SetRecoveryPinPage()),
      GoRoute(path: AppRoutes.changeRecoveryPin, builder: (_, _) => const ChangeRecoveryPinPage()),
      GoRoute(path: AppRoutes.changePassword, builder: (_, _) => const ChangePasswordPage()),
      GoRoute(path: AppRoutes.changePhone, builder: (_, _) => const ChangePhonePage()),
      GoRoute(path: AppRoutes.addPhoneSignIn, builder: (_, _) => const AddPhoneSignInPage()),
      GoRoute(path: AppRoutes.deleteAccount, builder: (_, _) => const DeleteAccountPage()),
      GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage()),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsPage()),
      GoRoute(
        path: '/a/:slug',
        builder: (_, state) => ArticlePage(
          slug: state.pathParameters['slug']!,
          anchor: state.uri.fragment.isEmpty ? null : state.uri.fragment,
          language: AppRoutes.articleLanguage(state.uri),
        ),
      ),
      // The editor (F05), full screen above the tabs: a new article, or one of mine.
      GoRoute(path: EditorRoutes.newArticle, builder: (_, _) => const ArticleEditorPage()),
      GoRoute(path: '${AppRoutes.write}/:id', builder: (_, state) => ArticleEditorPage(articleId: state.pathParameters['id'])),
      GoRoute(
        path: AppRoutes.paths,
        builder: (_, state) => PathsPage(initialTab: PathRoutes.tabOf(state.uri)),
        routes: [GoRoute(path: ':slug', builder: (_, state) => PathPage(slug: state.pathParameters['slug']!))],
      ),
      GoRoute(
        path: '/u/:username',
        builder: (_, state) => ProfilePage(username: state.pathParameters['username']!),
        routes: [
          for (final kind in FollowListKind.values)
            GoRoute(
              path: kind.name,
              builder: (_, state) => FollowListsPage(
                username: state.pathParameters['username']!,
                initialKind: kind,
                profile: state.extra is UserProfile ? state.extra! as UserProfile : null,
              ),
            ),
        ],
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, state) => EditProfilePage(profile: state.extra is UserProfile ? state.extra! as UserProfile : null),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.explore, builder: (_, _) => const ExplorePage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.write, builder: (_, _) => const MyArticlesPage())]),
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
