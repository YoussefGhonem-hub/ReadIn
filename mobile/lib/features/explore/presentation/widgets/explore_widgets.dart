import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/field_style.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../article/presentation/widgets/article_card_tile.dart';
import '../../../follow/domain/entities/follow.dart';
import '../../../follow/presentation/widgets/follow_button.dart';
import '../../../mutes/presentation/widgets/mute_gate.dart';
import '../../../profile/presentation/widgets/profile_link.dart';
import '../../domain/entities/explore.dart';
import '../explore_routes.dart';

/// A section's title, and "عرض الكل" / "See all" on the other side when the section has a full list.
class ExploreSectionHeader extends StatelessWidget {
  const ExploreSectionHeader({super.key, required this.title, this.onSeeAll, this.seeAllKey});

  final String title;
  final VoidCallback? onSeeAll;
  final Key? seeAllKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onSeeAll = this.onSeeAll;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(child: Semantics(header: true, child: Text(title, style: context.textTheme.titleMedium))),
          if (onSeeAll != null)
            TextButton(
              key: seeAllKey,
              onPressed: onSeeAll,
              style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
              // The screen reader says which section: "See all: Trending this week".
              child: Text(l10n.exploreSeeAll, semanticsLabel: l10n.exploreSeeAllSection(title)),
            ),
        ],
      ),
    );
  }
}

/// A field's icon on a tint of its color (readable in light and dark: both come from the theme's tokens).
class FieldIconBox extends StatelessWidget {
  const FieldIconBox({super.key, required this.icon, required this.color, this.size = 44});

  final String icon;
  final String color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = FieldStyle.color(colors, color);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Color.alphaBlend(tone.withValues(alpha: 0.14), colors.surface),
          borderRadius: BorderRadius.circular(size >= 56 ? ReadInRadius.card : ReadInRadius.md),
        ),
        child: Icon(FieldStyle.icon(icon), color: tone, size: size * 0.5),
      ),
    );
  }
}

/// A field tile: its icon and color, its name and article count. It opens the field page (`/f/{slug}`).
class FieldTile extends StatelessWidget {
  const FieldTile({super.key, required this.field});

  final FieldSummary field;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final radius = BorderRadius.circular(ReadInRadius.md);
    return MergeSemantics(
      child: Semantics(
        link: true,
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: colors.border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('explore-field-${field.slug}'),
            onTap: () => unawaited(GoRouter.maybeOf(context)?.push<void>(ExploreRoutes.field(field.slug))),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.all(ReadInSpace.s3),
                child: Row(
                  children: [
                    FieldIconBox(icon: field.icon, color: field.color, size: 36),
                    const SizedBox(width: ReadInSpace.s2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BidiText(
                            field.nameFor(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.fieldArticleCount(field.articleCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
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

/// Every enabled field, two to a row (each row as tall as its taller tile, so long names and large text fit), as the
/// web shows them.
class FieldsGrid extends StatelessWidget {
  const FieldsGrid({super.key, required this.fields});

  final List<FieldSummary> fields;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < fields.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: FieldTile(field: fields[i])),
                    const SizedBox(width: ReadInSpace.s2),
                    Expanded(child: i + 1 < fields.length ? FieldTile(field: fields[i + 1]) : const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
        ],
      );
}

/// An article in an Explore section as the compact row (the full list, "See all", shows post cards), with the viewer's
/// latest counters. It opens the reader.
class ExploreArticleRow extends StatelessWidget {
  const ExploreArticleRow({super.key, required this.article});

  final ArticleCard article;

  @override
  Widget build(BuildContext context) {
    final engagement = context.select((EngagementCubit c) => c.state.of(article));
    // A writer, field or topic muted elsewhere (the reader) folds the row away too (F28).
    return MuteGate(
      article: article,
      child: ArticleCardTile(
        key: ValueKey('explore-article-${article.id}'),
        article: engagement.applyTo(article),
        onTap: () => unawaited(GoRouter.maybeOf(context)?.push<void>('/a/${article.slug}')),
        showAttachments: false,
      ),
    );
  }
}

/// Writers in a row that scrolls sideways (Explore's new writers, a field's top writers), every one the API sends
/// (≤ 10), as on the web: photo, name, @handle and Follow. The row runs to the screen's edges; [padding] lines the first
/// card up with the page.
class WriterRail extends StatelessWidget {
  const WriterRail({
    super.key,
    required this.users,
    required this.label,
    this.keyPrefix = 'writer',
    this.padding = const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
  });

  final List<UserSummary> users;

  /// What the list is, for screen readers (the section's title).
  final String label;

  /// Each card's key is `{keyPrefix}-{userId}`.
  final String keyPrefix;
  final EdgeInsets padding;

  static const cardWidth = 160.0;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        container: true,
        explicitChildNodes: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: padding.add(const EdgeInsets.symmetric(vertical: ReadInSpace.s1)),
          // Every card as tall as the tallest (your own has no Follow; large text grows them all).
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, user) in users.indexed) ...[
                  if (i > 0) const SizedBox(width: ReadInSpace.s3),
                  WriterCard(key: ValueKey('$keyPrefix-${user.id}'), user: user),
                ],
              ],
            ),
          ),
        ),
      );
}

/// A writer on a [WriterRail]: the photo, name and @handle open the profile (F14); Follow below (F12: none on your own
/// card, guests get the sign-in prompt).
class WriterCard extends StatelessWidget {
  const WriterCard({super.key, required this.user});

  final UserSummary user;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: WriterRail.cardWidth,
      padding: const EdgeInsets.all(ReadInSpace.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ReadInRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileLink(
            username: user.username,
            child: Column(
              children: [
                UserAvatar(name: user.displayName, url: user.avatarUrl, size: 56),
                const SizedBox(height: ReadInSpace.s2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: BidiText(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (user.isVerified) ...[const SizedBox(width: 4), const VerifiedMark()],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  Bidi.ltrIsolate('@${user.username}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: ReadInSpace.s3),
          const Spacer(),
          Center(child: FollowButton(userId: user.id, name: user.displayName, initiallyFollowing: user.isFollowing, dense: true)),
        ],
      ),
    );
  }
}

/// Static placeholders (no shimmer, so "reduce motion" is respected).
class ExploreSkeletons {
  const ExploreSkeletons._();

  /// A section title.
  static const title = Padding(
    padding: EdgeInsets.symmetric(vertical: ReadInSpace.s3),
    child: Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBox(width: 140, height: 18)),
  );

  /// Field tiles, two to a row.
  static Widget fields({int rows = 3}) => Column(
        children: [
          for (var i = 0; i < rows; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: ReadInSpace.s2),
              child: Row(
                children: [
                  Expanded(child: SkeletonBox(height: 64, radius: ReadInRadius.md)),
                  SizedBox(width: ReadInSpace.s2),
                  Expanded(child: SkeletonBox(height: 64, radius: ReadInRadius.md)),
                ],
              ),
            ),
        ],
      );

  /// Compact article rows.
  static Widget rows({int count = 3}) => Column(
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: ReadInSpace.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 72, height: 72, radius: ReadInRadius.md),
                  SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 200),
                        SizedBox(height: ReadInSpace.s2),
                        SkeletonBox(width: 150),
                        SizedBox(height: ReadInSpace.s2),
                        SkeletonBox(width: 90, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );

  /// A [WriterRail]'s cards, cut at the screen's edge like the rail.
  static Widget writers({int count = 3, EdgeInsets padding = const EdgeInsets.symmetric(horizontal: ReadInSpace.s5)}) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding.add(const EdgeInsets.symmetric(vertical: ReadInSpace.s1)),
        child: Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: ReadInSpace.s3),
              const _WriterCardSkeleton(),
            ],
          ],
        ),
      );
}

class _WriterCardSkeleton extends StatelessWidget {
  const _WriterCardSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        width: WriterRail.cardWidth,
        padding: const EdgeInsets.all(ReadInSpace.s3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ReadInRadius.card),
          border: Border.all(color: context.colors.border),
        ),
        child: const Column(
          children: [
            SkeletonBox(width: 56, height: 56, radius: 28),
            SizedBox(height: ReadInSpace.s2),
            SkeletonBox(width: 96, height: 12),
            SizedBox(height: ReadInSpace.s2),
            SkeletonBox(width: 64, height: 10),
            SizedBox(height: ReadInSpace.s3),
            SkeletonBox(width: 84, height: 36, radius: ReadInRadius.chip),
          ],
        ),
      );
}

/// The load-more spinner, the end of a list, or a load-more error with retry.
class ExploreListFooter extends StatelessWidget {
  const ExploreListFooter({super.key, required this.loadingMore, required this.failure, required this.onRetry});

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
