import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../mutes/presentation/widgets/mute_gate.dart';
import '../../domain/entities/article.dart';
import '../../domain/usecases/get_related_articles.dart';
import '../cubit/related_articles_cubit.dart';
import 'engagement_seeder.dart';
import 'post_card.dart';

/// "Related articles" at the end of the reader (F04), as a sliver: up to 4 post cards (F34) for the version being
/// read. It loads once the article is shown and again when the reader switches the version, and stays hidden while it
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
              final shown = cards.take(GetRelatedArticles.limit).toList();
              // With every card folded away by mutes or "show less" (F28), the heading goes too.
              if (shown.isEmpty || mutesHideAll(context, shown)) return const SliverToBoxAdapter(child: SizedBox.shrink());
              // Post cards full width under the heading, one after another on the background.
              return SliverPadding(
                padding: const EdgeInsets.only(bottom: ReadInSpace.s8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
                        child: Semantics(
                          header: true,
                          child: Text(context.l10n.relatedArticles, style: context.textTheme.titleMedium),
                        ),
                      ),
                      const SizedBox(height: ReadInSpace.s3),
                      for (final card in shown)
                        // Mutes and "show less" fold the card away at once (F28).
                        MuteGate(
                          key: ValueKey('related-${card.id}'),
                          article: card,
                          child: Padding(padding: const EdgeInsets.only(bottom: postCardGap), child: PostCard(article: card)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
}
