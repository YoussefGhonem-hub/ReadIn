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
import '../../../article/presentation/widgets/engagement_seeder.dart';
import '../../../article/presentation/widgets/post_card.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../../mutes/presentation/widgets/mute_gate.dart';
import '../../domain/entities/tag.dart';
import '../cubit/tag_cubits.dart';

/// A tag's page (F32, guests allowed): `#name`, its article count, and every published article with the tag, from all
/// writers, newest first, as post cards (F34) with pull to refresh and infinite scroll. An unknown or hidden tag shows
/// "This tag doesn't exist".
class TagPage extends StatelessWidget {
  const TagPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<TagCubit>()..load(slug)),
          BlocProvider(create: (_) => getIt<TagArticlesCubit>(param1: slug)..load()),
          // The expanded post cards, kept while the reader is open (F34).
          BlocProvider(create: (_) => getIt<PostCardsCubit>()),
        ],
        child: const TagView(),
      );
}

/// The tag page once its [TagCubit], [TagArticlesCubit] and [PostCardsCubit] are provided.
class TagView extends StatelessWidget {
  const TagView({super.key});

  static void _retry(BuildContext context) {
    final header = context.read<TagCubit>();
    unawaited(header.refresh());
    unawaited(context.read<TagArticlesCubit>().load());
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<TagCubit, TagState>(
        builder: (context, header) => Scaffold(
          appBar: AppBar(
            // Opened from a link with no page under it (App Link, Universal Link, a push): back goes Home, like the
            // reader, so the user is never stuck here.
            leading: Navigator.of(context).canPop()
                ? null
                : IconButton(
                    key: const ValueKey('tag-page-home'),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    icon: const BackButtonIcon(),
                    onPressed: () => GoRouter.maybeOf(context)?.go('/home'),
                  ),
          ),
          body: switch (header.status) {
            TagStatus.loading => const _TagSkeleton(),
            TagStatus.failure when header.notFound => const _TagNotFound(),
            TagStatus.failure => ErrorView(failure: header.failure!, onRetry: () => _retry(context)),
            TagStatus.ready => _TagContent(tag: header.tag!),
          },
        ),
      );
}

class _TagNotFound extends StatelessWidget {
  const _TagNotFound();

  @override
  Widget build(BuildContext context) => EmptyView(
        icon: Icons.tag_rounded,
        title: context.l10n.tagNotFoundTitle,
        body: context.l10n.tagNotFoundBody,
      );
}

class _TagContent extends StatelessWidget {
  const _TagContent({required this.tag});

  final ArticleTag tag;

  /// Pull to refresh: the header and the first page again, and the cards collapsed (F34).
  static Future<void> _refresh(BuildContext context) async {
    context.read<PostCardsCubit?>()?.reset();
    await Future.wait([context.read<TagCubit>().refresh(), context.read<TagArticlesCubit>().refresh()]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TagArticlesCubit>();
    return EngagementSeeder<TagArticlesCubit, FeedState>(
      cards: (state) => state.items,
      child: BlocBuilder<TagArticlesCubit, FeedState>(
        builder: (context, feed) {
          // Mutes and "show less" can fold away every card loaded (F28): the next page loads by itself, and once none
          // is left the page says it has no articles.
          final allHidden = mutesHideAll(context, feed.items);
          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) unawaited(cubit.loadMore());
                return false;
              },
              child: CustomScrollView(
                key: PageStorageKey('tag-${tag.slug}'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: TagHeader(tag: tag)),
                  ...switch (feed.status) {
                    FeedStatus.loading => [
                        SliverList.list(children: [
                          for (var i = 0; i < 2; i++) const Padding(padding: EdgeInsets.only(bottom: postCardGap), child: PostCardSkeleton()),
                        ]),
                      ],
                    FeedStatus.failure when isTagNotFound(feed.failure) => [
                        const SliverFillRemaining(hasScrollBody: false, child: _TagNotFound()),
                      ],
                    FeedStatus.failure => [
                        SliverFillRemaining(hasScrollBody: false, child: ErrorView(failure: feed.failure!, onRetry: cubit.load)),
                      ],
                    FeedStatus.ready when feed.items.isEmpty || (allHidden && !feed.hasMore) => [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyView(icon: Icons.article_outlined, title: l10n.tagPageEmptyTitle, body: l10n.tagPageEmptyBody),
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
                                  child: Padding(padding: const EdgeInsets.only(bottom: postCardGap), child: PostCard(article: feed.items[i])),
                                )
                              : LoadMoreWhileHidden(
                                  active: allHidden && !feed.loadingMore && feed.loadMoreFailure == null,
                                  onLoadMore: () => unawaited(cubit.loadMore()),
                                  child: _ListFooter(loadingMore: feed.loadingMore, failure: feed.loadMoreFailure, onRetry: cubit.loadMore),
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
    );
  }
}

/// `#name` (in its own direction, "dir=auto") and the number of articles readers can see.
class TagHeader extends StatelessWidget {
  const TagHeader({super.key, required this.tag});

  final ArticleTag tag;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = '#${tag.name}';
    final nameDir = Bidi.detect(tag.name) ?? Directionality.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, ReadInSpace.s5),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.card)),
            child: ExcludeSemantics(child: Icon(Icons.tag_rounded, size: 28, color: colors.onPrimaryContainer)),
          ),
          const SizedBox(width: ReadInSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      name,
                      key: const ValueKey('tag-page-name'),
                      textDirection: nameDir,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: ReadInSpace.s1),
                Text(
                  context.l10n.tagPageArticleCount(tag.articleCount),
                  style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The load-more spinner, or its error with retry.
class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.loadingMore, required this.failure, required this.onRetry});

  final bool loadingMore;
  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = this.failure;
    final Widget child = loadingMore
        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
        : failure != null
            ? ErrorView(failure: failure, compact: true, onRetry: onRetry)
            : const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s5), child: Center(child: child));
  }
}

/// The header and two post cards while the page loads (static, so "reduce motion" is respected).
class _TagSkeleton extends StatelessWidget {
  const _TagSkeleton();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, ReadInSpace.s5),
              child: Row(
                children: [
                  SkeletonBox(width: 56, height: 56, radius: ReadInRadius.card),
                  SizedBox(width: ReadInSpace.s4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [SkeletonBox(width: 160, height: 24), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 80)],
                  ),
                ],
              ),
            ),
            PostCardSkeleton(),
            SizedBox(height: postCardGap),
            PostCardSkeleton(),
          ],
        ),
      );
}
