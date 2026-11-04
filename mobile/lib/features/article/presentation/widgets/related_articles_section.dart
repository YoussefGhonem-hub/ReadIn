import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../saved/presentation/widgets/save_button.dart';
import '../../domain/entities/article.dart';
import '../../domain/usecases/get_related_articles.dart';
import '../cubit/engagement_cubit.dart';
import '../cubit/related_articles_cubit.dart';
import 'article_card_tile.dart';
import 'engagement_seeder.dart';

/// "Related articles" at the end of the reader (F04), as a sliver: up to 4 compact cards for the version being read.
/// It loads once the article is shown and again when the reader switches the version, and stays hidden while it
/// loads, when there are none and when the request fails.
class RelatedArticlesSection extends StatefulWidget {
  const RelatedArticlesSection({super.key, required this.article, this.cubit});

  /// The article being read, in the version shown.
  final ArticleCard article;

  /// Builds the section's cubit; the app's by default.
  final RelatedArticlesCubit Function()? cubit;

  @override
  State<RelatedArticlesSection> createState() => _RelatedArticlesSectionState();
}

class _RelatedArticlesSectionState extends State<RelatedArticlesSection> {
  late final RelatedArticlesCubit _cubit = widget.cubit?.call() ?? getIt<RelatedArticlesCubit>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RelatedArticlesSection old) {
    super.didUpdateWidget(old);
    if (old.article.id != widget.article.id || old.article.language != widget.article.language) _load();
  }

  void _load() => unawaited(_cubit.load(widget.article.id, language: widget.article.language));

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: _cubit,
        child: EngagementSeeder<RelatedArticlesCubit, List<ArticleCard>>(
          cards: (cards) => cards,
          child: BlocBuilder<RelatedArticlesCubit, List<ArticleCard>>(
            builder: (context, cards) {
              if (cards.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, 0, ReadInSpace.s5, ReadInSpace.s8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(context.l10n.relatedArticles, style: context.textTheme.titleMedium),
                      ),
                      const SizedBox(height: ReadInSpace.s2),
                      for (final card in cards.take(GetRelatedArticles.limit)) _RelatedTile(article: card),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
}

/// A related card with the newest counters and the viewer's save (F10, F13); a tap opens it like any other card.
class _RelatedTile extends StatelessWidget {
  const _RelatedTile({required this.article});

  final ArticleCard article;

  @override
  Widget build(BuildContext context) {
    final engagement = context.select((EngagementCubit c) => c.state.of(article));
    return ArticleCardTile(
      article: engagement.applyTo(article),
      onTap: () => context.push('/a/${article.slug}'),
      actions: [SaveToggleButton(article: article)],
      showAttachments: false,
    );
  }
}
