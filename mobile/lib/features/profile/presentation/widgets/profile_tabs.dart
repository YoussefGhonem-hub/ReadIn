import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/utils/link_opener.dart';
import '../../../../shared/widgets/field_style.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/presentation/cubit/post_cards_cubit.dart';
import '../../../article/presentation/widgets/engagement_seeder.dart';
import '../../../article/presentation/widgets/post_card.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../../paths/domain/entities/learning_path.dart';
import '../../../paths/presentation/cubit/path_list_cubit.dart';
import '../../../paths/presentation/pages/paths_page.dart';
import '../../../paths/presentation/path_routes.dart';
import '../../../reading/presentation/widgets/reading_heatmap.dart';
import '../../../reading/presentation/widgets/reading_stats_card.dart';
import '../../domain/entities/profile.dart';
import '../cubit/profile_articles_cubit.dart';
import '../cubit/profile_cubit.dart';
import 'profile_header.dart';
import 'public_reading_stats_switch.dart';

/// The first sliver of every tab: room for the pinned tab bar of the profile's [NestedScrollView].
Widget profileTabOverlap(BuildContext context) =>
    SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context));

// ── Articles ────────────────────────────────────────────────────────────────

/// Published articles, newest first, with pull to refresh and infinite scroll. Needs a [ProfileArticlesCubit] above.
class ProfileArticlesTab extends StatefulWidget {
  const ProfileArticlesTab({super.key, required this.profile, this.onWrite});

  final UserProfile profile;

  /// The own profile's empty state offers to write the first article.
  final VoidCallback? onWrite;

  @override
  State<ProfileArticlesTab> createState() => _ProfileArticlesTabState();
}

class _ProfileArticlesTabState extends State<ProfileArticlesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// Pull to refresh: the cards show collapsed again (F34).
  Future<void> _refresh() async {
    final profile = context.read<ProfileCubit?>();
    context.read<PostCardsCubit?>()?.reset();
    await Future.wait([context.read<ProfileArticlesCubit>().refresh(), ?profile?.refresh()]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cubit = context.read<ProfileArticlesCubit>();
    return EngagementSeeder<ProfileArticlesCubit, FeedState>(
      cards: (state) => state.items,
      child: BlocBuilder<ProfileArticlesCubit, FeedState>(
        builder: (context, feed) => RefreshIndicator(
          onRefresh: _refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) unawaited(cubit.loadMore());
              return false;
            },
            child: CustomScrollView(
              key: const PageStorageKey('profile-articles'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                profileTabOverlap(context),
                ...switch (feed.status) {
                  FeedStatus.loading => [
                      SliverList.list(children: [
                        for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: postCardGap), child: PostCardSkeleton()),
                      ]),
                    ],
                  FeedStatus.failure => [
                      SliverFillRemaining(hasScrollBody: false, child: ErrorView(failure: feed.failure!, onRetry: cubit.load)),
                    ],
                  FeedStatus.ready when feed.items.isEmpty => [
                      SliverFillRemaining(hasScrollBody: false, child: _ArticlesEmpty(profile: widget.profile, onWrite: widget.onWrite)),
                    ],
                  // Post cards full width, one after another on the background (F34).
                  FeedStatus.ready => [
                      SliverPadding(
                        padding: const EdgeInsets.only(top: postCardGap),
                        sliver: SliverList.builder(
                          itemCount: feed.items.length + 1,
                          itemBuilder: (context, i) => i < feed.items.length
                              ? Padding(padding: const EdgeInsets.only(bottom: postCardGap), child: PostCard(article: feed.items[i]))
                              : _ListFooter(loadingMore: feed.loadingMore, failure: feed.loadMoreFailure, onRetry: cubit.loadMore),
                        ),
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

class _ArticlesEmpty extends StatelessWidget {
  const _ArticlesEmpty({required this.profile, this.onWrite});

  final UserProfile profile;
  final VoidCallback? onWrite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (profile.isMe) {
      return EmptyView(
        icon: Icons.edit_note_rounded,
        title: l10n.profileArticlesEmptyOwnTitle,
        body: l10n.profileArticlesEmptyOwnBody,
        action: onWrite == null ? null : FilledButton(onPressed: onWrite, child: Text(l10n.profileWriteFirst)),
      );
    }
    return EmptyView(icon: Icons.article_outlined, title: l10n.profileArticlesEmptyTitle, body: l10n.profileArticlesEmptyBody);
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

/// Card placeholders while a list loads.
class ArticleListSkeleton extends StatelessWidget {
  const ArticleListSkeleton({super.key});

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
                      children: [SkeletonBox(width: 70), SizedBox(height: ReadInSpace.s2), SkeletonBox(), SizedBox(height: ReadInSpace.s2), SkeletonBox(width: 140)],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}

// ── Paths ───────────────────────────────────────────────────────────────────

/// The learning paths [profile] joined (F09): `GET /users/{username}/paths`, in progress first, with progress and
/// completion badges. Shown when their reading stats are visible (always on the own profile); otherwise the private
/// state, without a request.
class ProfilePathsTab extends StatelessWidget {
  const ProfilePathsTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!profile.readingStatsVisible) {
      return CustomScrollView(
        key: const PageStorageKey('profile-paths'),
        slivers: [
          profileTabOverlap(context),
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.lock_outline_rounded,
              title: l10n.profilePathsPrivateTitle,
              body: l10n.profilePathsPrivateBody,
            ),
          ),
        ],
      );
    }
    final isMe = profile.isMe;
    return BlocProvider(
      create: (_) => getIt<UserPathsCubit>(param1: profile.username)..load(),
      child: Builder(
        builder: (context) => PathList<UserPathsCubit>(
          storageKey: 'profile-paths',
          leading: profileTabOverlap,
          onOpen: (path) => _openPath(context, path),
          // The own profile is one tap from every path.
          footer: isMe
              ? Center(child: TextButton(onPressed: () => context.push(PathRoutes.list), child: Text(l10n.pathsBrowse)))
              : null,
          empty: EmptyView(
            icon: Icons.route_outlined,
            title: l10n.profilePathsEmptyTitle,
            body: isMe ? l10n.profilePathsEmptyOwnBody : l10n.profilePathsEmptyBody,
            action: isMe ? FilledButton(onPressed: () => context.push(PathRoutes.list), child: Text(l10n.pathsBrowse)) : null,
          ),
        ),
      ),
    );
  }

  /// Back from the path page, the list refreshes (enrolling, leaving and reading change it).
  static Future<void> _openPath(BuildContext context, LearningPath path) async {
    final cubit = context.read<UserPathsCubit>();
    await context.push<void>(PathRoutes.of(path.slug));
    if (!cubit.isClosed) unawaited(cubit.refresh());
  }
}

// ── About ───────────────────────────────────────────────────────────────────

/// Bio, links, fields of expertise, joined date and, when visible, the reading stats card and heatmap (F08). The own
/// profile also has the "show on my public profile" switch, which needs a [PrivacyCubit] above.
class ProfileAboutTab extends StatelessWidget {
  const ProfileAboutTab({super.key, required this.profile, this.onEdit});

  final UserProfile profile;

  /// The own profile's "add details" action.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final bio = profile.bio;
    final links = ProfileLinksRow.entries(context, profile.links);
    final hasDetails = bio != null || links.isNotEmpty || profile.expertise.isNotEmpty;
    // The own stats come from /me/stats (the streak badge follows them); someone else's from their public endpoint.
    final statsOf = profile.isMe ? null : profile.username;

    return CustomScrollView(
      key: const PageStorageKey('profile-about'),
      slivers: [
        profileTabOverlap(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s6),
          sliver: SliverList.list(
            children: [
              if (bio != null) _Section(title: l10n.profileAboutBio, child: ProfileBioText(bio, style: context.textTheme.bodyLarge?.copyWith(height: 1.6))),
              if (links.isNotEmpty)
                _Section(
                  title: l10n.profileLinks,
                  child: Column(
                    children: [
                      for (final (icon, label, url) in links)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          minTileHeight: 56,
                          leading: Icon(icon, color: context.colors.primary),
                          title: Text(label),
                          subtitle: Text(
                            Bidi.ltrIsolate(_display(url)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall,
                          ),
                          trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                          onTap: () => openExternalLink(url),
                        ),
                    ],
                  ),
                ),
              if (profile.expertise.isNotEmpty)
                _Section(
                  title: l10n.profileExpertise,
                  child: Wrap(
                    spacing: ReadInSpace.s2,
                    runSpacing: ReadInSpace.s2,
                    children: [for (final field in profile.expertise) ExpertiseChip(field: field)],
                  ),
                ),
              if (!hasDetails)
                Padding(
                  padding: const EdgeInsets.only(bottom: ReadInSpace.s5),
                  child: profile.isMe
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.profileAboutEmptyOwn, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                            if (onEdit != null) ...[
                              const SizedBox(height: ReadInSpace.s3),
                              OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: Text(l10n.editProfile)),
                            ],
                          ],
                        )
                      : Text(l10n.profileAboutEmpty, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                ),
              if (profile.joinedAt case final joined?)
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 18, color: context.colors.textSecondary),
                    const SizedBox(width: ReadInSpace.s2),
                    Expanded(child: Text(l10n.profileJoined(formatMonthYear(joined, lang)), style: context.textTheme.bodyMedium)),
                  ],
                ),
              if (profile.readingStatsVisible) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: ReadInSpace.s5), child: Divider()),
                Semantics(header: true, child: Text(l10n.readingStatsTitle, style: context.textTheme.titleMedium)),
                if (profile.isMe) const PublicReadingStatsSwitch(),
                const SizedBox(height: ReadInSpace.s3),
                ReadingStatsCard(username: statsOf),
                const SizedBox(height: ReadInSpace.s4),
                ReadingHeatmap(username: statsOf),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// `https://github.com/mona/` → `github.com/mona`.
  static String _display(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final path = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
    return '${uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host}$path';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: ReadInSpace.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: context.textTheme.labelLarge?.copyWith(color: context.colors.textSecondary)),
            ),
            const SizedBox(height: ReadInSpace.s2),
            child,
          ],
        ),
      );
}

/// A field of expertise: its icon and name on a soft tint of its color token.
class ExpertiseChip extends StatelessWidget {
  const ExpertiseChip({super.key, required this.field});

  final ExpertiseField field;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = FieldStyle.color(colors, field.color);
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.12), colors.surface),
        borderRadius: BorderRadius.circular(ReadInRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(FieldStyle.icon(field.icon), size: 16, color: color)),
          const SizedBox(width: 6),
          Text(
            Bidi.isolateOppositeRuns(field.name, Directionality.of(context)),
            style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
