import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/blocks/text_blocks.dart';
import '../../../../shared/rdoc/rdoc_view.dart';
import '../../../../shared/utils/link_opener.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/article.dart';
import '../cubit/article_cubit.dart';
import '../widgets/reader_widgets.dart';

/// Article reader (F04). Deep link: `readin.app/a/{slug}`.
class ArticlePage extends StatelessWidget {
  const ArticlePage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final preferred = context.read<SettingsCubit>().state.articleLanguage;
    return BlocProvider(
      create: (_) => getIt<ArticleCubit>()..load(slug, preferredLanguage: preferred),
      child: const _ArticleView(),
    );
  }
}

class _ArticleView extends StatefulWidget {
  const _ArticleView();

  @override
  State<_ArticleView> createState() => _ArticleViewState();
}

class _ArticleViewState extends State<_ArticleView> {
  final _scroll = ScrollController();
  final _progress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final position = _scroll.position;
    final max = position.maxScrollExtent;
    _progress.value = max <= 0 ? 1 : (position.pixels / max).clamp(0, 1);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _progress.dispose();
    super.dispose();
  }

  double _fontSizeFor(ArticleFontSize size) => switch (size) {
        ArticleFontSize.s => ReadInArticleFontScale.s,
        ArticleFontSize.m => ReadInArticleFontScale.m,
        ArticleFontSize.l => ReadInArticleFontScale.l,
        ArticleFontSize.xl => ReadInArticleFontScale.xl,
      };

  void _showTerm(RTerm term) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.glossary, style: context.textTheme.labelMedium?.copyWith(color: context.colors.primary)),
              const SizedBox(height: ReadInSpace.s2),
              Text(term.text, textDirection: TextDirection.ltr, style: context.textTheme.headlineSmall),
              const SizedBox(height: ReadInSpace.s3),
              Text(context.l10n.glossaryComingSoon(term.text), style: context.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>();
    final fontSize = settings.state.fontSize;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ArticleCubit, ArticleState>(
          builder: (context, state) {
            final article = state.article;
            return Column(
              children: [
                ReadingProgressBar(progress: _progress),
                _TopBar(
                  article: article,
                  switching: state.switchingLanguage,
                  onLanguage: (lang) => context.read<ArticleCubit>().switchLanguage(lang),
                  onFontSize: () => showFontSizeSheet(context, current: fontSize, onChanged: settings.setFontSize),
                ),
                Expanded(
                  child: switch (state.status) {
                    ArticleStatus.loading => const _ReaderSkeleton(),
                    ArticleStatus.failure => ErrorView(
                        failure: state.failure!,
                        onRetry: () => context.read<ArticleCubit>().retry(settings.state.articleLanguage),
                      ),
                    ArticleStatus.ready => _ReaderBody(
                        article: article!,
                        controller: _scroll,
                        bodyFontSize: _fontSizeFor(fontSize),
                        onTerm: _showTerm,
                      ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.article, required this.switching, required this.onLanguage, required this.onFontSize});

  final ArticleDetails? article;
  final bool switching;
  final ValueChanged<String> onLanguage;
  final VoidCallback onFontSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = article;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: ReadInSpace.s1),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const BackButtonIcon(),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          const Spacer(),
          if (a != null && a.hasBothLanguages)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s1),
              child: SegmentedButton<String>(
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'ar-EG', label: Text(l10n.langToggleArEg), tooltip: l10n.articleLangArEg),
                  ButtonSegment(value: 'en', label: Text(l10n.langToggleEn), tooltip: l10n.articleLangEn),
                ],
                selected: {a.card.language},
                onSelectionChanged: switching ? null : (v) => onLanguage(v.first),
              ),
            ),
          IconButton(tooltip: l10n.fontSize, icon: const Icon(Icons.format_size_rounded), onPressed: onFontSize),
          IconButton(
            tooltip: l10n.share,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: a == null
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoonTitle))),
          ),
        ],
      ),
    );
  }
}

class _ReaderBody extends StatelessWidget {
  const _ReaderBody({required this.article, required this.controller, required this.bodyFontSize, required this.onTerm});

  final ArticleDetails article;
  final ScrollController controller;
  final double bodyFontSize;
  final ValueChanged<RTerm> onTerm;

  @override
  Widget build(BuildContext context) {
    final direction = RDocScope.directionForLanguage(article.card.language);
    final showSummary = article.summary != null && article.summary!.isNotEmpty && !article.content.hasSummaryBlock;
    const gutter = EdgeInsets.symmetric(horizontal: ReadInSpace.s5);

    return RDocScope(
      baseDirection: direction,
      bodyFontSize: bodyFontSize,
      onLinkTap: openExternalLink,
      onTermTap: onTerm,
      child: Builder(
        builder: (context) => CustomScrollView(
          controller: controller,
          slivers: [
            SliverPadding(
              padding: gutter.copyWith(top: ReadInSpace.s2),
              sliver: SliverToBoxAdapter(
                child: ArticleHeader(article: article, titleScale: RDocScope.of(context).scale),
              ),
            ),
            SliverPadding(
              padding: gutter.copyWith(top: ReadInSpace.s4, bottom: ReadInSpace.s4),
              sliver: SliverToBoxAdapter(child: TrustRow(article: article)),
            ),
            if (showSummary)
              SliverPadding(
                padding: gutter.copyWith(bottom: ReadInSpace.s4),
                sliver: SliverToBoxAdapter(
                  child: SummaryBox(
                    direction: direction,
                    child: Text(article.summary!, textDirection: direction, style: rdocBodyStyle(context, direction, factor: 0.94)),
                  ),
                ),
              ),
            SliverPadding(padding: gutter, sliver: RDocSliver(article.content)),
            SliverPadding(
              padding: gutter.copyWith(top: ReadInSpace.s4, bottom: ReadInSpace.s8),
              sliver: SliverToBoxAdapter(child: SourcesSection(sources: article.sources, onOpen: openExternalLink)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderSkeleton extends StatelessWidget {
  const _ReaderSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(ReadInSpace.s5),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SkeletonBox(width: 80, height: 18),
          const SizedBox(height: ReadInSpace.s4),
          const SkeletonBox(height: 26),
          const SizedBox(height: ReadInSpace.s2),
          const SkeletonBox(width: 220, height: 26),
          const SizedBox(height: ReadInSpace.s5),
          const Row(children: [
            SkeletonBox(width: 36, height: 36, radius: 18),
            SizedBox(width: ReadInSpace.s2),
            SkeletonBox(width: 140),
          ]),
          const SizedBox(height: ReadInSpace.s6),
          for (var i = 0; i < 8; i++) ...[
            SkeletonBox(width: i.isEven ? double.infinity : 260),
            const SizedBox(height: ReadInSpace.s3),
          ],
        ],
      );
}
