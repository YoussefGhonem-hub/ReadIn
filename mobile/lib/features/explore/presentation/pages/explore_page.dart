import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/presentation/widgets/engagement_seeder.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../home/presentation/widgets/app_top_bar.dart';
import '../../../paths/presentation/path_routes.dart';
import '../../../paths/presentation/widgets/path_widgets.dart';
import '../../domain/entities/explore.dart';
import '../cubit/explore_cubit.dart';
import '../explore_routes.dart';
import '../widgets/explore_widgets.dart';

/// The Explore tab (F15), guests too: the top bar's search (F16), then the fields (each opens its field page, where the
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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExploreCubit>();
    return BlocListener<SessionCubit, SessionState>(
      // Signing in or out changes the viewer's reactions, saves, follows and path progress on every section.
      listenWhen: (a, b) =>
          a.status != SessionStatus.unknown && (a.isAuthenticated, a.me?.id) != (b.isAuthenticated, b.me?.id),
      listener: (_, _) => unawaited(cubit.load()),
      child: EngagementSeeder<ExploreCubit, ExploreState>(
        cards: (state) => [...state.sections.featuredArticles, ...state.sections.trending, ...state.sections.mostSaved],
        child: Scaffold(
          // The tabs' top bar: its search pill is Explore's search (F16).
          appBar: const AppTopBar(),
          body: BlocBuilder<ExploreCubit, ExploreState>(
            builder: (context, state) => RefreshIndicator(
              onRefresh: cubit.refresh,
              child: CustomScrollView(
                key: const PageStorageKey('explore'),
                physics: const AlwaysScrollableScrollPhysics(),
                // Every section is a full-width block on the canvas, a gap apart (LinkedIn style); the loading,
                // error and empty states too.
                slivers: [
                  ...switch (state.status) {
                    ExploreStatus.loading => [const SliverToBoxAdapter(child: _ExploreSkeleton())],
                    ExploreStatus.failure => [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: PageBlock(
                            margin: _blockGap,
                            child: ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load())),
                          ),
                        ),
                      ],
                    ExploreStatus.ready when state.sections.isEmpty => [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: PageBlock(
                            margin: _blockGap,
                            child: EmptyView(
                              icon: Icons.explore_outlined,
                              title: context.l10n.exploreEmptyTitle,
                              body: context.l10n.exploreEmptyBody,
                            ),
                          ),
                        ),
                      ],
                    ExploreStatus.ready => [
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
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
    Widget padded(Widget child) => Padding(padding: PageBlock.gutters, child: child);
    return [
      if (sections.fields.isNotEmpty)
        _SectionBlock(
          header: ExploreSectionHeader(title: l10n.exploreFields),
          children: [padded(FieldsGrid(key: const ValueKey('explore-fields'), fields: sections.fields))],
        ),
      // The articles the SuperAdmin featured (F23); none hides the section.
      if (sections.featuredArticles.isNotEmpty)
        _SectionBlock(
          header: ExploreSectionHeader(title: l10n.adminExploreFeatured),
          children: [
            for (final card in sections.featuredArticles)
              padded(ExploreArticleRow(key: ValueKey('explore-featured-${card.id}'), article: card)),
          ],
        ),
      for (final (ranking, cards, title) in [
        (ExploreRanking.trending, sections.trending, l10n.exploreTrending),
        (ExploreRanking.mostSaved, sections.mostSaved, l10n.exploreMostSaved),
      ])
        if (cards.isNotEmpty)
          // The rows split by their own top lines.
          _SectionBlock(
            header: ExploreSectionHeader(
              title: title,
              seeAllKey: ValueKey('explore-see-all-${ranking.path}'),
              onSeeAll: () => push(ExploreRoutes.ranking(ranking)),
            ),
            children: [for (final card in cards.take(previewCount)) padded(ExploreArticleRow(article: card))],
          ),
      if (sections.newWriters.isNotEmpty)
        _SectionBlock(
          header: ExploreSectionHeader(title: l10n.exploreNewWriters),
          children: [
            // The rail runs to the screen's edges.
            WriterRail(
              key: const ValueKey('explore-new-writers'),
              users: sections.newWriters,
              label: l10n.exploreNewWriters,
              keyPrefix: 'explore-writer',
              padding: PageBlock.gutters,
            ),
          ],
        ),
      // No featured path: the section is hidden like any other (Home and the profile lead to /paths).
      if (sections.featuredPaths.isNotEmpty)
        _SectionBlock(
          header: ExploreSectionHeader(
            title: l10n.exploreFeaturedPaths,
            seeAllKey: const ValueKey('explore-see-all-paths'),
            onSeeAll: () => push(PathRoutes.list),
          ),
          children: [
            for (final path in sections.featuredPaths) ...[
              const Divider(indent: PageBlock.gutter, endIndent: PageBlock.gutter),
              PathCardTile(
                key: ValueKey('explore-path-${path.slug}'),
                path: path,
                onTap: () => push(PathRoutes.of(path.slug)),
              ),
            ],
          ],
        ),
    ];
  }
}

/// The canvas above a block.
const _blockGap = EdgeInsets.only(top: PageBlock.gap);

/// A section of Explore: its title row (and "See all") at the top of a block, then [children].
class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.header, required this.children});

  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => PageBlock(
        margin: _blockGap,
        padding: const EdgeInsets.only(top: ReadInSpace.s1, bottom: ReadInSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // "See all" lines its text up with the gutter.
            Padding(padding: const EdgeInsetsDirectional.only(start: PageBlock.gutter, end: ReadInSpace.s1), child: header),
            ...children,
          ],
        ),
      );
}

/// Every section's shape while Explore loads, in its block.
class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('explore-skeleton'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageBlock(
            margin: _blockGap,
            padding: PageBlock.gutters,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [ExploreSkeletons.title, ExploreSkeletons.fields()],
            ),
          ),
          PageBlock(
            margin: _blockGap,
            padding: PageBlock.gutters,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [ExploreSkeletons.title, ExploreSkeletons.rows()],
            ),
          ),
          PageBlock(
            margin: _blockGap,
            padding: const EdgeInsets.only(bottom: ReadInSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(padding: PageBlock.gutters, child: ExploreSkeletons.title),
                // The writers' rail runs to the screen's edges.
                ExploreSkeletons.writers(padding: PageBlock.gutters),
              ],
            ),
          ),
        ],
      );
}
