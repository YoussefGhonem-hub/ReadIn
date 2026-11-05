import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/field_style.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../article/presentation/widgets/article_card_tile.dart';
import '../../../tags/domain/entities/tag.dart';
import '../../../tags/presentation/tag_routes.dart';
import '../../domain/entities/search.dart';

/// An article result as the compact row (F34) without the post's attachments (the thumbnail shows the first image or
/// PDF page instead), with the viewer's latest counters, and "Found in the attached PDF" when only the PDF matched. It
/// opens the reader in the version that matched.
class SearchArticleRow extends StatelessWidget {
  const SearchArticleRow({super.key, required this.result, this.onOpen});

  final SearchArticle result;

  /// Runs before the reader opens.
  final VoidCallback? onOpen;

  static String locationOf(SearchArticle result) =>
      '/a/${Uri.encodeComponent(result.article.slug)}?lang=${Uri.encodeQueryComponent(result.article.language)}';

  @override
  Widget build(BuildContext context) {
    final article = result.article;
    final engagement = context.select((EngagementCubit c) => c.state.of(article));
    return ArticleCardTile(
      key: ValueKey('search-article-${article.id}'),
      article: engagement.applyTo(article),
      onTap: () {
        onOpen?.call();
        unawaited(GoRouter.maybeOf(context)?.push<void>(locationOf(result)));
      },
      note: result.foundInAttachment ? const FoundInPdfNote() : null,
      showAttachments: false,
    );
  }
}

/// "لقيناها في ملف الـ PDF المرفق" / "Found in the attached PDF".
class FoundInPdfNote extends StatelessWidget {
  const FoundInPdfNote({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      key: const ValueKey('search-found-in-pdf'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Icon(Icons.picture_as_pdf_outlined, size: 16, color: colors.primary)),
        const SizedBox(width: ReadInSpace.s1),
        Flexible(
          child: BidiText(
            context.l10n.searchFoundInPdf,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// A field or a topic: its field's icon and color, its name, and "Field · 12 articles" or "{field} · 12 articles". It
/// opens the field page (F15).
class SearchTopicRow extends StatelessWidget {
  const SearchTopicRow({super.key, required this.topic, this.onOpen});

  final SearchTopic topic;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final color = FieldStyle.color(colors, topic.color);
    final kind = topic.isField ? l10n.searchKindField : topic.fieldName;
    return _ResultRow(
      key: ValueKey('search-topic-${topic.kind.name}-${topic.id}'),
      location: topic.location,
      onOpen: onOpen,
      leading: Container(
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withValues(alpha: 0.12), colors.surface),
          borderRadius: BorderRadius.circular(ReadInRadius.md),
        ),
        child: Icon(FieldStyle.icon(topic.icon), color: color),
      ),
      title: BidiText(topic.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall),
      subtitle: BidiText('$kind · ${l10n.tagPageArticleCount(topic.articleCount)}', maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// A tag: `#name` in its own direction and its article count. It opens the tag page (F32).
class SearchTagRow extends StatelessWidget {
  const SearchTagRow({super.key, required this.tag, this.onOpen});

  final ArticleTag tag;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _ResultRow(
      key: ValueKey('search-tag-${tag.slug}'),
      location: TagRoutes.of(tag.slug),
      onOpen: onOpen,
      leading: Container(
        decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.md)),
        child: Icon(Icons.tag_rounded, color: colors.onPrimaryContainer),
      ),
      title: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          '#${tag.name}',
          textDirection: Bidi.detect(tag.name) ?? Directionality.of(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleSmall,
        ),
      ),
      subtitle: Text(context.l10n.tagPageArticleCount(tag.articleCount)),
    );
  }
}

/// A topic or tag row: a 44 px leading box, a title and a subtitle, and a chevron; the whole row is one link.
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    super.key,
    required this.location,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onOpen,
  });

  final String location;
  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    void open() {
      onOpen?.call();
      unawaited(GoRouter.maybeOf(context)?.push<void>(location));
    }

    return MergeSemantics(
      child: Semantics(
        link: true,
        child: InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
              child: Row(
                children: [
                  ExcludeSemantics(child: SizedBox.square(dimension: 44, child: leading)),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        title,
                        const SizedBox(height: 2),
                        DefaultTextStyle.merge(
                          style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                          child: subtitle,
                        ),
                      ],
                    ),
                  ),
                  ExcludeSemantics(child: Icon(Icons.chevron_right_rounded, color: colors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
