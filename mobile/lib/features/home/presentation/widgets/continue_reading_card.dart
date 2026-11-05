import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../article/presentation/widgets/article_card_tile.dart';
import '../../../paths/presentation/widgets/path_widgets.dart';
import '../../domain/entities/continue_reading.dart';

/// "كمّل القراءة" (F03): the last unfinished article, with how far the viewer scrolled. Opens the reader in the
/// version they were reading, which resumes from their last position. A full-width block on the canvas (F34).
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({super.key, required this.item, required this.onTap});

  final ContinueReading item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final article = item.article;
    final titleDir = Bidi.detect(article.title) ?? Directionality.of(context);
    return PageBlock(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s3),
          child: Row(
            children: [
              ArticleThumbnail(url: article.coverUrl, size: 56),
              const SizedBox(width: ReadInSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.continueReading,
                            style: context.textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: ReadInSpace.s2),
                        InfoTag(label: article.field.nameFor(lang), tone: InfoTagTone.neutral),
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
                    const SizedBox(height: ReadInSpace.s2),
                    Semantics(
                      label: l10n.continueReadingProgress(item.percent),
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          Expanded(child: PathProgressBar(value: item.fraction, color: colors.accent, height: 4)),
                          const SizedBox(width: ReadInSpace.s2),
                          Text('${item.percent}%', textDirection: TextDirection.ltr, style: context.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ReadInSpace.s1),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
