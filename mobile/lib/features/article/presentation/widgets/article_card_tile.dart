import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../domain/entities/article.dart';
import 'article_attachments_view.dart';

/// Compact feed row (mockup "article-card"): thumbnail, title, author ·
/// reading time, reaction/comment counts, then the post's images or PDF
/// pages full width (F26).
class ArticleCardTile extends StatelessWidget {
  const ArticleCardTile({super.key, required this.article, required this.onTap, this.actions = const []});

  final ArticleCard article;
  final VoidCallback onTap;

  /// Buttons at the end of the counters line, e.g. save (F13).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ReadInRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.colors.border))),
        child: article.attachments == null
            ? _Summary(article: article, actions: actions)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Summary(article: article, actions: actions),
                  const SizedBox(height: ReadInSpace.s3),
                  ArticleAttachmentsView(article: article),
                ],
              ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.article, required this.actions});

  final ArticleCard article;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final titleDir = Bidi.detect(article.title) ?? Directionality.of(context);
    final meta = context.textTheme.bodySmall;

    return Row(
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
              if (actions.isEmpty)
                _Counts(article: article)
              else
                Row(children: [Expanded(child: _Counts(article: article)), ...actions]),
            ],
          ),
        ),
      ],
    );
  }
}

/// Reaction total and comment count (live on visible cards, F27).
class _Counts extends StatelessWidget {
  const _Counts({required this.article});

  final ArticleCard article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: '${l10n.reactionsCount(article.reactionCount)}${l10n.listSeparator}${l10n.commentsCount(article.commentCount)}',
      excludeSemantics: true,
      child: Text('💡 ${article.reactionCount}    💬 ${article.commentCount}', style: context.textTheme.bodySmall?.withEmoji()),
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
