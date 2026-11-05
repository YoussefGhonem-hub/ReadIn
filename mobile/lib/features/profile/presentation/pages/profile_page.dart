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
import '../../../article/presentation/cubit/post_cards_cubit.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../categories/presentation/widgets/categories_tab.dart';
import '../../../highlights/presentation/cubit/my_highlights_cubit.dart';
import '../../../highlights/presentation/widgets/saved_highlights_list.dart';
import '../../../moderation/presentation/cubit/moderation_action_cubit.dart';
import '../../../mutes/presentation/widgets/muted_writer_banner.dart';
import '../../../saved/presentation/cubit/saved_list_cubit.dart';
import '../../../saved/presentation/pages/saved_page.dart';
import '../../domain/entities/profile.dart';
import '../cubit/privacy_cubit.dart';
import '../cubit/profile_articles_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_reposts_cubit.dart';
import '../profile_routes.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu.dart';
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
          // F29: created, and loaded, when the Reposts tab is first shown.
          BlocProvider(create: (_) => getIt<ProfileRepostsCubit>(param1: username)),
          BlocProvider(create: (_) => getIt<SavedListCubit>()..load()),
          BlocProvider(create: (_) => getIt<PrivacyCubit>()),
          // Created when a moderator warns or suspends from the "⋯" menu (F22).
          BlocProvider(create: (_) => getIt<ModerationActionCubit>()),
          // The expanded post cards of the Articles tab, kept while the reader is open (F34).
          BlocProvider(create: (_) => getIt<PostCardsCubit>()),
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

/// A loaded profile, its header and tabs: Articles · Categories (F31) · Reposts (F29) · Saved (own profile only) ·
/// Paths · About. Needs a [ProfileCubit], [ProfileArticlesCubit] and [ProfileRepostsCubit] above it, plus
/// [SavedListCubit] and [PrivacyCubit] on the own profile. The Categories tab makes its own cubit when it is first
/// shown.
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
            actions: [
              if (own)
                const _SettingsButton()
              else if (profile != null && state.status == ProfileStatus.ready)
                ProfileMenuButton(profile: profile),
            ],
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
      Tab(text: l10n.profileTabCategories),
      Tab(text: l10n.profileTabReposts),
      if (isMe) Tab(text: l10n.profileTabSaved),
      Tab(text: l10n.profileTabPaths),
      Tab(text: l10n.profileTabAbout),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: ProfileHeader(profile: profile, onEdit: onEdit)),
          // A muted writer's profile still opens, with "انت كاتم الكاتب ده" under the header, as on the web; its tabs
          // still list their articles (F28).
          if (!isMe)
            SliverToBoxAdapter(
              child: MutedWriterBanner(
                key: const ValueKey('profile-muted-banner'),
                userId: profile.id,
                name: profile.displayName,
                initiallyMuted: profile.isMuted,
                padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s3),
              ),
            ),
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
            ProfileCategoriesTab(username: profile.username, isMe: isMe, leading: profileTabOverlap),
            ProfileRepostsTab(profile: profile),
            if (isMe) const _ProfileSavedTab(),
            ProfilePathsTab(profile: profile),
            ProfileAboutTab(profile: profile, onEdit: isMe ? onEdit : null),
          ],
        ),
      ),
    );
  }
}

/// The own profile's Saved tab (F14): the saved articles, and the Highlights section (F30) from the switch at its top.
/// The highlights load when the section is first shown.
class _ProfileSavedTab extends StatefulWidget {
  const _ProfileSavedTab();

  @override
  State<_ProfileSavedTab> createState() => _ProfileSavedTabState();
}

class _ProfileSavedTabState extends State<_ProfileSavedTab> {
  bool _highlights = false;

  Widget _leading(BuildContext context) {
    final l10n = context.l10n;
    return SliverMainAxisGroup(
      slivers: [
        profileTabOverlap(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, 0),
          sliver: SliverToBoxAdapter(
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.savedTabArticles), icon: const Icon(Icons.bookmark_border_rounded)),
                ButtonSegment(value: true, label: Text(l10n.highlightSavedTab), icon: const Icon(Icons.border_color_outlined)),
              ],
              selected: {_highlights},
              onSelectionChanged: (v) => setState(() => _highlights = v.first),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<MyHighlightsCubit>()..load(),
        child: _highlights ? SavedHighlightsList(leading: _leading) : SavedArticlesList(leading: _leading),
      );
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
