import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../article/domain/entities/article.dart';
import '../../../profile/presentation/widgets/profile_link.dart';

/// "مقال النهارده" hero card (F03/F07, mockup "hero-card").
class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({super.key, required this.article, required this.onTap});

  final ArticleCard article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final titleDir = Bidi.detect(article.title) ?? Directionality.of(context);
    final author = article.author;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 128,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (article.coverUrl != null && article.coverUrl!.isNotEmpty)
                    AppNetworkImage(url: article.coverUrl!, borderRadius: BorderRadius.zero)
                  else
                    _CoverArt(),
                  PositionedDirectional(
                    top: ReadInSpace.s3,
                    start: ReadInSpace.s3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: ReadInSpace.s1),
                      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(ReadInRadius.sm)),
                      child: Text(
                        '${l10n.todayArticle} ✦',
                        style: context.textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ReadInSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: ReadInSpace.s2,
                    runSpacing: ReadInSpace.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      InfoTag(label: article.field.nameFor(lang)),
                      Text(l10n.readingTime(article.readingTimeMinutes), style: context.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: ReadInSpace.s2),
                  Text(
                    Bidi.isolateOppositeRuns(article.title, titleDir),
                    textDirection: titleDir,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(height: 1.55),
                  ),
                  const SizedBox(height: ReadInSpace.s3),
                  Row(
                    children: [
                      if (author == null) ...[
                        // A deleted account's articles stay up under "Deleted user" (SPEC §9.6), with no profile link.
                        const GenericAvatar(size: 26),
                        const SizedBox(width: ReadInSpace.s2),
                        Flexible(
                          child: Text(l10n.deletedUser,
                              style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ] else ...[
                        // The author's avatar and name open their profile (F14); the rest of the card opens the article.
                        ExcludeSemantics(
                          child: ProfileLink(
                            username: author.username,
                            child: UserAvatar(name: author.displayName, url: author.avatarUrl, size: 26),
                          ),
                        ),
                        const SizedBox(width: ReadInSpace.s2),
                        Flexible(
                          child: ProfileLink(
                            username: author.username,
                            child: BidiText(author.displayName, style: context.textTheme.labelMedium, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      if (author?.isVerified ?? false) ...[const SizedBox(width: 4), const VerifiedMark(size: 13)],
                      const Spacer(),
                      Text(l10n.todayArticleCta, style: context.textTheme.labelMedium?.copyWith(color: colors.primary)),
                      Icon(Icons.chevron_right_rounded, size: 18, color: colors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative token-colored cover used when an article has no cover image.
class _CoverArt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.primaryContainer,
      child: Stack(
        children: [
          PositionedDirectional(
            end: -40,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.primary.withValues(alpha: 0.25))),
            ),
          ),
          PositionedDirectional(
            end: 70,
            top: 26,
            child: Transform.rotate(
              angle: 0.45,
              child: Container(
                width: 56,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(26),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
