import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../article/presentation/widgets/article_card_tile.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../domain/entities/learning_path.dart';
import '../cubit/article_path_cubit.dart';
import '../path_routes.dart';
import 'path_widgets.dart';

/// "Next in path" at the end of the reader (F04, F09), as a sliver for the reader's scroll view: after the sources,
/// before related articles and comments. The block is built (and `GET /articles/{id}/path` sent) only once the sliver
/// is laid out within the viewport's cache extent, i.e. as the reader nears the end; it then stays. An article in no
/// path, or a failed call, renders nothing.
class NextInPathSliver extends StatefulWidget {
  const NextInPathSliver({super.key, required this.articleId});

  final String articleId;

  @override
  State<NextInPathSliver> createState() => _NextInPathSliverState();
}

class _NextInPathSliverState extends State<NextInPathSliver> {
  /// Set the first time the sliver comes near the viewport.
  bool _near = false;

  @override
  void didUpdateWidget(NextInPathSliver old) {
    super.didUpdateWidget(old);
    if (old.articleId != widget.articleId) _near = false;
  }

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
        builder: (context, constraints) {
          // Past the cache extent the viewport has nothing left to give this sliver.
          _near = _near || constraints.remainingCacheExtent > 0;
          return SliverToBoxAdapter(
            child: _near
                ? NextInPathBlock(key: ValueKey('next-in-path-${widget.articleId}'), articleId: widget.articleId)
                : const SizedBox.shrink(),
          );
        },
      );
}

/// The block itself; it owns its [ArticlePathCubit] and loads when it is first built.
class NextInPathBlock extends StatefulWidget {
  const NextInPathBlock({super.key, required this.articleId});

  final String articleId;

  @override
  State<NextInPathBlock> createState() => _NextInPathBlockState();
}

class _NextInPathBlockState extends State<NextInPathBlock> {
  late final ArticlePathCubit _cubit = getIt<ArticlePathCubit>();

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.load(widget.articleId));
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  Future<void> _join() async {
    if (!requireAccount(context)) return;
    final failure = await _cubit.join();
    if (!mounted) return;
    if (failure != null) {
      showActionFailure(context, failure);
    } else {
      showActionMessage(context, context.l10n.pathJoined);
    }
  }

  /// The path page; enrolling or leaving there changes the block, so it reloads on the way back.
  Future<void> _openPath(String slug) async {
    await context.push<void>(PathRoutes.of(slug));
    if (mounted) unawaited(_cubit.load(widget.articleId));
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ArticlePathCubit, ArticlePathState>(
        bloc: _cubit,
        builder: (context, state) {
          final articlePath = state.articlePath;
          if (state.status != ArticlePathStatus.ready || articlePath == null) return const SizedBox.shrink();
          // Its own block, a gap under the article's.
          return Padding(
            padding: const EdgeInsets.only(top: PageBlock.gap),
            child: NextInPathCard(
              articlePath: articlePath,
              joining: state.joining,
              onJoin: _join,
              onOpenPath: () => _openPath(articlePath.path.slug),
              onOpenNext: (slug) => context.push('/a/$slug'),
            ),
          );
        },
      );
}

/// The block itself, a white [PageBlock] on the canvas: "From the path: …", "{position} of {total}" and the progress,
/// then the next article (or "this is the last one" and the completion), and "Join path" when the viewer isn't
/// enrolled.
class NextInPathCard extends StatelessWidget {
  const NextInPathCard({
    super.key,
    required this.articlePath,
    required this.onJoin,
    required this.onOpenPath,
    required this.onOpenNext,
    this.joining = false,
  });

  final ArticlePath articlePath;
  final bool joining;
  final VoidCallback onJoin;
  final VoidCallback onOpenPath;
  final ValueChanged<String> onOpenNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final path = articlePath.path;
    final progress = path.progress;
    final next = articlePath.next;
    return PageBlock(
      padding: const EdgeInsets.all(PageBlock.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.route_rounded, size: 20, color: colors.primary),
              ),
              const SizedBox(width: ReadInSpace.s2),
              Expanded(
                child: Semantics(
                  link: true,
                  child: InkWell(
                    onTap: onOpenPath,
                    borderRadius: BorderRadius.circular(ReadInRadius.sm),
                    child: Text(
                      l10n.pathFrom(isolateTitle(path.title)),
                      style: context.textTheme.titleSmall?.copyWith(color: colors.link),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ReadInSpace.s2),
              Text(
                l10n.pathPosition(articlePath.position, articlePath.total),
                style: context.textTheme.labelMedium?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: ReadInSpace.s3),
            PathProgressRow(progress: progress),
          ],
          if (next != null) ...[
            const SizedBox(height: ReadInSpace.s4),
            Semantics(
              header: true,
              child: Text(l10n.pathNextInPath, style: context.textTheme.labelLarge?.copyWith(color: colors.textSecondary)),
            ),
            const SizedBox(height: ReadInSpace.s1),
            ArticleCardTile(article: next, onTap: () => onOpenNext(next.slug)),
          ] else ...[
            const SizedBox(height: ReadInSpace.s3),
            Text(l10n.pathLastArticle, style: context.textTheme.bodyMedium),
            if (articlePath.pathCompleted) ...[
              const SizedBox(height: ReadInSpace.s3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s2),
                decoration: BoxDecoration(color: colors.calloutTip, borderRadius: BorderRadius.circular(ReadInRadius.md)),
                child: Text(
                  l10n.pathCompletedCelebration,
                  style: context.textTheme.titleSmall?.copyWith(color: colors.success).withEmoji(),
                ),
              ),
            ],
          ],
          if (!path.isEnrolled) ...[
            const SizedBox(height: ReadInSpace.s3),
            OutlinedButton.icon(
              onPressed: joining ? null : onJoin,
              icon: joining
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.pathJoin),
            ),
          ],
        ],
      ),
    );
  }
}
