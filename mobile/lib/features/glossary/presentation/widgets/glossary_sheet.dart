import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/glossary_term.dart';
import '../cubit/glossary_term_cubit.dart';

/// Opens the glossary sheet of a term tapped in the reader (F21). [termId] is the RDoc node's `termId` and [text] the
/// words tapped; [language] is the article version being read and [articleId] the open article, which the term's
/// articles leave out. Completes with the slug of the article the reader picked in the sheet, for the caller to open.
Future<String?> showGlossarySheet(
  BuildContext context, {
  required String termId,
  required String text,
  required String language,
  required String articleId,
  GlossaryTermCubit Function()? cubit,
}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider(
        create: (_) => (cubit?.call() ?? getIt<GlossaryTermCubit>())..load(termId, language: language),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.92,
          builder: (context, controller) =>
              GlossaryTermView(text: text, language: language, articleId: articleId, controller: controller),
        ),
      ),
    );

/// The sheet's content: the English term, its explanation for the version being read, then the articles that use it.
class GlossaryTermView extends StatelessWidget {
  const GlossaryTermView({super.key, required this.text, required this.language, required this.articleId, this.controller});

  /// The words tapped in the article: the header until the term loads, and when it isn't in the glossary.
  final String text;

  /// The article version being read: `ar-EG` leads with the Arabic explanation, `en` with the English definition.
  final String language;

  /// The open article, left out of the term's articles.
  final String articleId;
  final ScrollController? controller;

  /// The sheet lists at most this many of the term's articles.
  static const maxArticles = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<GlossaryTermCubit>().state;
    final term = state.term;
    final articles = term == null ? const <GlossaryArticle>[] : term.articles.where((a) => a.id != articleId).take(maxArticles).toList();

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s6),
      children: [
        // The API's term is English; the tapped words can be in either script.
        _Header(term: term?.term ?? text, direction: term != null ? TextDirection.ltr : Bidi.detect(text) ?? TextDirection.ltr),
        const SizedBox(height: ReadInSpace.s4),
        switch (state.status) {
          GlossaryTermStatus.loading => const _Skeleton(),
          GlossaryTermStatus.notFound => Semantics(
              liveRegion: true,
              child: Text(l10n.glossaryNotFound, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
            ),
          GlossaryTermStatus.failure => ErrorView(
              failure: state.failure!,
              compact: true,
              onRetry: context.read<GlossaryTermCubit>().retry,
            ),
          GlossaryTermStatus.ready => _Definition(term: term!, language: language),
        },
        if (articles.isNotEmpty) ...[
          const SizedBox(height: ReadInSpace.s6),
          Semantics(header: true, child: Text(l10n.glossaryArticles, style: context.textTheme.titleSmall)),
          const SizedBox(height: ReadInSpace.s2),
          for (final article in articles) _ArticleRow(article: article),
        ],
      ],
    );
  }
}

/// "Glossary" over the term. The term is isolated in its own direction, so `.NET` or `C#` never flip in RTL.
class _Header extends StatelessWidget {
  const _Header({required this.term, required this.direction});

  final String term;
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isolated = direction == TextDirection.ltr ? Bidi.ltrIsolate(term) : Bidi.isolateOppositeRuns(term, direction);
    return Semantics(
      header: true,
      label: '${l10n.glossary}${l10n.listSeparator}$term',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.glossary, style: context.textTheme.labelMedium?.copyWith(color: context.colors.primary)),
          const SizedBox(height: ReadInSpace.s1),
          Text(isolated, textDirection: direction, style: _scriptStyle(context.textTheme.headlineSmall!, direction)),
        ],
      ),
    );
  }
}

/// The explanation for the version being read (SPEC F21): an `ar-EG` article leads with the Arabic explanation, then
/// the English definition; an `en` article shows the English definition, plus the Arabic explanation in the Arabic UI.
class _Definition extends StatelessWidget {
  const _Definition({required this.term, required this.language});

  final GlossaryTerm term;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final explanation = term.explanationAr.trim();
    final definition = term.definitionEn.trim();
    final arabicUi = Localizations.localeOf(context).languageCode == 'ar';

    final List<Widget> parts;
    if (language.startsWith('ar')) {
      parts = [
        if (explanation.isNotEmpty) _GlossaryText(explanation, direction: TextDirection.rtl),
        if (definition.isNotEmpty)
          _GlossaryText(definition, direction: TextDirection.ltr, secondary: true, label: l10n.glossaryInEnglish),
      ];
    } else {
      parts = [
        if (definition.isNotEmpty) _GlossaryText(definition, direction: TextDirection.ltr),
        if (arabicUi && explanation.isNotEmpty)
          _GlossaryText(explanation, direction: TextDirection.rtl, secondary: true, label: l10n.glossaryInArabic),
      ];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < parts.length; i++) ...[if (i > 0) const SizedBox(height: ReadInSpace.s4), parts[i]],
      ],
    );
  }
}

/// A paragraph in its own [direction], full width so it starts on its own side in either UI language. Runs in the
/// other script are isolated (SPEC §14.2). A [label] above it says which language it is.
class _GlossaryText extends StatelessWidget {
  const _GlossaryText(this.text, {required this.direction, this.secondary = false, this.label});

  final String text;
  final TextDirection direction;

  /// The second language: smaller and in the secondary color.
  final bool secondary;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = secondary
        ? context.textTheme.bodyMedium!.copyWith(color: colors.textSecondary)
        : context.textTheme.bodyLarge!.copyWith(height: 1.7);
    final paragraph = Text(
      Bidi.isolateOppositeRuns(text, direction),
      textDirection: direction,
      style: _scriptStyle(base, direction),
    );
    if (label == null) return paragraph;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label!, style: context.textTheme.labelSmall),
          const SizedBox(height: ReadInSpace.s1),
          paragraph,
        ],
      ),
    );
  }
}

/// One of the term's articles: its title in its own language's direction, field and reading time. A tap closes the
/// sheet with the article's slug.
class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article});

  final GlossaryArticle article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final field = article.field.nameFor(Localizations.localeOf(context).languageCode);
    final time = l10n.readingTime(article.readingTimeMinutes);
    final titleDir = article.language.startsWith('ar') ? TextDirection.rtl : TextDirection.ltr;

    return Semantics(
      button: true,
      label: '${article.title}${l10n.listSeparator}$field${l10n.listSeparator}$time',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(article.slug),
        borderRadius: BorderRadius.circular(ReadInRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Bidi.isolateOppositeRuns(article.title, titleDir),
                      textDirection: titleDir,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _scriptStyle(context.textTheme.titleSmall!.copyWith(height: 1.5), titleDir),
                    ),
                    const SizedBox(height: ReadInSpace.s1),
                    // The field on its own, so `.NET` keeps its dot in RTL (as on feed cards).
                    Row(
                      children: [
                        Flexible(child: BidiText(field, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall)),
                        Text('  ·  $time', style: context.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ReadInSpace.s2),
              Icon(Icons.chevron_right_rounded, size: 20, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lines of the explanation and the articles while the term loads. Static, so it respects "reduce motion".
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Semantics(
        label: context.l10n.loading,
        liveRegion: true,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(),
            SizedBox(height: ReadInSpace.s3),
            SkeletonBox(),
            SizedBox(height: ReadInSpace.s3),
            SkeletonBox(width: 200),
            SizedBox(height: ReadInSpace.s5),
            SkeletonBox(width: 90, height: 12),
            SizedBox(height: ReadInSpace.s2),
            SkeletonBox(width: 260),
            SizedBox(height: ReadInSpace.s6),
            SkeletonBox(width: 160, height: 16),
            SizedBox(height: ReadInSpace.s3),
            SkeletonBox(height: 40),
            SizedBox(height: ReadInSpace.s3),
            SkeletonBox(height: 40),
          ],
        ),
      );
}

/// [base] in the font of the script [direction] is written in, with the other one as fallback.
TextStyle _scriptStyle(TextStyle base, TextDirection direction) {
  final rtl = direction == TextDirection.rtl;
  return base.copyWith(
    fontFamily: rtl ? ReadInFonts.arabic : ReadInFonts.latin,
    fontFamilyFallback: [rtl ? ReadInFonts.latin : ReadInFonts.arabic],
  );
}
