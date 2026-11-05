import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
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
import '../../../article/presentation/cubit/post_cards_cubit.dart';
import '../../../article/presentation/widgets/engagement_seeder.dart';
import '../../../article/presentation/widgets/post_card.dart';
import '../../../auth/domain/entities/me.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../../follow/presentation/cubit/suggested_writers_cubit.dart';
import '../../../follow/presentation/widgets/suggested_writers.dart';
import '../../../follow/presentation/widgets/suggested_writers_carousel.dart';
import '../../../mutes/presentation/widgets/mute_gate.dart';
import '../../../paths/presentation/path_routes.dart';
import '../../../paths/presentation/widgets/home_path_card.dart';
import '../../../paths/presentation/widgets/suggested_path_card.dart';
import '../../../reading/presentation/widgets/home_streak_badge.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/live_feed_cubit.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/home_side_column.dart';
import '../widgets/start_post_card.dart';

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
          // The Following tab and the suggestions (its empty state, For you's "Add to your feed", the side column)
          // load the first time they are shown.
          BlocProvider(create: (_) => getIt<FollowingFeedCubit>()),
          BlocProvider(create: (_) => getIt<SuggestedWritersCubit>()),
          BlocProvider(create: (_) => getIt<LiveFeedCubit>()..start()),
          // The expanded post cards of every list on Home, kept while the reader or a profile is open (F34).
          BlocProvider(create: (_) => getIt<PostCardsCubit>()),
          // The top bar's unread count comes from the tab shell (MainShell), as on Explore and Saved.
        ],
        child: const HomeView(),
      );
}

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.initialTab = HomeFeedTab.forYou});

  final HomeFeedTab initialTab;

  /// From this width (tablets) Home has two columns: the feed, and [HomeSideColumn] beside it.
  static const twoColumnWidth = 840.0;

  /// "Add to your feed" comes after this many cards of For you (on phones; tablets have it in the side column).
  static const suggestedWritersAfter = 3;

  /// The suggested path comes after this many cards of For you when a path in progress has its place above.
  static const suggestedPathAfter = 8;

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

  /// Pull to refresh: the cards show collapsed again (F34); unsent comments stay.
  Future<void> _refresh() {
    context.read<PostCardsCubit?>()?.reset();
    return Future.wait([
      context.read<HomeCubit>().load(refresh: true),
      if (_tab == HomeFeedTab.forYou || _signedIn) _activeFeed.refresh(),
    ]);
  }

  static bool _sameInterests(Me? a, Me? b) =>
      a == null ||
      b == null ||
      (setEquals(a.interestFieldIds.toSet(), b.interestFieldIds.toSet()) &&
          setEquals(a.interestTopicIds.toSet(), b.interestTopicIds.toSet()));

  /// Signing in or out changes what every feed shows (reactions, saves, the Following tab), and so do new interests.
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

  /// What comes after card [index] of For you: "Add to your feed" (signed in, on phones), and the suggested path when
  /// a path in progress has the place above.
  Widget? _afterCard(int index, {required bool signedIn, required bool wide}) {
    if (index == HomeView.suggestedWritersAfter - 1 && signedIn && !wide) {
      return SuggestedWritersCarousel(
        margin: const EdgeInsets.only(bottom: postCardGap),
        // Explore is a tab: switch to it.
        onSeeAll: () => GoRouter.maybeOf(context)?.go('/explore'),
      );
    }
    if (index == HomeView.suggestedPathAfter - 1) return _FeedSuggestedPath(onPush: (location) => unawaited(_push(location)));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    final me = context.select((SessionCubit c) => c.state.isAuthenticated ? c.state.me : null);
    // Tablets: the profile card, this week's reading and suggestions in a column beside the feed.
    final wide = MediaQuery.sizeOf(context).width >= HomeView.twoColumnWidth;
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionCubit, SessionState>(
          // New interests (Settings → Your interests) change For you and the suggestions too.
          listenWhen: (a, b) =>
              a.status != SessionStatus.unknown &&
              ((a.isAuthenticated, a.me?.id) != (b.isAuthenticated, b.me?.id) || !_sameInterests(a.me, b.me)),
          listener: (_, _) => _onSessionChanged(),
        ),
      ],
      child: EngagementSeeder<FeedCubit, FeedState>(
        cards: (state) => state.items,
        child: EngagementSeeder<FollowingFeedCubit, FeedState>(
          cards: (state) => state.items,
          child: Scaffold(
            // The avatar (Me), search, the light / dark toggle and the bell, as on Explore and Saved.
            appBar: const AppTopBar(),
            body: SafeArea(
              bottom: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _feed(signedIn: signedIn, me: me, wide: wide)),
                  if (wide) const SizedBox(width: HomeSideColumn.width, child: HomeSideColumn()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The feed column: the header, Start a post, Today's article, the progress cards, the tabs and their feed.
  Widget _feed({required bool signedIn, required Me? me, required bool wide}) =>
      NotificationListener<ScrollNotification>(
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
                  // "Start a post" (signed-in writers): the editor, one tap away.
                  if (me != null && me.canWrite)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, ReadInSpace.s4),
                      sliver: SliverToBoxAdapter(child: StartPostCard(me: me)),
                    ),
                  // Today's article (F07) as a post card under its label, full width (F34).
                  SliverToBoxAdapter(
                    child: EngagementSeeder<HomeCubit, HomeState>(
                      cards: (state) => [?state.today],
                      child: BlocBuilder<HomeCubit, HomeState>(
                        buildWhen: (a, b) => (a.loading, a.today) != (b.loading, b.today),
                        builder: (context, state) {
                          if (state.loading) return const PostCardSkeleton();
                          final today = state.today;
                          if (today == null) return const SizedBox.shrink();
                          // Muting its writer, field or topic, or "show less", folds it away (F28).
                          return MuteGate(
                            article: today,
                            child: _LiveArticleTile(
                              article: today,
                              label: context.l10n.todayArticle,
                              onTap: () => _open(today.slug),
                            ),
                          );
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
                      after: (index) => _afterCard(index, signedIn: signedIn, wide: wide),
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
      );
}

/// The header says "good morning" from 5 AM until noon and "good evening" otherwise, as on the web.
bool greetsMorning(DateTime now) => now.hour >= 5 && now.hour < 12;

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = context.select((SessionCubit c) => c.state.me);
    final morning = greetsMorning(HomeView.clock());
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
        // The bell is in the top bar.
        const HomeStreakBadge(),
      ],
    );
  }
}

/// Under Today's article (F03): "Continue reading" (signed in, not the hero's article), then the learning path in
/// progress; without one (and for guests) a suggested path to start, or the slim "explore paths" prompt when there is
/// none to suggest. Nothing while Home loads.
class _ProgressCards extends StatelessWidget {
  const _ProgressCards({required this.onPush});

  /// Opens a location over Home (Home refreshes these cards when it comes back).
  final ValueChanged<String> onPush;

  @override
  Widget build(BuildContext context) => BlocBuilder<HomeCubit, HomeState>(
        buildWhen: (a, b) =>
            (a.loading, a.today?.id, a.resume, a.activePath, a.suggestedPath) !=
            (b.loading, b.today?.id, b.resume, b.activePath, b.suggestedPath),
        builder: (context, state) {
          if (state.loading) return const SizedBox.shrink();
          final resume = state.resume;
          final path = state.activePath;
          final suggested = state.suggestedPath;
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
              else if (suggested != null)
                SuggestedPathCard(
                  path: suggested,
                  onOpenPath: () => onPush(PathRoutes.of(suggested.slug)),
                  onSeeAll: () => onPush(PathRoutes.list),
                )
              else
                PathsPromptRow(onTap: () => onPush(PathRoutes.list)),
            ],
          );
        },
      );
}

/// The suggested path further down For you (after [HomeView.suggestedPathAfter] cards), for readers whose path in
/// progress has the place above.
class _FeedSuggestedPath extends StatelessWidget {
  const _FeedSuggestedPath({required this.onPush});

  final ValueChanged<String> onPush;

  @override
  Widget build(BuildContext context) {
    final (active, suggested) = context.select((HomeCubit c) => (c.state.activePath, c.state.suggestedPath));
    if (active == null || suggested == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, ReadInSpace.s2 + postCardGap),
      child: SuggestedPathCard(
        key: const ValueKey('feed-suggested-path'),
        path: suggested,
        onOpenPath: () => onPush(PathRoutes.of(suggested.slug)),
        onSeeAll: () => onPush(PathRoutes.list),
      ),
    );
  }
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
  const _ArticleFeedSliver({required this.onOpen, required this.empty, this.emptyFillsRemaining = true, this.after});

  final ValueChanged<String> onOpen;
  final Widget empty;

  /// Centre [empty] in the space left (a message), or let it scroll at its own height (a list of suggestions).
  final bool emptyFillsRemaining;

  /// A block to show after the card at an index (suggestions), or null. It stays when that card is muted away.
  final Widget? Function(int index)? after;

  Widget _card(FeedState feed, int i) {
    final article = feed.items[i];
    // Mutes and "show less" fold the card away at once, and Undo brings it back in place (F28).
    final card = MuteGate(
      key: ValueKey('feed-${article.id}'),
      article: article,
      child: Padding(
        padding: const EdgeInsets.only(bottom: postCardGap),
        child: _LiveArticleTile(article: article, onTap: () => onOpen(article.slug)),
      ),
    );
    final extra = after?.call(i);
    return extra == null ? card : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [card, extra]);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<C, FeedState>(
        builder: (context, feed) {
          // Mutes and "show less" can fold away every card loaded (F28): then the next page loads by itself, and once
          // none is left the list says it's empty.
          final allHidden = mutesHideAll(context, feed.items);
          return switch (feed.status) {
            FeedStatus.loading => const SliverToBoxAdapter(child: _FeedSkeleton()),
            FeedStatus.failure => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  failure: feed.failure!,
                  compact: true,
                  onRetry: () => context.read<C>().load(fieldSlug: feed.fieldSlug),
                ),
              ),
            FeedStatus.ready when feed.items.isEmpty || (allHidden && !feed.hasMore) => emptyFillsRemaining
                ? SliverFillRemaining(hasScrollBody: false, child: empty)
                : SliverToBoxAdapter(child: empty),
            // Post cards full width, one after another on the background (F34).
            FeedStatus.ready => SliverList.builder(
                itemCount: feed.items.length + 1,
                itemBuilder: (context, i) => i < feed.items.length
                    ? _card(feed, i)
                    : LoadMoreWhileHidden(
                        active: allHidden && !feed.loadingMore && feed.loadMoreFailure == null,
                        onLoadMore: () => unawaited(context.read<C>().loadMore()),
                        child: _FeedFooter(state: feed, onRetry: context.read<C>().loadMore),
                      ),
              ),
          };
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

/// A post card (F34) with the newest counters and the viewer's reaction and save, live while the list keeps it built
/// (on or near the screen, F27). [LiveFeedCubit] owns the subscription; its values go to [EngagementCubit], where
/// they replace the counts.
class _LiveArticleTile extends StatefulWidget {
  const _LiveArticleTile({required this.article, required this.onTap, this.label});

  final ArticleCard article;
  final VoidCallback onTap;

  /// "مقال النهارده" on Today's article.
  final String? label;

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
    return BlocListener<LiveFeedCubit, LiveFeedState>(
      listenWhen: (a, b) => b.counts[id] != null && !identical(a.counts[id], b.counts[id]),
      listener: (context, state) => context.read<EngagementCubit>().applyLive(id, state.counts[id]!),
      child: PostCard(article: widget.article, label: widget.label, onOpen: widget.onTap),
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

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: postCardGap), child: PostCardSkeleton()),
        ],
      );
}
