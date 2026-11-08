import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/push/push_links.dart';
import '../features/admin/domain/entities/admin_content.dart';
import '../features/admin/presentation/admin_routes.dart';
import '../features/admin/presentation/pages/admin_article_page.dart';
import '../features/admin/presentation/pages/admin_console_page.dart';
import '../features/admin/presentation/pages/admin_content_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/admin/presentation/pages/admin_notifications_tab.dart';
import '../features/admin/presentation/pages/admin_user_page.dart';
import '../features/admin/presentation/pages/admin_users_page.dart';
import '../features/admin/presentation/pages/admin_verification_page.dart';
import '../features/admin/presentation/pages/admin_verification_request_page.dart';
import '../features/article/presentation/pages/article_page.dart';
import '../features/auth/domain/entities/permissions.dart';
import '../features/auth/presentation/pages/account_pages.dart';
import '../features/auth/presentation/pages/complete_profile_page.dart';
import '../features/auth/presentation/pages/delete_account_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/auth/presentation/pages/sign_up_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/session/session_cubit.dart';
import '../features/categories/presentation/category_routes.dart';
import '../features/categories/presentation/pages/category_page.dart';
import '../features/editor/presentation/pages/article_editor_page.dart';
import '../features/editor/presentation/pages/my_articles_page.dart';
import '../features/explore/domain/entities/explore.dart';
import '../features/explore/presentation/explore_routes.dart';
import '../features/explore/presentation/pages/explore_page.dart';
import '../features/explore/presentation/pages/explore_ranking_page.dart';
import '../features/explore/presentation/pages/field_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/moderation/domain/entities/moderation.dart';
import '../features/moderation/presentation/moderation_routes.dart';
import '../features/moderation/presentation/pages/moderation_case_page.dart';
import '../features/moderation/presentation/pages/moderation_page.dart';
import '../features/mutes/presentation/pages/muted_page.dart';
import '../features/notifications/presentation/pages/notification_settings_page.dart';
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
import '../features/reading/presentation/pages/reading_stats_page.dart';
import '../features/saved/presentation/pages/saved_page.dart';
import '../features/search/domain/entities/search.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/search/presentation/search_routes.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/settings/presentation/pages/interests_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/support/presentation/pages/admin_ticket_page.dart';
import '../features/support/presentation/pages/admin_tickets_page.dart';
import '../features/support/presentation/pages/new_ticket_page.dart';
import '../features/support/presentation/pages/support_page.dart';
import '../features/support/presentation/pages/support_ticket_page.dart';
import '../features/support/presentation/support_routes.dart';
import '../features/tags/presentation/pages/tag_page.dart';
import '../features/tags/presentation/tag_routes.dart';
import '../features/verification/presentation/pages/verification_page.dart';
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
  static const notificationSettings = NotificationSettingsPage.path;
  static const interests = InterestsPage.path;
  static const readingStats = ReadingStatsPage.path;
  static const verification = VerificationPage.path;
  static const moderation = ModerationRoutes.home;
  static const editProfile = ProfileRoutes.edit;
  static const paths = PathRoutes.list;
  static const search = SearchRoutes.path;

  /// The reader. Shared web links (`https://{domain}/{ar|en}/a/{slug}`, F24) arrive here as `/a/{slug}?lang=`.
  static String article(String slug) => '/a/$slug';

  /// Anyone's profile (F14).
  static String user(String username) => ProfileRoutes.of(username);

  /// A learning path (F09).
  static String path(String slug) => PathRoutes.of(slug);

  /// A tag's page (F32).
  static String tag(String slug) => TagRoutes.of(slug);

  /// A writer's category page (F31).
  static String category(String username, String slug) => CategoryRoutes.of(username, slug);

  /// A field's page (F15), on one of its topics with [topic].
  static String field(String slug, {String? topic}) => ExploreRoutes.field(slug, topic: topic);

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
  // The web's article links (/ar/a/{slug}, /en/a/{slug}) arrive through App Links and Universal Links (F24): they open
  // the reader in the version that was shared.
  if (webArticleRoute(uri) case final article?) return article;
  // The web's category pages (/@{username}/c/{slug}, F31) and profiles (/@{username}) are /u/… here.
  if (webProfileRoute(uri) case final profile?) return profile;

  final location = uri.path;
  final atSplash = location == AppRoutes.splash;
  if (session.status == SessionStatus.unknown) {
    return atSplash ? null : Uri(path: AppRoutes.splash, queryParameters: {'from': uri.toString()}).toString();
  }

  final target = atSplash ? (uri.queryParameters['from'] ?? AppRoutes.home) : uri.toString();
  final targetPath = Uri.parse(target).path;
  final isAuthRoute = targetPath.startsWith('/auth/') || targetPath == AppRoutes.welcome;
  // The editor (F05), moderation (F22), notifications and their settings (F17), your interests (F12), the own reading
  // stats and writer verification (F19) need an account like the account screens; the Write tab itself shows the
  // sign-in prompt.
  final isAccountRoute = targetPath.startsWith('/account/') ||
      targetPath == AppRoutes.editProfile ||
      targetPath.startsWith('${AppRoutes.write}/') ||
      targetPath == AppRoutes.moderation ||
      targetPath.startsWith('${AppRoutes.moderation}/') ||
      targetPath == AppRoutes.notifications ||
      targetPath == AppRoutes.notificationSettings ||
      targetPath == AppRoutes.interests ||
      targetPath == MutedPage.path || // Settings → Muted (F28)
      targetPath == AppRoutes.readingStats ||
      targetPath == AppRoutes.verification ||
      // The admin console (F23) and Help & support (F35); the pages check the permissions.
      AdminRoutes.isConsoleTab(targetPath) ||
      AdminRoutes.isConsole(targetPath) ||
      SupportRoutes.isSupport(targetPath);
  // Shared links (articles, profiles, tag pages, field pages) open for first-time guests too, without Welcome first.
  final isArticle = targetPath.startsWith('/a/') ||
      targetPath.startsWith('/u/') ||
      targetPath.startsWith('/tags/') ||
      targetPath.startsWith('/f/');
  String? stay() => atSplash ? target : null;

  if (session.isAuthenticated) {
    if (session.gate case final gate?) {
      final gateRoute = AppRoutes.forGate(gate);
      return targetPath == gateRoute ? stay() : gateRoute;
    }
    // The admin's bar (F23): holders of admin.access start on the console's dashboard, when the app opens and after
    // signing in; the console's tabs are theirs only, each behind its permission (Home is the app as a reader sees it).
    final isAdmin = session.me?.isAdmin ?? false;
    final landing = isAuthRoute ||
        targetPath == AppRoutes.setRecoveryPin ||
        targetPath == AppRoutes.completeProfile ||
        (atSplash && targetPath == AppRoutes.home);
    if (isAdmin && landing) return AdminRoutes.consoleDashboard;
    // The console's old home (`/admin`) is the dashboard tab now; its pages (`/admin/...`) still open as before.
    if (targetPath == AdminRoutes.home) return isAdmin ? AdminRoutes.consoleDashboard : AppRoutes.home;
    if (AdminRoutes.isConsoleTab(targetPath)) {
      if (!isAdmin) return AppRoutes.home;
      final needs = AdminRoutes.consoleTabPermission(targetPath);
      if (targetPath == AdminRoutes.console || (needs != null && !(session.me?.can(needs) ?? false))) {
        return AdminRoutes.consoleDashboard;
      }
    }
    // Mandatory screens that no longer apply, and the sign-in screens, lead home.
    if (isAuthRoute || targetPath == AppRoutes.setRecoveryPin || targetPath == AppRoutes.completeProfile) {
      return AppRoutes.home;
    }
    // A console ticket (a `support_ticket` push, F35) for someone without support.manage: the notification center.
    if (AdminRoutes.isTicket(targetPath) && !(session.me?.can(Permissions.supportManage) ?? false)) {
      return AppRoutes.notifications;
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
      GoRoute(path: AppRoutes.settings, builder: (_, state) => SettingsPage(section: SettingsSection.fromQuery(state.uri))),
      GoRoute(path: AppRoutes.notificationSettings, builder: (_, _) => const NotificationSettingsPage()),
      GoRoute(path: AppRoutes.interests, builder: (_, _) => const InterestsPage()),
      // Settings → Muted (F28); it needs an account (the redirect above).
      GoRoute(path: MutedPage.path, builder: (_, _) => const MutedPage()),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsPage()),
      GoRoute(path: AppRoutes.readingStats, builder: (_, _) => const ReadingStatsPage()),
      GoRoute(path: AppRoutes.verification, builder: (_, _) => const VerificationPage()),
      // Help & support (F35): the member's tickets; `?from=` is the screen a new ticket came from.
      GoRoute(path: SupportRoutes.home, builder: (_, state) => SupportPage(from: SupportRoutes.fromOf(state.uri))),
      GoRoute(path: SupportRoutes.newTicket, builder: (_, state) => NewTicketPage(from: SupportRoutes.fromOf(state.uri))),
      GoRoute(
        path: '${SupportRoutes.ticketsPrefix}/:id',
        builder: (_, state) => SupportTicketPage(ticketId: state.pathParameters['id']!),
      ),
      // The admin console (F23): each page checks its own permission.
      GoRoute(path: AdminRoutes.home, builder: (_, _) => const AdminConsolePage()),
      GoRoute(path: AdminRoutes.dashboard, builder: (_, _) => const AdminDashboardPage()),
      GoRoute(path: AdminRoutes.users, builder: (_, _) => const AdminUsersPage()),
      GoRoute(path: '${AdminRoutes.users}/:id', builder: (_, state) => AdminUserPage(userId: state.pathParameters['id']!)),
      GoRoute(path: AdminRoutes.content, builder: (_, state) => AdminContentPage(query: AdminArticleQuery.fromUri(state.uri))),
      GoRoute(path: '${AdminRoutes.content}/:id', builder: (_, state) => AdminArticlePage(articleId: state.pathParameters['id']!)),
      GoRoute(path: AdminRoutes.tickets, builder: (_, _) => const AdminTicketsPage()),
      GoRoute(path: '${AdminRoutes.tickets}/:id', builder: (_, state) => AdminTicketPage(ticketId: state.pathParameters['id']!)),
      GoRoute(path: AdminRoutes.verification, builder: (_, _) => const AdminVerificationPage()),
      GoRoute(
        path: '${AdminRoutes.verification}/:id',
        builder: (_, state) => AdminVerificationRequestPage(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/a/:slug',
        builder: (_, state) => ArticlePage(
          slug: state.pathParameters['slug']!,
          anchor: state.uri.fragment.isEmpty ? null : state.uri.fragment,
          language: AppRoutes.articleLanguage(state.uri),
        ),
      ),
      // A tag's page (F32), guests allowed; its web link https://{domain}/tags/{slug} opens it too (App Links).
      GoRoute(path: TagRoutes.pattern, builder: (_, state) => TagPage(slug: state.pathParameters['slug']!)),
      // A field's page (F15), guests allowed: `?topic=` selects a chip (the link Search gives topics); its web link
      // https://{domain}/f/{slug} opens it too (App Links).
      GoRoute(
        path: ExploreRoutes.fieldPattern,
        builder: (_, state) => FieldPage(slug: state.pathParameters['slug']!, topic: ExploreRoutes.topicOf(state.uri)),
      ),
      // Explore's rankings in full ("See all", F15), above the tabs.
      for (final ranking in ExploreRanking.values)
        GoRoute(path: ExploreRoutes.ranking(ranking), builder: (_, _) => ExploreRankingPage(ranking: ranking)),
      // Search (F16), full screen above the tabs, guests allowed: from Explore's search bar, or `/search?q=&type=`.
      GoRoute(
        path: AppRoutes.search,
        builder: (_, state) => SearchPage(
          initialQuery: state.uri.queryParameters['q'],
          initialType: SearchType.fromWire(state.uri.queryParameters['type']),
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
        path: AppRoutes.moderation,
        builder: (_, _) => const ModerationPage(),
        routes: [
          GoRoute(
            path: ':type/:id',
            builder: (_, state) => switch (enumFromWire(ModerationTargetType.values, state.pathParameters['type'])) {
              final type? => ModerationCasePage(target: ModerationTargetRef(type, state.pathParameters['id']!)),
              null => const ModerationPage(),
            },
          ),
        ],
      ),
      GoRoute(
        path: '/u/:username',
        builder: (_, state) => ProfilePage(username: state.pathParameters['username']!),
        routes: [
          // A writer's category page (F31), guests allowed; `_other` is "مقالات تانية". Its web link
          // https://{domain}/@{username}/c/{slug} opens it too (App Links).
          GoRoute(
            path: CategoryRoutes.subPattern,
            builder: (_, state) => CategoryPage(username: state.pathParameters['username']!, slug: state.pathParameters['slug']!),
          ),
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
          // The admin's bar (F23, holders of admin.access; the redirect keeps everyone else out): Dashboard, Tickets,
          // Users and Notifications; More opens a sheet with the rest of the console.
          StatefulShellBranch(routes: [GoRoute(path: AdminRoutes.consoleDashboard, builder: (_, _) => const AdminDashboardPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AdminRoutes.consoleTickets, builder: (_, _) => const AdminTicketsPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AdminRoutes.consoleUsers, builder: (_, _) => const AdminUsersPage())]),
          StatefulShellBranch(
            routes: [GoRoute(path: AdminRoutes.consoleNotifications, builder: (_, _) => const AdminNotificationsTab())],
          ),
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
