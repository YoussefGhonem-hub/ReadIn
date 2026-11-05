import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/presentation/widgets/engagement_seeder.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../paths/presentation/path_routes.dart';
import '../../../paths/presentation/widgets/path_widgets.dart';
import '../../../search/presentation/widgets/search_entry_bar.dart';
import '../../domain/entities/explore.dart';
import '../cubit/explore_cubit.dart';
import '../explore_routes.dart';
import '../widgets/explore_widgets.dart';

/// The Explore tab (F15), guests too: the search bar (F16), then the fields (each opens its field page, where the
/// topics are), "Trending this week" and "Most saved" (a few rows each, "See all" opens the full list as post cards),
/// new writers with Follow, and the featured learning paths. A section with nothing in it is hidden.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ExploreCubit>()..load(),
        child: const ExploreView(),
      );
}

/// Explore once its [ExploreCubit] is provided.
class ExploreView extends StatelessWidget {
  const ExploreView({super.key});

  /// The rows a ranking shows here; "See all" has the rest.
  static const previewCount = 3;

  static const _gutter = ReadInSpace.s5;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExploreCubit>();
    return BlocListener<SessionCubit, SessionState>(
      // Signing in or out changes the viewer's reactions, saves, follows and path progress on every section.
      listenWhen: (a, b) =>
          a.status != SessionStatus.unknown && (a.isAuthenticated, a.me?.id) != (b.isAuthenticated, b.me?.id),
      listener: (_, _) => unawaited(cubit.load()),
      child: EngagementSeeder<ExploreCubit, ExploreState>(
        cards: (state) => [...state.sections.trending, ...state.sections.mostSaved],
        child: Scaffold(
          appBar: AppBar(title: Text(context.l10n.navExplore), automaticallyImplyLeading: false),
          body: BlocBuilder<ExploreCubit, ExploreState>(
            builder: (context, state) => RefreshIndicator(
              onRefresh: cubit.refresh,
              child: CustomScrollView(
                key: const PageStorageKey('explore'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(_gutter, ReadInSpace.s2, _gutter, ReadInSpace.s2),
                    sliver: SliverToBoxAdapter(child: SearchEntryBar()),
                  ),
                  ...switch (state.status) {
                    ExploreStatus.loading => [const SliverToBoxAdapter(child: _ExploreSkeleton())],
                    ExploreStatus.failure => [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load())),
                        ),
                      ],
                    ExploreStatus.ready when state.sections.isEmpty => [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyView(
                            icon: Icons.explore_outlined,
                            title: context.l10n.exploreEmptyTitle,
                            body: context.l10n.exploreEmptyBody,
                          ),
                        ),
                      ],
                    ExploreStatus.ready => [
                        // Each section keeps the gutter itself: the writers' rail runs to the screen's edges.
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: ReadInSpace.s7),
                          sliver: SliverList.list(children: _sections(context, state.sections)),
                        ),
                      ],
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static List<Widget> _sections(BuildContext context, ExploreSections sections) {
    final l10n = context.l10n;
    void push(String location) => unawaited(GoRouter.maybeOf(context)?.push<void>(location));
    Widget padded(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: _gutter), child: child);
    const gap = SizedBox(height: ReadInSpace.s5);
    return [
      if (sections.fields.isNotEmpty) ...[
        padded(ExploreSectionHeader(title: l10n.exploreFields)),
        const SizedBox(height: ReadInSpace.s1),
        padded(FieldsGrid(key: const ValueKey('explore-fields'), fields: sections.fields)),
        gap,
      ],
      for (final (ranking, cards, title) in [
        (ExploreRanking.trending, sections.trending, l10n.exploreTrending),
        (ExploreRanking.mostSaved, sections.mostSaved, l10n.exploreMostSaved),
      ])
        if (cards.isNotEmpty) ...[
          padded(ExploreSectionHeader(
            title: title,
            seeAllKey: ValueKey('explore-see-all-${ranking.path}'),
            onSeeAll: () => push(ExploreRoutes.ranking(ranking)),
          )),
          for (final card in cards.take(previewCount)) padded(ExploreArticleRow(article: card)),
          gap,
        ],
      if (sections.newWriters.isNotEmpty) ...[
        padded(ExploreSectionHeader(title: l10n.exploreNewWriters)),
        WriterRail(
          key: const ValueKey('explore-new-writers'),
          users: sections.newWriters,
          label: l10n.exploreNewWriters,
          keyPrefix: 'explore-writer',
          padding: const EdgeInsets.symmetric(horizontal: _gutter),
        ),
        gap,
      ],
      // No featured path: the section is hidden like any other (Home and the profile lead to /paths).
      if (sections.featuredPaths.isNotEmpty) ...[
        padded(ExploreSectionHeader(
          title: l10n.exploreFeaturedPaths,
          seeAllKey: const ValueKey('explore-see-all-paths'),
          onSeeAll: () => push(PathRoutes.list),
        )),
        const SizedBox(height: ReadInSpace.s1),
        for (final path in sections.featuredPaths)
          padded(Padding(
            padding: const EdgeInsets.only(bottom: ReadInSpace.s3),
            child: PathCardTile(
              key: ValueKey('explore-path-${path.slug}'),
              path: path,
              onTap: () => push(PathRoutes.of(path.slug)),
            ),
          )),
      ],
    ];
  }
}

/// Every section's shape while Explore loads.
class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  static const _padding = EdgeInsets.symmetric(horizontal: ExploreView._gutter);

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('explore-skeleton'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: _padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExploreSkeletons.title,
                ExploreSkeletons.fields(),
                const SizedBox(height: ReadInSpace.s3),
                ExploreSkeletons.title,
                ExploreSkeletons.rows(),
                const SizedBox(height: ReadInSpace.s3),
                ExploreSkeletons.title,
              ],
            ),
          ),
          // The writers' rail runs to the screen's edges.
          ExploreSkeletons.writers(padding: _padding),
        ],
      );
}
