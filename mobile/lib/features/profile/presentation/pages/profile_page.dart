import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../saved/presentation/cubit/saved_list_cubit.dart';
import '../../../saved/presentation/pages/saved_page.dart';
import '../../domain/entities/profile.dart';
import '../cubit/privacy_cubit.dart';
import '../cubit/profile_articles_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../profile_routes.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_tabs.dart';

/// Profile (F14). Without [username] it is the Profile tab: the viewer's own profile, or the sign-in prompt for
/// guests. `/u/{username}` shows anyone's profile.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.username});

  final String? username;

  @override
  Widget build(BuildContext context) {
    final handle = username;
    if (handle != null) return _ProfileProviders(username: handle, child: const ProfileView());

    final l10n = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final me = session.me;
    if (!session.isAuthenticated) {
      return _TabScaffold(
        body: EmptyView(
          icon: Icons.person_outline_rounded,
          title: l10n.profileGuestTitle,
          body: l10n.profileGuestBody,
          action: Column(
            children: [
              FilledButton(onPressed: () => context.push('/auth/sign-up'), child: Text(l10n.signUp)),
              const SizedBox(height: ReadInSpace.s2),
              TextButton(onPressed: () => context.push('/auth/sign-in'), child: Text(l10n.signIn)),
            ],
          ),
        ),
      );
    }
    if (me == null) {
      return _TabScaffold(
        body: ErrorView(
          failure: session.failure ?? const Failure(FailureCodes.userNotSynced),
          onRetry: context.read<SessionCubit>().refresh,
        ),
      );
    }
    // A new @username (edit profile) is a new profile to load.
    return KeyedSubtree(
      key: ValueKey(me.username),
      child: _ProfileProviders(username: me.username, child: const ProfileView(isTab: true)),
    );
  }
}

/// The profile's cubits. The tabs' cubits start when their tab is first shown.
class _ProfileProviders extends StatelessWidget {
  const _ProfileProviders({required this.username, required this.child});

  final String username;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<ProfileCubit>()..load(username)),
          BlocProvider(create: (_) => getIt<ProfileArticlesCubit>(param1: username)..load()),
          BlocProvider(create: (_) => getIt<SavedListCubit>()..load()),
          BlocProvider(create: (_) => getIt<PrivacyCubit>()),
        ],
        child: child,
      );
}

/// Settings stay one tap away on the Profile tab.
class _TabScaffold extends StatelessWidget {
  const _TabScaffold({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.navProfile),
          automaticallyImplyLeading: false,
          actions: const [_SettingsButton()],
        ),
        body: body,
      );
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: context.l10n.settings,
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => context.push('/settings'),
      );
}

/// A loaded profile, its header and tabs: Articles · Saved (own profile only) · Paths · About. Needs a [ProfileCubit]
/// and [ProfileArticlesCubit] above it, plus [SavedListCubit] and [PrivacyCubit] on the own profile.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key, this.isTab = false});

  /// The Profile tab (no back button) rather than a pushed `/u/{username}`.
  final bool isTab;

  Future<void> _edit(BuildContext context, UserProfile profile) async {
    final saved = await context.push<bool>(ProfileRoutes.edit, extra: profile);
    if (saved == true && context.mounted) {
      unawaited(context.read<ProfileCubit>().refresh());
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.l10n.profileSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final profile = state.profile;
        final own = isTab || (profile?.isMe ?? false);
        return Scaffold(
          appBar: AppBar(
            title: isTab || profile == null
                ? Text(isTab ? l10n.navProfile : '')
                : Text(Bidi.ltrIsolate('@${profile.username}'), maxLines: 1, overflow: TextOverflow.ellipsis),
            automaticallyImplyLeading: !isTab,
            actions: [if (own) const _SettingsButton()],
          ),
          body: switch (state.status) {
            ProfileStatus.loading => const SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    ProfileHeaderSkeleton(),
                    Padding(padding: EdgeInsets.symmetric(horizontal: ReadInSpace.s5), child: ArticleListSkeleton()),
                  ],
                ),
              ),
            ProfileStatus.failure when state.notFound => EmptyView(
                icon: Icons.person_off_outlined,
                title: l10n.profileNotFoundTitle,
                body: l10n.profileNotFoundBody,
              ),
            ProfileStatus.failure => ErrorView(failure: state.failure!, onRetry: context.read<ProfileCubit>().refresh),
            ProfileStatus.ready => _ProfileContent(profile: profile!, onEdit: () => _edit(context, profile)),
          },
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile, required this.onEdit});

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isMe = profile.isMe;
    final tabs = [
      Tab(text: l10n.profileTabArticles),
      if (isMe) Tab(text: l10n.profileTabSaved),
      Tab(text: l10n.profileTabPaths),
      Tab(text: l10n.profileTabAbout),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: ProfileHeader(profile: profile, onEdit: onEdit)),
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverPersistentHeader(
              pinned: true,
              // Natural widths: four Arabic labels don't fit fixed quarters, nor do larger font sizes.
              delegate: _TabBarHeader(TabBar(tabs: tabs, isScrollable: true, tabAlignment: TabAlignment.start), context.colors),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            ProfileArticlesTab(profile: profile, onWrite: isMe ? () => context.go('/write') : null),
            if (isMe) const SavedArticlesList(leading: profileTabOverlap),
            const ProfilePathsTab(),
            ProfileAboutTab(profile: profile, onEdit: isMe ? onEdit : null),
          ],
        ),
      ),
    );
  }
}

/// The tab bar, pinned under the app bar once the header scrolls away.
class _TabBarHeader extends SliverPersistentHeaderDelegate {
  _TabBarHeader(this.tabBar, this.colors);

  final TabBar tabBar;
  final ReadInColors colors;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => DecoratedBox(
        decoration: BoxDecoration(color: colors.bg, border: Border(bottom: BorderSide(color: colors.border))),
        child: Align(alignment: AlignmentDirectional.topStart, child: tabBar),
      );

  @override
  bool shouldRebuild(_TabBarHeader old) => old.tabBar != tabBar || old.colors != colors;
}
