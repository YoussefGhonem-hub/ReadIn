import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/presentation/cubit/post_cards_cubit.dart';
import '../../../article/presentation/widgets/engagement_seeder.dart';
import '../../../article/presentation/widgets/post_card.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../../mutes/presentation/widgets/mute_gate.dart';
import '../../domain/entities/explore.dart';
import '../cubit/explore_cubit.dart';
import '../widgets/explore_widgets.dart';

/// "Trending this week" or "Most saved" in full (F15, "See all" on Explore): post cards (F34) with pull to refresh and
/// infinite scroll, above the tabs.
class ExploreRankingPage extends StatelessWidget {
  const ExploreRankingPage({super.key, required this.ranking});

  final ExploreRanking ranking;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<ExploreRankingCubit>(param1: ranking)..load()),
          // The expanded post cards, kept while the reader is open (F34).
          BlocProvider(create: (_) => getIt<PostCardsCubit>()),
        ],
        child: const ExploreRankingView(),
      );
}

/// The ranking once its [ExploreRankingCubit] and [PostCardsCubit] are provided.
class ExploreRankingView extends StatelessWidget {
  const ExploreRankingView({super.key});

  /// Pull to refresh: the first page again, and the cards collapsed (F34).
  static Future<void> _refresh(BuildContext context) {
    context.read<PostCardsCubit?>()?.reset();
    return context.read<ExploreRankingCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ExploreRankingCubit>();
    final (title, emptyTitle) = switch (cubit.ranking) {
      ExploreRanking.trending => (l10n.exploreTrending, l10n.exploreTrendingEmptyTitle),
      ExploreRanking.mostSaved => (l10n.exploreMostSaved, l10n.exploreMostSavedEmptyTitle),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // Opened with no page under it: back goes to Explore, so the user is never stuck here.
        leading: Navigator.of(context).canPop()
            ? null
            : IconButton(
                key: const ValueKey('explore-ranking-back'),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const BackButtonIcon(),
                onPressed: () => GoRouter.maybeOf(context)?.go('/explore'),
              ),
      ),
      body: EngagementSeeder<ExploreRankingCubit, FeedState>(
        cards: (state) => state.items,
        child: BlocBuilder<ExploreRankingCubit, FeedState>(
          builder: (context, feed) {
            // Mutes and "show less" can fold away every card loaded (F28): the next page loads by itself, and once
            // none is left the page says it's empty.
            final allHidden = mutesHideAll(context, feed.items);
            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) unawaited(cubit.loadMore());
                  return false;
                },
                child: CustomScrollView(
                  key: PageStorageKey('explore-${cubit.ranking.path}'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    ...switch (feed.status) {
                      FeedStatus.loading => [
                          SliverList.list(children: [
                            for (var i = 0; i < 2; i++)
                              const Padding(padding: EdgeInsets.only(bottom: postCardGap), child: PostCardSkeleton()),
                          ]),
                        ],
                      FeedStatus.failure => [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: ErrorView(failure: feed.failure!, onRetry: () => unawaited(cubit.load())),
                          ),
                        ],
                      FeedStatus.ready when feed.items.isEmpty || (allHidden && !feed.hasMore) => [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyView(
                              icon: Icons.local_fire_department_outlined,
                              title: emptyTitle,
                              body: l10n.exploreRankingEmptyBody,
                            ),
                          ),
                        ],
                      // Post cards full width, one after another on the background (F34).
                      FeedStatus.ready => [
                          SliverList.builder(
                            itemCount: feed.items.length + 1,
                            itemBuilder: (context, i) => i < feed.items.length
                                // Mutes and "show less" fold the card away at once (F28).
                                ? MuteGate(
                                    article: feed.items[i],
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: postCardGap),
                                      child: PostCard(key: ValueKey('ranking-card-${feed.items[i].id}'), article: feed.items[i]),
                                    ),
                                  )
                                : LoadMoreWhileHidden(
                                    active: allHidden && !feed.loadingMore && feed.loadMoreFailure == null,
                                    onLoadMore: () => unawaited(cubit.loadMore()),
                                    child: ExploreListFooter(
                                      loadingMore: feed.loadingMore,
                                      failure: feed.loadMoreFailure,
                                      onRetry: () => unawaited(cubit.loadMore()),
                                    ),
                                  ),
                          ),
                        ],
                    },
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
