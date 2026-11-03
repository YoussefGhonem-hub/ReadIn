import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../domain/entities/article.dart';

/// Compact feed row (mockup "article-card"): thumbnail, title, author ·
/// reading time, reaction/comment counts.
class ArticleCardTile extends StatelessWidget {
  const ArticleCardTile({super.key, required this.article, required this.onTap});

  final ArticleCard article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final titleDir = Bidi.detect(article.title) ?? Directionality.of(context);
    final meta = context.textTheme.bodySmall;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ReadInRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(url: article.coverUrl, fieldSlug: article.field.slug),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: ReadInSpace.s1,
                    runSpacing: ReadInSpace.s1,
                    children: [
                      InfoTag(label: article.field.nameFor(lang)),
                      if (article.isReviewed)
                        InfoTag(label: l10n.badgeReviewed, icon: Icons.check_rounded, tone: InfoTagTone.success),
                    ],
                  ),
                  const SizedBox(height: ReadInSpace.s1),
                  Text(
                    Bidi.isolateOppositeRuns(article.title, titleDir),
                    textDirection: titleDir,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: ReadInSpace.s1),
                  Row(
                    children: [
                      Flexible(
                        child: BidiText(article.author.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: meta),
                      ),
                      if (article.author.isVerified) ...[const SizedBox(width: 3), const VerifiedMark(size: 12)],
                      Text('  ·  ${l10n.readingTime(article.readingTimeMinutes)}', style: meta),
                    ],
                  ),
                  const SizedBox(height: ReadInSpace.s1),
                  Text('💡 ${article.reactionCount}    💬 ${article.commentCount}', style: meta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.fieldSlug});

  final String? url;
  final String fieldSlug;

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    if (url != null && url!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: AppNetworkImage(url: url!, borderRadius: BorderRadius.circular(ReadInRadius.md)),
      );
    }
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.md)),
      alignment: Alignment.center,
      child: Text(
        '</>',
        textDirection: TextDirection.ltr,
        style: codeTextStyle(size: 15, color: colors.onPrimaryContainer).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
