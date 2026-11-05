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
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/presentation/cubit/post_cards_cubit.dart';
import '../../../article/presentation/widgets/engagement_seeder.dart';
import '../../../article/presentation/widgets/post_card.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../../profile/presentation/profile_routes.dart';
import '../../../profile/presentation/widgets/profile_link.dart';
import '../../domain/entities/writer_category.dart';
import '../cubit/category_cubits.dart';

/// A writer's category page (F31, guests allowed): `/u/{username}/c/{slug}`, the category's name, its article count and
/// its writer, then its articles readers can see, newest first, as post cards (F34) with pull to refresh and infinite
/// scroll. `_other` is "مقالات تانية", the writer's articles without a category. An unknown slug (a moderator's clear
/// changes it) shows "This category doesn't exist" with a way to the writer's profile. The header is a block on the
/// canvas, a gap above the post cards.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.username, required this.slug});

  final String username;
  final String slug;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<CategoryPageCubit>()..load(username, slug)),
          BlocProvider(create: (_) => getIt<CategoryArticlesCubit>(param1: username, param2: slug)..load()),
          // The expanded post cards, kept while the reader is open (F34).
          BlocProvider(create: (_) => getIt<PostCardsCubit>()),
        ],
        child: CategoryView(username: username),
      );
}

/// The category page once its [CategoryPageCubit], [CategoryArticlesCubit] and [PostCardsCubit] are provided.
class CategoryView extends StatelessWidget {
  const CategoryView({super.key, required this.username});

  /// The writer, for the way back to their profile when the category doesn't exist.
  final String username;

  static void _retry(BuildContext context) {
    unawaited(context.read<CategoryPageCubit>().refresh());
    unawaited(context.read<CategoryArticlesCubit>().load());
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CategoryPageCubit, CategoryPageState>(
        builder: (context, header) => Scaffold(
          appBar: AppBar(
            // Opened from a link with no page under it (App Link, Universal Link, a push): back goes Home, like the
            // reader, so the user is never stuck here.
            leading: Navigator.of(context).canPop()
                ? null
                : IconButton(
                    key: const ValueKey('category-page-home'),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    icon: const BackButtonIcon(),
                    onPressed: () => GoRouter.maybeOf(context)?.go('/home'),
                  ),
          ),
          body: switch (header.status) {
            CategoryLoadStatus.loading => const _CategorySkeleton(),
            CategoryLoadStatus.failure when header.writerNotFound => const PageBlock(margin: _blockGap, child: _WriterNotFound()),
            CategoryLoadStatus.failure when header.notFound =>
              PageBlock(margin: _blockGap, child: _CategoryNotFound(username: username)),
            CategoryLoadStatus.failure => PageBlock(
                margin: _blockGap,
                child: ErrorView(failure: header.failure!, onRetry: () => _retry(context)),
              ),
            CategoryLoadStatus.ready => _CategoryContent(page: header.page!),
          },
        ),
      );
}

class _CategoryNotFound extends StatelessWidget {
  const _CategoryNotFound({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) => EmptyView(
        icon: Icons.folder_off_outlined,
        title: context.l10n.categoryNotFoundTitle,
        body: context.l10n.categoryNotFoundBody,
        action: OutlinedButton.icon(
          key: const ValueKey('category-writer-profile'),
          onPressed: () => unawaited(context.push<void>(ProfileRoutes.of(username))),
          icon: const Icon(Icons.person_outline_rounded, size: 18),
          label: Text(context.l10n.categoryWriterProfile),
        ),
      );
}

class _WriterNotFound extends StatelessWidget {
  const _WriterNotFound();

  @override
  Widget build(BuildContext context) => EmptyView(
        icon: Icons.person_off_outlined,
        title: context.l10n.profileNotFoundTitle,
        body: context.l10n.profileNotFoundBody,
      );
}

class _CategoryContent extends StatelessWidget {
  const _CategoryContent({required this.page});

  final WriterCategoryPage page;

  /// Pull to refresh: the header and the first page again, and the cards collapsed (F34).
  static Future<void> _refresh(BuildContext context) async {
    context.read<PostCardsCubit?>()?.reset();
    await Future.wait([context.read<CategoryPageCubit>().refresh(), context.read<CategoryArticlesCubit>().refresh()]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CategoryArticlesCubit>();
    return EngagementSeeder<CategoryArticlesCubit, FeedState>(
      cards: (state) => state.items,
      child: BlocBuilder<CategoryArticlesCubit, FeedState>(
        builder: (context, feed) => RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) unawaited(cubit.loadMore());
              return false;
            },
            child: CustomScrollView(
              key: PageStorageKey('category-${page.author.username}-${page.slug}'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: PageBlock(margin: _blockGap, child: CategoryHeader(page: page))),
                // A gap under the header; the cards, or the states in a block.
                const SliverToBoxAdapter(child: SizedBox(height: PageBlock.gap)),
                ...switch (feed.status) {
                  FeedStatus.loading => [
                      SliverList.list(children: [
                        for (var i = 0; i < 2; i++) const Padding(padding: EdgeInsets.only(bottom: postCardGap), child: PostCardSkeleton()),
                      ]),
                    ],
                  FeedStatus.failure when isCategoryNotFound(feed.failure) => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: PageBlock(child: _CategoryNotFound(username: page.author.username)),
                      ),
                    ],
                  FeedStatus.failure => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: PageBlock(child: ErrorView(failure: feed.failure!, onRetry: cubit.load)),
                      ),
                    ],
                  FeedStatus.ready when feed.items.isEmpty => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: PageBlock(
                          child: EmptyView(
                            icon: Icons.folder_open_outlined,
                            title: page.isOther ? l10n.categoryOtherEmptyTitle : l10n.categoryPageEmptyTitle,
                            body: page.isOther ? l10n.categoryOtherEmptyBody : l10n.categoryPageEmptyBody,
                          ),
                        ),
                      ),
                    ],
                  // Post cards full width, one after another on the background (F34).
                  FeedStatus.ready => [
                      SliverList.builder(
                        itemCount: feed.items.length + 1,
                        itemBuilder: (context, i) => i < feed.items.length
                            ? Padding(padding: const EdgeInsets.only(bottom: postCardGap), child: PostCard(article: feed.items[i]))
                            : _ListFooter(loadingMore: feed.loadingMore, failure: feed.loadMoreFailure, onRetry: cubit.loadMore),
                      ),
                    ],
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The category's name (in its own direction, "dir=auto"; "مقالات تانية" for `_other`), the number of articles
/// readers can see, and its writer, who opens their profile.
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key, required this.page});

  final WriterCategoryPage page;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final name = page.isOther ? l10n.categoriesOther : page.name!;
    final nameDir = Bidi.detect(name) ?? Directionality.of(context);
    final author = page.author;
    return Padding(
      padding: const EdgeInsets.fromLTRB(PageBlock.gutter, PageBlock.gutter, PageBlock.gutter, ReadInSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.card)),
                child: ExcludeSemantics(
                  child: Icon(page.isOther ? Icons.layers_outlined : Icons.folder_outlined, size: 28, color: colors.onPrimaryContainer),
                ),
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
                          Bidi.isolateOppositeRuns(name, nameDir),
                          key: const ValueKey('category-page-name'),
                          textDirection: nameDir,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: ReadInSpace.s1),
                    Text(
                      l10n.categoryArticleCount(page.articleCount),
                      style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ReadInSpace.s3),
          // The writer: the way back to their profile.
          ProfileLink(
            username: author.username,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(name: author.displayName, url: author.avatarUrl, size: 28),
                  const SizedBox(width: ReadInSpace.s2),
                  Flexible(child: BidiText(author.displayName, style: context.textTheme.labelLarge, overflow: TextOverflow.ellipsis)),
                  if (author.isVerified) ...[const SizedBox(width: 4), const VerifiedMark()],
                  const SizedBox(width: ReadInSpace.s2),
                  Text(
                    Bidi.ltrIsolate('@${author.username}'),
                    style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
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

/// The canvas above a block.
const _blockGap = EdgeInsets.only(top: PageBlock.gap);

/// The header's block and two post cards while the page loads (static, so "reduce motion" is respected).
class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageBlock(
              margin: EdgeInsets.symmetric(vertical: PageBlock.gap),
              padding: EdgeInsets.all(PageBlock.gutter),
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
