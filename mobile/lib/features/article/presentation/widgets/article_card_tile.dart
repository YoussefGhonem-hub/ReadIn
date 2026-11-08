import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../moderation/presentation/widgets/reported_collapse.dart';
import '../../../profile/presentation/widgets/profile_link.dart';
import '../../domain/entities/article.dart';
import 'article_attachments_view.dart';

/// Compact article row (mockup "article-card"): thumbnail, title, author ·
/// reading time, reaction/comment counts, then the post's images or PDF
/// pages full width (F26). Lists people scan rather than read keep it (Saved,
/// learning paths, "Next in path", the editor's preview, search results);
/// feeds show the post card instead (F34). Search results leave the
/// attachments out ([showAttachments]), like the web.
class ArticleCardTile extends StatelessWidget {
  const ArticleCardTile({
    super.key,
    required this.article,
    required this.onTap,
    this.actions = const [],
    this.note,
    this.showAttachments = true,
  });

  final ArticleCard article;
  final VoidCallback onTap;

  /// Buttons at the end of the counters line, e.g. save (F13).
  final List<Widget> actions;

  /// A line under the counters, e.g. search's "Found in the attached PDF" (F16).
  final Widget? note;

  /// The post's images or PDF pages full width below the row. Without them (search results, F16) the thumbnail falls
  /// back to the first image, or the PDF's first page, when the article has no cover.
  final bool showAttachments;

  String? get _thumbnailUrl {
    final cover = article.coverUrl;
    final attachments = article.attachments;
    if ((cover != null && cover.isNotEmpty) || showAttachments || attachments == null) return cover;
    return attachments.images.firstOrNull?.variants.firstOrNull?.url ?? attachments.document?.pages.firstOrNull?.thumbUrl;
  }

  @override
  Widget build(BuildContext context) => ReportedCollapse(reported: cardReportedByMe(context, article), child: _row(context));

  Widget _row(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ReadInRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.colors.border))),
        child: !showAttachments || article.attachments == null
            ? _Summary(article: article, thumbnailUrl: _thumbnailUrl, actions: actions, note: note)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Summary(article: article, thumbnailUrl: _thumbnailUrl, actions: actions, note: note),
                  const SizedBox(height: ReadInSpace.s3),
                  ArticleAttachmentsView(article: article),
                ],
              ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.article, required this.thumbnailUrl, required this.actions, this.note});

  final ArticleCard article;
  final String? thumbnailUrl;
  final List<Widget> actions;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final titleDir = Bidi.detect(article.title) ?? Directionality.of(context);
    final meta = context.textTheme.bodySmall;
    final author = article.author;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArticleThumbnail(url: thumbnailUrl),
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
                  // The author's name opens their profile (F14); the rest of the card opens the article.
                  Flexible(
                    child: author == null
                        // A deleted account's articles stay up under "Deleted user" (SPEC §9.6), with no profile link.
                        ? BidiText(l10n.deletedUser, maxLines: 1, overflow: TextOverflow.ellipsis, style: meta)
                        : ProfileLink(
                            username: author.username,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: BidiText(author.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: meta),
                                ),
                                if (author.isVerified) ...[const SizedBox(width: 3), const VerifiedMark(size: 12)],
                              ],
                            ),
                          ),
                  ),
                  Text('  ·  ${l10n.readingTime(article.readingTimeMinutes)}', style: meta),
                ],
              ),
              const SizedBox(height: ReadInSpace.s1),
              if (actions.isEmpty)
                _Counts(article: article)
              else
                Row(children: [Expanded(child: _Counts(article: article)), ...actions]),
              if (note case final note?) ...[const SizedBox(height: ReadInSpace.s1), note],
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

/// An article's cover as a square thumbnail, or the token-colored `</>` placeholder when it has none. Also the
/// Continue reading card's thumbnail (F03).
class ArticleThumbnail extends StatelessWidget {
  const ArticleThumbnail({super.key, required this.url, this.size = 64});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
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
        style: codeTextStyle(size: size * 15 / 64, color: colors.onPrimaryContainer).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
