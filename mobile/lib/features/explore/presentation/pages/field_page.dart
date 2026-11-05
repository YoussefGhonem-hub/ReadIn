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
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/presentation/cubit/post_cards_cubit.dart';
import '../../../article/presentation/widgets/engagement_seeder.dart';
import '../../../article/presentation/widgets/post_card.dart';
import '../../../article/presentation/widgets/reader_widgets.dart' show HealthDisclaimer;
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../../follow/presentation/widgets/follow_button.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../domain/entities/explore.dart';
import '../cubit/field_cubits.dart';
import '../widgets/explore_widgets.dart';

/// A field's page (F15, guests allowed; `/f/{slug}`, `?topic=` selects a chip): the field's icon, name, article and
/// follower counts with Follow, the health note on sensitive fields, the topic chips (each filters the articles and can
/// be followed), "Top writers in this field", then the articles as post cards (F34), newest first, with pull to refresh
/// and infinite scroll. An unknown or disabled field shows "This field doesn't exist".
class FieldPage extends StatelessWidget {
  const FieldPage({super.key, required this.slug, this.topic});

  final String slug;

  /// The topic chip to start on (`?topic=`), or null for the whole field.
  final String? topic;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<FieldCubit>()..load(slug)),
          BlocProvider(create: (_) => getIt<FieldArticlesCubit>(param1: slug)..load(fieldSlug: topic)),
          BlocProvider(create: (_) => getIt<FieldWritersCubit>(param1: slug)..load()),
          // The expanded post cards, kept while the reader is open (F34).
          BlocProvider(create: (_) => getIt<PostCardsCubit>()),
        ],
        child: const FieldView(),
      );
}

/// The field page once its [FieldCubit], [FieldArticlesCubit], [FieldWritersCubit] and [PostCardsCubit] are provided.
class FieldView extends StatelessWidget {
  const FieldView({super.key});

  static void _reload(BuildContext context) {
    final articles = context.read<FieldArticlesCubit>();
    unawaited(context.read<FieldCubit>().refresh());
    unawaited(articles.load(fieldSlug: articles.topic));
    unawaited(context.read<FieldWritersCubit>().load());
  }

  @override
  Widget build(BuildContext context) => BlocListener<SessionCubit, SessionState>(
        // Signing in (from the sign-in prompt) or out changes the follows and the viewer's state on the cards.
        listenWhen: (a, b) =>
            a.status != SessionStatus.unknown && (a.isAuthenticated, a.me?.id) != (b.isAuthenticated, b.me?.id),
        listener: (context, _) => _reload(context),
        child: BlocBuilder<FieldCubit, FieldState>(
          buildWhen: (a, b) => a.status != b.status || (a.field == null) != (b.field == null),
          builder: (context, header) => Scaffold(
            appBar: AppBar(
              // Opened from a link with no page under it (App Link, a push): back goes Home, like the tag page.
              leading: Navigator.of(context).canPop()
                  ? null
                  : IconButton(
                      key: const ValueKey('field-page-home'),
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      icon: const BackButtonIcon(),
                      onPressed: () => GoRouter.maybeOf(context)?.go('/home'),
                    ),
            ),
            body: switch (header.status) {
              FieldStatus.loading => const _FieldSkeleton(),
              FieldStatus.failure when header.notFound => const _FieldNotFound(),
              FieldStatus.failure => ErrorView(failure: header.failure!, onRetry: () => _reload(context)),
              FieldStatus.ready => const _FieldContent(),
            },
          ),
        ),
      );
}

class _FieldNotFound extends StatelessWidget {
  const _FieldNotFound();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyView(
      icon: Icons.explore_off_outlined,
      title: l10n.fieldNotFoundTitle,
      body: l10n.fieldNotFoundBody,
      action: FilledButton(
        key: const ValueKey('field-go-explore'),
        onPressed: () => GoRouter.maybeOf(context)?.go('/explore'),
        child: Text(l10n.fieldGoToExplore),
      ),
    );
  }
}

/// Follows or unfollows through [change] (guests get the sign-in prompt), and says why it went back: "Keep at least 3
/// interests. Follow another field or topic first." when it was one of the last ones.
Future<void> _follow(BuildContext context, Future<Failure?> Function() change) async {
  if (!requireAccount(context)) return;
  final failure = await change();
  if (failure == null || !context.mounted) return;
  if (failure.code == FailureCodes.interestsMinThree) return showActionMessage(context, context.l10n.fieldKeepThree);
  showActionFailure(context, failure);
}

class _FieldContent extends StatelessWidget {
  const _FieldContent();

  /// Pull to refresh: the header, the writers and the first page again, and the cards collapsed (F34).
  static Future<void> _refresh(BuildContext context) async {
    context.read<PostCardsCubit?>()?.reset();
    await Future.wait([
      context.read<FieldCubit>().refresh(),
      context.read<FieldWritersCubit>().refresh(),
      context.read<FieldArticlesCubit>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FieldArticlesCubit>();
    final field = context.select((FieldCubit c) => c.state.field!);
    return EngagementSeeder<FieldArticlesCubit, FeedState>(
      cards: (state) => state.items,
      child: BlocBuilder<FieldArticlesCubit, FeedState>(
        builder: (context, feed) => RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) unawaited(cubit.loadMore());
              return false;
            },
            child: CustomScrollView(
              key: PageStorageKey('field-${field.slug}'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: FieldHeader(field: field)),
                if (field.topics.isNotEmpty)
                  SliverToBoxAdapter(
                    child: TopicChips(
                      topics: field.topics,
                      selected: feed.fieldSlug,
                      onSelected: (slug) => unawaited(cubit.selectTopic(slug)),
                    ),
                  ),
                if (field.topicOf(feed.fieldSlug) case final topic?) SliverToBoxAdapter(child: TopicFollowRow(topic: topic)),
                const SliverToBoxAdapter(child: _TopWriters()),
                ..._articles(context, feed, field),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static List<Widget> _articles(BuildContext context, FeedState feed, FieldDetails field) {
    final l10n = context.l10n;
    final cubit = context.read<FieldArticlesCubit>();
    final title = SliverPadding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s3, ReadInSpace.s5, ReadInSpace.s2),
      sliver: SliverToBoxAdapter(child: ExploreSectionHeader(title: l10n.fieldArticles)),
    );
    return switch (feed.status) {
      FeedStatus.loading => [
          title,
          SliverList.list(children: [
            for (var i = 0; i < 2; i++) const Padding(padding: EdgeInsets.only(bottom: postCardGap), child: PostCardSkeleton()),
          ]),
        ],
      // A `?topic=` that isn't one of the field's: say so, and offer the whole field.
      FeedStatus.failure when isTopicNotFound(feed.failure) => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.label_off_outlined,
              title: l10n.fieldTopicNotFoundTitle,
              body: l10n.fieldTopicNotFoundBody('${Bidi.fsi}${field.nameFor(Localizations.localeOf(context).languageCode)}${Bidi.pdi}'),
              action: OutlinedButton(
                key: const ValueKey('field-show-all'),
                onPressed: () => unawaited(cubit.selectTopic(null)),
                child: Text(l10n.fieldShowAllArticles),
              ),
            ),
          ),
        ],
      FeedStatus.failure => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorView(failure: feed.failure!, compact: true, onRetry: () => unawaited(cubit.load(fieldSlug: cubit.topic))),
          ),
        ],
      FeedStatus.ready when feed.items.isEmpty => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              key: const ValueKey('field-empty'),
              icon: Icons.article_outlined,
              title: feed.fieldSlug == null ? l10n.fieldEmptyTitle : l10n.fieldTopicEmptyTitle,
              body: l10n.fieldEmptyBody,
            ),
          ),
        ],
      // Post cards full width, one after another on the background (F34).
      FeedStatus.ready => [
          title,
          SliverList.builder(
            itemCount: feed.items.length + 1,
            itemBuilder: (context, i) => i < feed.items.length
                ? Padding(
                    padding: const EdgeInsets.only(bottom: postCardGap),
                    child: PostCard(key: ValueKey('field-card-${feed.items[i].id}'), article: feed.items[i]),
                  )
                : ExploreListFooter(
                    loadingMore: feed.loadingMore,
                    failure: feed.loadMoreFailure,
                    onRetry: () => unawaited(cubit.loadMore()),
                  ),
          ),
        ],
    };
  }
}

/// The field's icon in its color, its name (in its own direction), "N articles · M followers" and Follow, then the
/// health note on a sensitive field (medicine, public health).
class FieldHeader extends StatelessWidget {
  const FieldHeader({super.key, required this.field});

  final FieldDetails field;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final name = field.nameFor(Localizations.localeOf(context).languageCode);
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    final pending = context.select((FieldCubit c) => c.state.pending.contains(field.id));
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, ReadInSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldIconBox(icon: field.icon, color: field.color, size: 56),
              const SizedBox(width: ReadInSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: BidiText(
                        name,
                        key: const ValueKey('field-page-name'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: ReadInSpace.s1),
                    Text(
                      '${l10n.fieldArticleCount(field.articleCount)} · ${l10n.fieldFollowerCount(field.followerCount)}',
                      key: const ValueKey('field-page-counts'),
                      style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: ReadInSpace.s3),
                    FollowButtonView(
                      key: const ValueKey('field-follow'),
                      following: signedIn && field.isFollowing,
                      pending: pending,
                      name: name,
                      followLabel: l10n.fieldFollow,
                      onPressed: () => unawaited(_follow(context, context.read<FieldCubit>().toggleField)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (field.isSensitive) ...[const SizedBox(height: ReadInSpace.s4), const HealthDisclaimer()],
        ],
      ),
    );
  }
}

/// "All" and the field's topics; the selected one filters the articles, and a followed one has a ✓ after its name (as on
/// the web). A topic opened from a link (`?topic=`) is scrolled into view.
class TopicChips extends StatefulWidget {
  const TopicChips({super.key, required this.topics, required this.selected, required this.onSelected});

  final List<FieldTopic> topics;

  /// The selected topic's slug; null is "All".
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  State<TopicChips> createState() => _TopicChipsState();
}

class _TopicChipsState extends State<TopicChips> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _selectedKey.currentContext;
      final box = chip?.findRenderObject();
      if (!mounted || chip == null || box == null || widget.selected == null) return;
      // Only the chips' own row scrolls; the page stays at its top.
      unawaited(Scrollable.of(chip, axis: Axis.horizontal).position.ensureVisible(box, alignment: 0.5));
    });
  }

  bool _isSelected(String? slug) => slug?.toLowerCase() == widget.selected?.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    Widget chip(String label, String? slug, {Key? key, bool following = false}) {
      final isSelected = _isSelected(slug);
      final color = isSelected ? colors.onPrimary : colors.textSecondary;
      return Padding(
        key: isSelected ? _selectedKey : null,
        padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s2),
        child: ChoiceChip(
          key: key,
          label: following
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BidiText(label),
                    const SizedBox(width: 4),
                    // Read out after the name: "ASP.NET Core, Following".
                    Icon(Icons.check_rounded, key: const ValueKey('field-topic-following'), size: 16, color: color, semanticLabel: l10n.followingState),
                  ],
                )
              : BidiText(label),
          selected: isSelected,
          onSelected: (_) => widget.onSelected(slug),
          selectedColor: colors.primary,
          labelStyle: context.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(color: isSelected ? colors.primary : colors.border),
        ),
      );
    }

    return Semantics(
      label: l10n.fieldTopics,
      container: true,
      // Every chip is built (a field has a handful of topics), so the one a link selects can be scrolled to.
      child: SingleChildScrollView(
        key: const ValueKey('field-topics'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s1),
        child: Row(
          children: [
            chip(l10n.filterAll, null, key: const ValueKey('field-topic-all')),
            for (final t in widget.topics)
              chip(t.nameFor(lang), t.slug, key: ValueKey('field-topic-${t.slug}'), following: signedIn && t.isFollowing),
          ],
        ),
      ),
    );
  }
}

/// The selected topic: its name and article count, and Follow for the topic itself.
class TopicFollowRow extends StatelessWidget {
  const TopicFollowRow({super.key, required this.topic});

  final FieldTopic topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = topic.nameFor(Localizations.localeOf(context).languageCode);
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    final pending = context.select((FieldCubit c) => c.state.pending.contains(topic.id));
    return Padding(
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BidiText(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall),
                Text(
                  context.l10n.fieldArticleCount(topic.articleCount),
                  style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: ReadInSpace.s2),
          FollowButtonView(
            key: ValueKey('field-topic-follow-${topic.slug}'),
            following: signedIn && topic.isFollowing,
            pending: pending,
            name: name,
            followLabel: context.l10n.fieldFollowTopic,
            dense: true,
            onPressed: () => unawaited(_follow(context, () => context.read<FieldCubit>().toggleTopic(topic))),
          ),
        ],
      ),
    );
  }
}

/// "Top writers in this field" with Follow, in a rail that runs to the screen's edges (all of them, ≤ 10, as on the web
/// and Explore); nothing when the field has none.
class _TopWriters extends StatelessWidget {
  const _TopWriters();

  static const _gutter = EdgeInsets.symmetric(horizontal: ReadInSpace.s5);

  @override
  Widget build(BuildContext context) => BlocBuilder<FieldWritersCubit, FieldWritersState>(
        builder: (context, state) {
          final l10n = context.l10n;
          final Widget? body = switch (state.status) {
            FieldWritersStatus.loading => ExploreSkeletons.writers(padding: _gutter),
            FieldWritersStatus.failure => Padding(
                padding: _gutter,
                child: ErrorView(
                  failure: state.failure!,
                  compact: true,
                  onRetry: () => unawaited(context.read<FieldWritersCubit>().load()),
                ),
              ),
            FieldWritersStatus.ready when state.users.isEmpty => null,
            FieldWritersStatus.ready => WriterRail(
                key: const ValueKey('field-writers'),
                users: state.users,
                label: l10n.fieldTopWriters,
                keyPrefix: 'field-writer',
                padding: _gutter,
              ),
          };
          if (body == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: ReadInSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Padding(padding: _gutter, child: ExploreSectionHeader(title: l10n.fieldTopWriters)), body],
            ),
          );
        },
      );
}

/// The header, the chips and two post cards while the page loads (static, so "reduce motion" is respected).
class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton();

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        key: ValueKey('field-skeleton'),
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s2, ReadInSpace.s5, ReadInSpace.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 56, height: 56, radius: ReadInRadius.card),
                  SizedBox(width: ReadInSpace.s4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 170, height: 24),
                      SizedBox(height: ReadInSpace.s2),
                      SkeletonBox(width: 130),
                      SizedBox(height: ReadInSpace.s3),
                      SkeletonBox(width: 96, height: 44, radius: ReadInRadius.chip),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s2),
              child: Row(
                children: [
                  SkeletonBox(width: 56, height: 32, radius: ReadInRadius.chip),
                  SizedBox(width: ReadInSpace.s2),
                  SkeletonBox(width: 96, height: 32, radius: ReadInRadius.chip),
                  SizedBox(width: ReadInSpace.s2),
                  SkeletonBox(width: 80, height: 32, radius: ReadInRadius.chip),
                ],
              ),
            ),
            SizedBox(height: ReadInSpace.s3),
            PostCardSkeleton(),
            SizedBox(height: postCardGap),
            PostCardSkeleton(),
          ],
        ),
      );
}
