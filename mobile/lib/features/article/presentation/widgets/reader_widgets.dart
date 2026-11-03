import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/formatters.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../profile/presentation/widgets/profile_link.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../domain/entities/article.dart';

/// Thin amber progress bar pinned to the top of the reader (mockup "reader-progress").
class ReadingProgressBar extends StatelessWidget {
  const ReadingProgressBar({super.key, required this.progress});

  final ValueNotifier<double> progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (context, value, _) => Semantics(
        label: context.l10n.readingProgress,
        value: '${(value * 100).round()}%',
        child: LinearProgressIndicator(
          value: value,
          minHeight: 3,
          color: colors.accent,
          backgroundColor: colors.border,
        ),
      ),
    );
  }
}

/// Field tag, title, subtitle and byline.
class ArticleHeader extends StatelessWidget {
  const ArticleHeader({super.key, required this.article, required this.titleScale, this.authorAction});

  final ArticleDetails article;
  final double titleScale;

  /// At the end of the author row: the follow button (F12).
  final Widget? authorAction;

  @override
  Widget build(BuildContext context) {
    final card = article.card;
    final l10n = context.l10n;
    final uiLang = Localizations.localeOf(context).languageCode;
    final articleDir = card.language.startsWith('ar') ? TextDirection.rtl : TextDirection.ltr;
    final titleDir = Bidi.detect(card.title) ?? articleDir;
    final meta = context.textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: ReadInSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InfoTag(label: card.field.nameFor(uiLang)),
            if (article.topic != null) InfoTag(label: article.topic!.nameFor(uiLang), tone: InfoTagTone.neutral),
            Text(l10n.readingTime(card.readingTimeMinutes), style: meta),
          ],
        ),
        const SizedBox(height: ReadInSpace.s3),
        Semantics(
          header: true,
          child: Text(
            Bidi.isolateOppositeRuns(card.title, titleDir),
            textDirection: titleDir,
            style: context.textTheme.headlineSmall?.copyWith(fontSize: ReadInType.h3Size * titleScale + 2, height: 1.45),
          ),
        ),
        if (card.subtitle != null && card.subtitle!.isNotEmpty) ...[
          const SizedBox(height: ReadInSpace.s2),
          Text(
            Bidi.isolateOppositeRuns(card.subtitle!, Bidi.detect(card.subtitle!) ?? articleDir),
            textDirection: Bidi.detect(card.subtitle!) ?? articleDir,
            style: context.textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary),
          ),
        ],
        const SizedBox(height: ReadInSpace.s4),
        Row(
          children: [
            // Avatar and byline open the author's profile (F14).
            Expanded(
              child: ProfileLink(
                username: card.author.username,
                child: Row(
                  children: [
                    UserAvatar(name: card.author.displayName, url: card.author.avatarUrl, size: 36),
                    const SizedBox(width: ReadInSpace.s2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: BidiText(card.author.displayName, style: context.textTheme.labelLarge, overflow: TextOverflow.ellipsis),
                              ),
                              if (card.author.isVerified) ...[const SizedBox(width: 4), const VerifiedMark()],
                            ],
                          ),
                          Text(
                            // Isolated handle: in RTL, a bare "@readin · 8" would show as "readin · 8@".
                            '${Bidi.ltrIsolate('@${card.author.username}')} · ${formatDate(card.publishedAt, uiLang)}',
                            style: meta,
                            textDirection: Directionality.of(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (authorAction != null) ...[const SizedBox(width: ReadInSpace.s2), authorAction!],
          ],
        ),
      ],
    );
  }
}

/// Trust row (SPEC §11 F04, §20): reviewed by, last reviewed, version badge,
/// AI-assisted label (never hidden).
class TrustRow extends StatelessWidget {
  const TrustRow({super.key, required this.article});

  final ArticleDetails article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = article.card;
    final lang = Localizations.localeOf(context).languageCode;
    final items = <Widget>[
      if (card.isReviewed)
        InfoTag(
          label: article.reviewedBy == null ? l10n.badgeReviewed : l10n.reviewedBy(article.reviewedBy!.displayName),
          icon: Icons.check_rounded,
          tone: InfoTagTone.success,
        ),
      if (article.lastReviewedAt != null)
        InfoTag(label: l10n.lastReviewed(formatMonthYear(article.lastReviewedAt!, lang)), tone: InfoTagTone.neutral),
      if (card.versionBadge != null && card.versionBadge!.isNotEmpty) InfoTag(label: card.versionBadge!),
      if (card.isAiAssisted) InfoTag(label: l10n.aiAssisted, icon: Icons.auto_awesome_outlined, tone: InfoTagTone.accent),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: context.colors.border)),
      ),
      child: Wrap(spacing: ReadInSpace.s2, runSpacing: ReadInSpace.s2, children: items),
    );
  }
}

/// Mandatory sources list at the end of technical articles (SPEC §20).
class SourcesSection extends StatelessWidget {
  const SourcesSection({super.key, required this.sources, required this.onOpen});

  final List<ArticleSource> sources;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📚 ${context.l10n.sources}', style: context.textTheme.titleMedium),
        const SizedBox(height: ReadInSpace.s2),
        for (var i = 0; i < sources.length; i++)
          InkWell(
            onTap: () => onOpen(sources[i].url),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}.', style: context.textTheme.bodySmall),
                  const SizedBox(width: ReadInSpace.s2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Bidi.isolateOppositeRuns(sources[i].title, Directionality.of(context)),
                          style: context.textTheme.bodyMedium?.copyWith(color: colors.link),
                        ),
                        Text(
                          Uri.tryParse(sources[i].url)?.host ?? sources[i].url,
                          textDirection: TextDirection.ltr,
                          style: context.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.open_in_new, size: 16, color: colors.textSecondary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// S / M / L / XL picker.
Future<void> showFontSizeSheet(
  BuildContext context, {
  required ArticleFontSize current,
  required ValueChanged<ArticleFontSize> onChanged,
}) {
  final l10n = context.l10n;
  String label(ArticleFontSize s) => switch (s) {
        ArticleFontSize.s => l10n.fontSizeS,
        ArticleFontSize.m => l10n.fontSizeM,
        ArticleFontSize.l => l10n.fontSizeL,
        ArticleFontSize.xl => l10n.fontSizeXl,
      };
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, 0, ReadInSpace.s4, ReadInSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.fontSize, style: context.textTheme.titleMedium),
            const SizedBox(height: ReadInSpace.s4),
            SegmentedButton<ArticleFontSize>(
              segments: [for (final s in ArticleFontSize.values) ButtonSegment(value: s, label: Text(label(s)))],
              selected: {current},
              showSelectedIcon: false,
              onSelectionChanged: (v) {
                onChanged(v.first);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
