import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../moderation/presentation/cubit/report_cubit.dart';
import '../../domain/entities/comment.dart';
import '../../domain/usecases/comment_usecases.dart';
import '../cubit/comments_cubit.dart';
import '../cubit/mention_suggestions_cubit.dart';
import 'comment_composer.dart';
import 'comment_tile.dart';
import 'comments_sheet.dart';

/// The article's comments right under it in the reader (F11), as on the web: a sliver for the reader's scroll view,
/// after the sources and before "Next in path" and related articles, in its own block. "التعليقات (N)" with Top /
/// Newest, the composer (or the sign-in invitation for guests), the first [GetComments.firstPageSize] threads, then
/// "Show more comments" for [GetComments.pageSize] more a tap. It loads when the reader shows the article, and follows
/// the article's live comment events (F27) while the reader is open.
///
/// New top-level comments go straight to the top of the list ("Newest") only while that top is on screen; otherwise
/// they wait behind "N new comments" there. Reply and Edit bring the composer into view, focused. The reader's comment
/// count and links to a comment scroll here ([ArticleCommentsSectionState.reveal]).
class ArticleCommentsSection extends StatefulWidget {
  const ArticleCommentsSection({super.key, required this.article, this.comments, this.mentions, this.reportCubit});

  /// The article being read.
  final ArticleCard article;

  /// Build the section's cubits; the app's by default.
  final CommentsCubit Function()? comments;
  final MentionSuggestionsCubit Function()? mentions;

  /// Test seam for the report sheet; the app takes the cubit from DI.
  final ReportCubit Function()? reportCubit;

  @override
  State<ArticleCommentsSection> createState() => ArticleCommentsSectionState();
}

class ArticleCommentsSectionState extends State<ArticleCommentsSection> {
  final _headingKey = GlobalKey();

  /// Rounds of [reveal]: each lays out the article's blocks around the guess, so a few are enough.
  static const _maxRevealPasses = 6;

  /// Scrolls the reader so the section's heading is at the top (or as close as the end of the page allows). The
  /// article above is laid out lazily, so where the section starts is a guess until the blocks before it are built:
  /// each round scrolls to the guess and lets a frame lay them out, until the section stays put. The user scrolling
  /// meanwhile stops it.
  Future<void> reveal() async {
    final animate = !MediaQuery.disableAnimationsOf(context);
    for (var pass = 0; pass < _maxRevealPasses; pass++) {
      final target = _headingKey.currentContext;
      if (!mounted || target == null || !target.mounted) return;
      final position = Scrollable.of(target).position;
      if (pass > 0 && position.isScrollingNotifier.value) return;
      final before = position.pixels;
      await Scrollable.ensureVisible(
        target,
        duration: pass == 0 && animate ? ReadInMotion.slow : Duration.zero,
        curve: Curves.easeOutCubic,
      );
      if ((position.pixels - before).abs() < 0.5) return;
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        // Another article gets its own comments.
        key: ValueKey(widget.article.id),
        providers: [
          BlocProvider<CommentsCubit>(
            lazy: false,
            create: (_) => (widget.comments?.call() ?? getIt<CommentsCubit>())..load(widget.article.id),
          ),
          BlocProvider<MentionSuggestionsCubit>(create: (_) => widget.mentions?.call() ?? getIt<MentionSuggestionsCubit>()),
        ],
        child: _CommentsBlock(article: widget.article, headingKey: _headingKey, reportCubit: widget.reportCubit),
      );
}

/// The section once its cubits are provided.
class _CommentsBlock extends StatefulWidget {
  const _CommentsBlock({required this.article, required this.headingKey, this.reportCubit});

  final ArticleCard article;
  final GlobalKey headingKey;
  final ReportCubit Function()? reportCubit;

  @override
  State<_CommentsBlock> createState() => _CommentsBlockState();
}

class _CommentsBlockState extends State<_CommentsBlock> with CommentActions<_CommentsBlock> {
  final _composerKey = GlobalKey();
  final _listTopKey = GlobalKey();
  late final CommentsCubit _comments = context.read<CommentsCubit>();
  ScrollPosition? _position;

  /// The list's top still counts as on screen this far above the reader's top edge (as the sheet's "near the top").
  static const _onScreenSlack = 120.0;

  @override
  ArticleCard get commentsArticle => widget.article;

  @override
  ReportCubit Function()? get reportCubit => widget.reportCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == _position) return;
    _position?.removeListener(_followListTop);
    _position = position?..addListener(_followListTop);
    WidgetsBinding.instance.addPostFrameCallback((_) => _followListTop());
  }

  @override
  void dispose() {
    _position?.removeListener(_followListTop);
    super.dispose();
  }

  /// Tells the cubit whether the top of the list is on screen (from [_onScreenSlack] above the reader's top edge to
  /// its bottom edge), as the web does: only then do new comments in "Newest" go straight in, where the reader sees
  /// them arrive; otherwise nothing moves under the reader and they wait behind "N new comments".
  void _followListTop() {
    final box = _listTopKey.currentContext?.findRenderObject();
    final position = _position;
    if (!mounted || box is! RenderBox || !box.attached || !box.hasSize || position == null) return;
    if (!position.hasPixels || !position.hasViewportDimension) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final top = viewport.getOffsetToReveal(box, 0).offset - position.pixels;
    _comments.setNearTop(top > -_onScreenSlack && top < position.viewportDimension);
  }

  /// Reply or Edit on a comment further down: the composer (which takes the focus itself) comes into view, its top
  /// edge at the reader's top when it was above it, so the keyboard doesn't cover it. It jumps there at once, before
  /// the reply bar shows at the composer's top: the field's own scroll to its caret, once focused, then has nothing to
  /// do (it would cut an animation short and leave the reply bar above the screen).
  void _revealComposer() {
    final target = _composerKey.currentContext;
    if (target == null) return;
    unawaited(Scrollable.ensureVisible(target, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CommentsCubit>().state;
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);

    // A box inside the block: its own ink layer, so taps ripple above the block's `surface` (as in the reader).
    Widget box(Widget child) => SliverToBoxAdapter(child: Material(type: MaterialType.transparency, child: child));

    final List<Widget> list = switch (state.status) {
      CommentsStatus.loading => [box(const CommentsSkeleton())],
      CommentsStatus.failure => [box(ErrorView(failure: state.failure!, compact: true, onRetry: _comments.retry))],
      CommentsStatus.ready when state.threads.isEmpty => [box(const _NoComments())],
      CommentsStatus.ready => [
          SliverList.builder(
            itemCount: state.threads.length,
            itemBuilder: (context, i) {
              final thread = state.threads[i];
              return Material(
                key: ValueKey(thread.id),
                type: MaterialType.transparency,
                child: CommentThreadView(
                  thread: thread,
                  callbacks: commentCallbacks,
                  pendingIds: state.pendingIds,
                  highlighted: state.highlighted,
                  guest: !signedIn,
                ),
              );
            },
          ),
          if (state.hasMore) box(const _ShowMore()),
        ],
    };

    return commentListeners(
      child: BlocListener<CommentsCubit, CommentsState>(
        listenWhen: (a, b) => a.target != b.target && b.target != null,
        listener: (_, _) => _revealComposer(),
        // Its own block, a gap under the article's.
        child: SliverPadding(
          padding: const EdgeInsets.only(top: PageBlock.gap),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(color: context.colors.surface),
            sliver: SliverMainAxisGroup(
              slivers: [
                box(_Heading(key: widget.headingKey, article: widget.article)),
                box(KeyedSubtree(key: _composerKey, child: signedIn ? const CommentComposer() : const CommentGuestPrompt())),
                box(KeyedSubtree(key: _listTopKey, child: _NewComments(onTap: _comments.showIncoming))),
                ...list,
                const SliverToBoxAdapter(child: SizedBox(height: ReadInSpace.s2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "التعليقات (N)" and Top / Newest, side by side while they fit.
class _Heading extends StatelessWidget {
  const _Heading({super.key, required this.article});

  final ArticleCard article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (loaded, sort) = context.select((CommentsCubit c) => (c.state.total, c.state.sort));
    final known = context.select((EngagementCubit c) => c.state.of(article).commentCount);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(PageBlock.gutter, ReadInSpace.s4, PageBlock.gutter, ReadInSpace.s3),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: ReadInSpace.s3,
        runSpacing: ReadInSpace.s2,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.commentsTitleCount(loaded ?? known), style: context.textTheme.titleMedium),
          ),
          SegmentedButton<CommentSort>(
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: CommentSort.top, label: Text(l10n.commentsSortTop)),
              ButtonSegment(value: CommentSort.newest, label: Text(l10n.commentsSortNewest)),
            ],
            selected: {sort},
            onSelectionChanged: (v) => unawaited(context.read<CommentsCubit>().changeSort(v.first)),
          ),
        ],
      ),
    );
  }
}

/// "N new comments" at the top of the list (F27): they go in there. Nothing while there are none.
class _NewComments extends StatelessWidget {
  const _NewComments({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = context.select((CommentsCubit c) => c.state.incoming.length);
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(PageBlock.gutter, ReadInSpace.s3, PageBlock.gutter, ReadInSpace.s1),
      child: Center(
        child: Semantics(
          liveRegion: true,
          child: FilledButton.tonalIcon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            label: Text(context.l10n.commentsNewPill(count)),
          ),
        ),
      ),
    );
  }
}

/// "Show more comments", full width under the threads: a spinner while the page loads, "Try again" (with why) when
/// it failed.
class _ShowMore extends StatelessWidget {
  const _ShowMore();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (loading, failure) = context.select((CommentsCubit c) => (c.state.loadingMore, c.state.loadMoreFailure));
    final failed = failure != null && !loading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(PageBlock.gutter, ReadInSpace.s2, PageBlock.gutter, ReadInSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failed)
            Padding(
              padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
              child: Text(
                localizeFailure(l10n, failure),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ),
          OutlinedButton(
            onPressed: loading ? null : () => unawaited(context.read<CommentsCubit>().loadMore()),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: loading
                ? Semantics(
                    label: l10n.loading,
                    child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : Text(failed ? l10n.retry : l10n.commentsShowMore),
          ),
        ],
      ),
    );
  }
}

/// No comments yet, in a few lines (the composer is right above).
class _NoComments extends StatelessWidget {
  const _NoComments();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s5),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 28, color: colors.textSecondary),
          const SizedBox(height: ReadInSpace.s2),
          Text(l10n.commentsEmptyTitle, textAlign: TextAlign.center, style: context.textTheme.titleSmall),
          const SizedBox(height: ReadInSpace.s1),
          Text(
            l10n.commentsEmptyBody,
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
