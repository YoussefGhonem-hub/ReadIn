import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../article/presentation/widgets/article_card_tile.dart';
import '../../../article/presentation/widgets/engagement_seeder.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../../follow/presentation/cubit/suggested_writers_cubit.dart';
import '../../../follow/presentation/widgets/suggested_writers.dart';
import '../../../notifications/presentation/cubit/unread_badge_cubit.dart';
import '../../../paths/presentation/path_routes.dart';
import '../../../paths/presentation/widgets/home_path_card.dart';
import '../../../reading/presentation/widgets/home_streak_badge.dart';
import '../../../saved/presentation/widgets/save_button.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/live_feed_cubit.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/today_hero_card.dart';

/// The two feeds of Home (F03): "For you" and "Following" (F12).
enum HomeFeedTab { forYou, following }

/// Home — "النهارده" (F03).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<HomeCubit>()..load()),
          BlocProvider(create: (_) => getIt<FeedCubit>()..load()),
          // The Following tab and its suggestions load the first time they are shown.
          BlocProvider(create: (_) => getIt<FollowingFeedCubit>()),
          BlocProvider(create: (_) => getIt<SuggestedWritersCubit>()),
          BlocProvider(create: (_) => getIt<LiveFeedCubit>()..start()),
          BlocProvider(create: (_) => getIt<UnreadBadgeCubit>()),
        ],
        child: const HomeView(),
      );
}

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.initialTab = HomeFeedTab.forYou});

  final HomeFeedTab initialTab;

  /// Time source for the morning/evening greeting (overridden in golden tests).
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const _gutter = ReadInSpace.s5;

  late HomeFeedTab _tab = widget.initialTab;
  StreamSubscription<FollowChange>? _followChanges;

  /// Someone was followed or unfollowed since the Following feed loaded.
  bool _followingStale = false;

  @override
  void initState() {
    super.initState();
    _followChanges = context.read<FollowsCubit>().changes.listen((_) {
      if (mounted) setState(() => _followingStale = true);
    });
    if (_tab == HomeFeedTab.following) _showFollowing();
  }

  @override
  void dispose() {
    unawaited(_followChanges?.cancel());
    super.dispose();
  }

  ArticleFeedCubit get _activeFeed =>
      _tab == HomeFeedTab.forYou ? context.read<FeedCubit>() : context.read<FollowingFeedCubit>();

  bool get _signedIn => context.read<SessionCubit>().state.isAuthenticated;

  void _selectTab(HomeFeedTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (tab == HomeFeedTab.following) _showFollowing();
  }

  void _showFollowing() {
    if (!_signedIn) return;
    final feed = context.read<FollowingFeedCubit>();
    if (_followingStale) {
      _followingStale = false;
      unawaited(feed.state.items.isEmpty ? feed.load() : feed.refresh());
    } else {
      unawaited(feed.ensureLoaded());
    }
  }

  void _showFollowedArticles() {
    setState(() => _followingStale = false);
    unawaited(context.read<FollowingFeedCubit>().load());
  }

  Future<void> _refresh() => Future.wait([
        context.read<HomeCubit>().load(refresh: true),
        if (_tab == HomeFeedTab.forYou || _signedIn) _activeFeed.refresh(),
      ]);

  /// Signing in or out changes what every feed shows (reactions, saves, the Following tab).
  void _onSessionChanged() {
    unawaited(context.read<HomeCubit>().load(refresh: true));
    unawaited(context.read<FeedCubit>().load(fieldSlug: context.read<FeedCubit>().state.fieldSlug));
    if (_tab == HomeFeedTab.following && _signedIn) unawaited(context.read<FollowingFeedCubit>().load());
    final suggested = context.read<SuggestedWritersCubit>();
    if (suggested.started && _signedIn) unawaited(suggested.load());
  }

  void _open(String slug) => unawaited(_push('/a/$slug'));

  /// Opens [location] over Home. Back on Home (from the reader or a path), the Continue reading and learning path
  /// cards refresh: reading moved them on (F03).
  Future<void> _push(String location) async {
    final home = context.read<HomeCubit>();
    await context.push<void>(location);
    if (mounted) unawaited(home.refreshProgress());
  }

  void _showNewArticles() {
    context.read<LiveFeedCubit>().acknowledgeNewArticles();
    if (_tab != HomeFeedTab.forYou) setState(() => _tab = HomeFeedTab.forYou);
    unawaited(_refresh());
    final scroll = PrimaryScrollController.maybeOf(context);
    if (scroll != null && scroll.hasClients) {
      unawaited(scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (a, b) => a.status != SessionStatus.unknown && (a.isAuthenticated, a.me?.id) != (b.isAuthenticated, b.me?.id),
          listener: (_, _) => _onSessionChanged(),
        ),
      ],
      child: EngagementSeeder<FeedCubit, FeedState>(
        cards: (state) => state.items,
        child: EngagementSeeder<FollowingFeedCubit, FeedState>(
          cards: (state) => state.items,
          child: Scaffold(
            body: SafeArea(
              bottom: false,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) unawaited(_activeFeed.loadMore());
                  return false;
                },
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          const SliverPadding(
                            padding: EdgeInsets.fromLTRB(_gutter, ReadInSpace.s4, _gutter, ReadInSpace.s4),
                            sliver: SliverToBoxAdapter(child: _HomeHeader()),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: _gutter),
                            sliver: SliverToBoxAdapter(
                              child: BlocBuilder<HomeCubit, HomeState>(
                                builder: (context, state) {
                                  if (state.loading) return const _HeroSkeleton();
                                  final today = state.today;
                                  if (today == null) return const SizedBox.shrink();
                                  return TodayHeroCard(article: today, onTap: () => _open(today.slug));
                                },
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: _gutter),
                            sliver: SliverToBoxAdapter(child: _ProgressCards(onPush: (location) => unawaited(_push(location)))),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(_gutter, ReadInSpace.s4, _gutter, 0),
                            sliver: SliverToBoxAdapter(child: _FeedTabs(selected: _tab, onSelected: _selectTab)),
                          ),
                          if (_tab == HomeFeedTab.forYou) ...[
                            const SliverToBoxAdapter(child: _FieldFilterBar()),
                            _ArticleFeedSliver<FeedCubit>(
                              onOpen: _open,
                              empty: EmptyView(title: context.l10n.feedEmptyTitle, body: context.l10n.feedEmptyBody),
                            ),
                          ] else if (!signedIn)
                            const SliverFillRemaining(hasScrollBody: false, child: _FollowingGuest())
                          else ...[
                            const SliverToBoxAdapter(child: SizedBox(height: ReadInSpace.s3)),
                            _ArticleFeedSliver<FollowingFeedCubit>(
                              onOpen: _open,
                              emptyFillsRemaining: false,
                              empty: FollowingEmptyView(
                                onShowArticles: _followingStale ? _showFollowedArticles : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _NewArticlesBanner(onTap: _showNewArticles),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = context.select((SessionCubit c) => c.state.me);
    final morning = HomeView.clock().hour < 17;
    final greeting = me == null
        ? l10n.greetingGuest
        : morning
            ? l10n.greetingMorning(me.firstName)
            : l10n.greetingEvening(me.firstName);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: context.textTheme.titleLarge?.copyWith(fontSize: 20)),
              const SizedBox(height: 2),
              Text(l10n.greetingSubtitle, style: context.textTheme.bodySmall),
            ],
          ),
        ),
        const HomeStreakBadge(),
        const SizedBox(width: ReadInSpace.s2),
        const _NotificationsButton(),
      ],
    );
  }
}

/// Under Today's article (F03): "Continue reading" (signed in, not the hero's article), then the learning path in
/// progress, or the slim "explore paths" prompt when there is none (and for guests). Nothing while Home loads.
class _ProgressCards extends StatelessWidget {
  const _ProgressCards({required this.onPush});

  /// Opens a location over Home (Home refreshes these cards when it comes back).
  final ValueChanged<String> onPush;

  @override
  Widget build(BuildContext context) => BlocBuilder<HomeCubit, HomeState>(
        buildWhen: (a, b) => (a.loading, a.today?.id, a.resume, a.activePath) != (b.loading, b.today?.id, b.resume, b.activePath),
        builder: (context, state) {
          if (state.loading) return const SizedBox.shrink();
          final resume = state.resume;
          final path = state.activePath;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.today != null) const SizedBox(height: ReadInSpace.s4),
              if (resume != null) ...[
                ContinueReadingCard(
                  item: resume,
                  // The version they were reading; the reader resumes from their last position.
                  onTap: () => onPush(Uri(path: '/a/${resume.article.slug}', queryParameters: {'lang': resume.language}).toString()),
                ),
                const SizedBox(height: ReadInSpace.s3),
              ],
              if (path != null)
                ActivePathCard(
                  path: path,
                  onOpenPath: () => onPush(PathRoutes.of(path.slug)),
                  onOpenNext: (next) => onPush('/a/${next.slug}'),
                )
              else
                PathsPromptRow(onTap: () => onPush(PathRoutes.list)),
            ],
          );
        },
      );
}

/// "For you" | "Following" (F03).
class _FeedTabs extends StatelessWidget {
  const _FeedTabs({required this.selected, required this.onSelected});

  final HomeFeedTab selected;
  final ValueChanged<HomeFeedTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    Widget tab(HomeFeedTab tab, String label) {
      final isSelected = tab == selected;
      return Semantics(
        selected: isSelected,
        button: true,
        child: InkWell(
          onTap: () => onSelected(tab),
          borderRadius: BorderRadius.circular(ReadInRadius.sm),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s1),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isSelected ? colors.primary : Colors.transparent, width: 2)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: context.textTheme.titleMedium?.copyWith(
                color: isSelected ? colors.textPrimary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(HomeFeedTab.forYou, l10n.feedForYou),
        const SizedBox(width: ReadInSpace.s5),
        tab(HomeFeedTab.following, l10n.feedFollowing),
      ],
    );
  }
}

/// A feed's cards, skeleton, empty and error states and the load-more footer.
class _ArticleFeedSliver<C extends ArticleFeedCubit> extends StatelessWidget {
  const _ArticleFeedSliver({required this.onOpen, required this.empty, this.emptyFillsRemaining = true});

  final ValueChanged<String> onOpen;
  final Widget empty;

  /// Centre [empty] in the space left (a message), or let it scroll at its own height (a list of suggestions).
  final bool emptyFillsRemaining;

  static const _gutter = EdgeInsets.symmetric(horizontal: ReadInSpace.s5);

  @override
  Widget build(BuildContext context) => BlocBuilder<C, FeedState>(
        builder: (context, feed) => switch (feed.status) {
          FeedStatus.loading => const SliverPadding(padding: _gutter, sliver: SliverToBoxAdapter(child: _FeedSkeleton())),
          FeedStatus.failure => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                failure: feed.failure!,
                compact: true,
                onRetry: () => context.read<C>().load(fieldSlug: feed.fieldSlug),
              ),
            ),
          FeedStatus.ready when feed.items.isEmpty => emptyFillsRemaining
              ? SliverFillRemaining(hasScrollBody: false, child: empty)
              : SliverToBoxAdapter(child: empty),
          FeedStatus.ready => SliverPadding(
              padding: _gutter,
              sliver: SliverList.builder(
                itemCount: feed.items.length + 1,
                itemBuilder: (context, i) => i < feed.items.length
                    ? _LiveArticleTile(article: feed.items[i], onTap: () => onOpen(feed.items[i].slug))
                    : _FeedFooter(state: feed, onRetry: context.read<C>().loadMore),
              ),
            ),
        },
      );
}

/// The Following tab with nobody followed yet: suggested writers to follow (F12).
class FollowingEmptyView extends StatelessWidget {
  const FollowingEmptyView({super.key, this.onShowArticles});

  /// Set once someone was followed here: loads their articles.
  final VoidCallback? onShowArticles;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, ReadInSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(ReadInSpace.s4),
            decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.card)),
            child: Row(
              children: [
                Icon(Icons.group_add_outlined, color: colors.onPrimaryContainer, size: 28),
                const SizedBox(width: ReadInSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.followingEmptyTitle, style: context.textTheme.titleSmall?.copyWith(color: colors.onPrimaryContainer)),
                      const SizedBox(height: ReadInSpace.s1),
                      Text(l10n.followingEmptyBody, style: context.textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ReadInSpace.s5),
          const SuggestedWritersList(),
          if (onShowArticles != null) ...[
            const SizedBox(height: ReadInSpace.s4),
            FilledButton(onPressed: onShowArticles, child: Text(l10n.showFollowingArticles)),
          ],
        ],
      ),
    );
  }
}

class _FollowingGuest extends StatelessWidget {
  const _FollowingGuest();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyView(
      icon: Icons.group_outlined,
      title: l10n.followingGuestTitle,
      body: l10n.followingGuestBody,
      action: Column(
        children: [
          FilledButton(onPressed: () => context.push('/auth/sign-up'), child: Text(l10n.signUp)),
          const SizedBox(height: ReadInSpace.s2),
          TextButton(onPressed: () => context.push('/auth/sign-in'), child: Text(l10n.signIn)),
        ],
      ),
    );
  }
}

/// "مقالات جديدة ↑" once an article is published after the feed was loaded (F27).
class _NewArticlesBanner extends StatelessWidget {
  const _NewArticlesBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visible = context.select((LiveFeedCubit c) => c.state.hasNewArticles);
    if (!visible) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: ReadInSpace.s3),
        child: FilledButton(onPressed: onTap, child: Text(context.l10n.feedNewArticles)),
      ),
    );
  }
}

/// A feed card with the newest counters and the viewer's save (F13), live while the list keeps it built (on or near
/// the screen, F27). [LiveFeedCubit] owns the subscription; its values go to [EngagementCubit], where they replace
/// the counts.
class _LiveArticleTile extends StatefulWidget {
  const _LiveArticleTile({required this.article, required this.onTap});

  final ArticleCard article;
  final VoidCallback onTap;

  @override
  State<_LiveArticleTile> createState() => _LiveArticleTileState();
}

class _LiveArticleTileState extends State<_LiveArticleTile> {
  late final LiveFeedCubit _live = context.read<LiveFeedCubit>();

  @override
  void initState() {
    super.initState();
    _live.watch(widget.article.id);
  }

  @override
  void didUpdateWidget(_LiveArticleTile old) {
    super.didUpdateWidget(old);
    if (old.article.id != widget.article.id) {
      _live
        ..unwatch(old.article.id)
        ..watch(widget.article.id);
    }
  }

  @override
  void dispose() {
    _live.unwatch(widget.article.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.article.id;
    final engagement = context.select((EngagementCubit c) => c.state.of(widget.article));
    return BlocListener<LiveFeedCubit, LiveFeedState>(
      listenWhen: (a, b) => b.counts[id] != null && !identical(a.counts[id], b.counts[id]),
      listener: (context, state) => context.read<EngagementCubit>().applyLive(id, state.counts[id]!),
      child: ArticleCardTile(
        article: engagement.applyTo(widget.article),
        onTap: widget.onTap,
        actions: [SaveToggleButton(article: widget.article)],
      ),
    );
  }
}

/// The bell with the live unread count (F27).
class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unread = context.watch<UnreadBadgeCubit>().state;
    const bell = Icon(Icons.notifications_none_rounded);
    return IconButton.outlined(
      tooltip: unread > 0 ? l10n.notificationsUnread(unread) : l10n.notifications,
      onPressed: () => context.push('/notifications'),
      // No badge at 0, so the bell looks exactly as before.
      icon: unread > 0 ? Badge(label: Text(unread > 9 ? '9+' : '$unread'), child: bell) : bell,
      style: IconButton.styleFrom(side: BorderSide(color: context.colors.border)),
    );
  }
}

class _FieldFilterBar extends StatelessWidget {
  const _FieldFilterBar();

  @override
  Widget build(BuildContext context) {
    final fields = context.select((HomeCubit c) => c.state.fields);
    final selected = context.select((FeedCubit c) => c.state.fieldSlug);
    final lang = Localizations.localeOf(context).languageCode;
    final colors = context.colors;

    Widget chip(String label, String? slug) {
      final isSelected = selected == slug;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s2),
        child: ChoiceChip(
          label: BidiText(label),
          selected: isSelected,
          onSelected: (_) => context.read<FeedCubit>().selectField(slug),
          selectedColor: colors.primary,
          labelStyle: context.textTheme.labelMedium?.copyWith(
            color: isSelected ? colors.onPrimary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(color: isSelected ? colors.primary : colors.border),
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s3),
        children: [
          chip(context.l10n.filterAll, null),
          for (final f in fields) chip(f.nameFor(lang), f.slug),
        ],
      ),
    );
  }
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter({required this.state, required this.onRetry});

  final FeedState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (state.loadingMore) {
      child = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5));
    } else if (state.loadMoreFailure != null) {
      child = ErrorView(failure: state.loadMoreFailure!, compact: true, onRetry: onRetry);
    } else if (!state.hasMore) {
      child = Text(context.l10n.endOfFeed, style: context.textTheme.bodySmall);
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s5),
      child: Center(child: child),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) => const Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 128, radius: 0),
            Padding(
              padding: EdgeInsets.all(ReadInSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120),
                  SizedBox(height: ReadInSpace.s3),
                  SkeletonBox(height: 18),
                  SizedBox(height: ReadInSpace.s2),
                  SkeletonBox(width: 200, height: 18),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: ReadInSpace.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 64, height: 64, radius: ReadInRadius.md),
                  SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 70),
                        SizedBox(height: ReadInSpace.s2),
                        SkeletonBox(),
                        SizedBox(height: ReadInSpace.s2),
                        SkeletonBox(width: 140),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}
