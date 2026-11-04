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

/// Field tag, title, subtitle and byline. A deleted author's byline is "Deleted user" with a neutral avatar and the
/// date only: no @username, verified mark or [authorAction] (SPEC §9.6).
class ArticleHeader extends StatelessWidget {
  const ArticleHeader({super.key, required this.article, required this.titleScale, this.authorAction});

  final ArticleDetails article;
  final double titleScale;

  /// At the end of the author row: the follow button (F12). Never shown for a deleted author.
  final Widget? authorAction;

  @override
  Widget build(BuildContext context) {
    final card = article.card;
    final author = card.author;
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
            if (author == null) ...[
              // A deleted account's articles stay up under "Deleted user" (SPEC §9.6), with no profile link.
              const GenericAvatar(size: 36),
              const SizedBox(width: ReadInSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.deletedUser, style: context.textTheme.labelLarge?.copyWith(color: context.colors.textSecondary)),
                    Text(formatDate(card.publishedAt, uiLang), style: meta, textDirection: Directionality.of(context)),
                  ],
                ),
              ),
            ] else
              // Avatar and byline open the author's profile (F14).
              Expanded(
                child: ProfileLink(
                  username: author.username,
                  child: Row(
                    children: [
                      UserAvatar(name: author.displayName, url: author.avatarUrl, size: 36),
                      const SizedBox(width: ReadInSpace.s2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: BidiText(author.displayName, style: context.textTheme.labelLarge, overflow: TextOverflow.ellipsis),
                                ),
                                if (author.isVerified) ...[const SizedBox(width: 4), const VerifiedMark()],
                              ],
                            ),
                            Text(
                              // Isolated handle: in RTL, a bare "@readin · 8" would show as "readin · 8@".
                              '${Bidi.ltrIsolate('@${author.username}')} · ${formatDate(card.publishedAt, uiLang)}',
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
            if (author != null && authorAction != null) ...[const SizedBox(width: ReadInSpace.s2), authorAction!],
          ],
        ),
      ],
    );
  }
}

/// Trust row (SPEC §11 F04, §20): version badge and AI-assisted label (never
/// hidden). There is no review step (user decision, 2026-11-03).
class TrustRow extends StatelessWidget {
  const TrustRow({super.key, required this.article});

  final ArticleDetails article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = article.card;
    final items = <Widget>[
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

/// The health disclaimer of an article in a sensitive field (medicine, public health; SPEC F04): information, not an
/// error, in the UI language.
class HealthDisclaimer extends StatelessWidget {
  const HealthDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ReadInSpace.s3),
        decoration: BoxDecoration(
          color: colors.calloutInfo,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          border: BorderDirectional(start: BorderSide(color: colors.calloutInfoAccent, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.medical_services_outlined, size: 20, color: colors.calloutInfoAccent),
            const SizedBox(width: ReadInSpace.s2),
            Expanded(
              child: Text(
                context.l10n.healthDisclaimer,
                style: context.textTheme.bodySmall?.copyWith(color: colors.textPrimary, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The article's tags (`#tag`), as plain chips under the content: they don't open anything (F04).
class ArticleTags extends StatelessWidget {
  const ArticleTags({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: ReadInSpace.s2,
      runSpacing: ReadInSpace.s2,
      children: [
        // InfoTag isolates a tag written in the other direction with its "#": "#EF Core" stays as is in RTL.
        for (final tag in tags) InfoTag(label: '#$tag', tone: InfoTagTone.neutral),
      ],
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
