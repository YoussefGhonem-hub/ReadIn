import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/widgets/article_card_tile.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../notifications/presentation/cubit/unread_badge_cubit.dart';
import '../cubit/feed_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/live_feed_cubit.dart';
import '../widgets/today_hero_card.dart';

/// Home — "النهارده" (F03).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<HomeCubit>()..load()),
          BlocProvider(create: (_) => getIt<FeedCubit>()..load()),
          BlocProvider(create: (_) => getIt<LiveFeedCubit>()..start()),
          BlocProvider(create: (_) => getIt<UnreadBadgeCubit>()),
        ],
        child: const HomeView(),
      );
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const _gutter = ReadInSpace.s5;

  /// Time source for the morning/evening greeting (overridden in golden tests).
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  Future<void> _refresh(BuildContext context) =>
      Future.wait([context.read<HomeCubit>().load(refresh: true), context.read<FeedCubit>().refresh()]);

  void _open(BuildContext context, String slug) => context.push('/a/$slug');

  void _showNewArticles(BuildContext context) {
    context.read<LiveFeedCubit>().acknowledgeNewArticles();
    unawaited(_refresh(context));
    final scroll = PrimaryScrollController.maybeOf(context);
    if (scroll != null && scroll.hasClients) {
      unawaited(scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) {
              context.read<FeedCubit>().loadMore();
            }
            return false;
          },
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => _refresh(context),
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
                            return TodayHeroCard(article: today, onTap: () => _open(context, today.slug));
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: _FieldFilterBar()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, ReadInSpace.s2),
                      sliver: SliverToBoxAdapter(
                        child: Text(context.l10n.feedForYou, style: context.textTheme.titleMedium),
                      ),
                    ),
                    BlocBuilder<FeedCubit, FeedState>(
                      builder: (context, feed) => switch (feed.status) {
                        FeedStatus.loading => const SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: _gutter),
                            sliver: SliverToBoxAdapter(child: _FeedSkeleton()),
                          ),
                        FeedStatus.failure => SliverFillRemaining(
                            hasScrollBody: false,
                            child: ErrorView(
                              failure: feed.failure!,
                              compact: true,
                              onRetry: () => context.read<FeedCubit>().load(fieldSlug: feed.fieldSlug),
                            ),
                          ),
                        FeedStatus.ready when feed.items.isEmpty => SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyView(title: context.l10n.feedEmptyTitle, body: context.l10n.feedEmptyBody),
                          ),
                        FeedStatus.ready => SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: _gutter),
                            sliver: SliverList.builder(
                              itemCount: feed.items.length + 1,
                              itemBuilder: (context, i) => i < feed.items.length
                                  ? _LiveArticleTile(article: feed.items[i], onTap: () => _open(context, feed.items[i].slug))
                                  : _FeedFooter(state: feed),
                            ),
                          ),
                      },
                    ),
                  ],
                ),
              ),
              _NewArticlesBanner(onTap: () => _showNewArticles(context)),
            ],
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
        const StreakBadge(days: 0),
        const SizedBox(width: ReadInSpace.s2),
        const _NotificationsButton(),
      ],
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

/// A feed card with live counters while the list keeps it built (on or near the screen).
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
    final live = context.select((LiveFeedCubit c) => c.state.counts[widget.article.id]);
    final article = live == null
        ? widget.article
        : widget.article.withCounts(reactionCount: live.reactionCount, commentCount: live.commentCount);
    return ArticleCardTile(article: article, onTap: widget.onTap);
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
  const _FeedFooter({required this.state});

  final FeedState state;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (state.loadingMore) {
      child = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5));
    } else if (state.loadMoreFailure != null) {
      child = ErrorView(failure: state.loadMoreFailure!, compact: true, onRetry: context.read<FeedCubit>().loadMore);
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
