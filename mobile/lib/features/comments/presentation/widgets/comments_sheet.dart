import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../../article/presentation/cubit/engagement_cubit.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../../blocks/presentation/widgets/block_actions.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../moderation/presentation/cubit/report_cubit.dart';
import '../../../moderation/presentation/widgets/report_sheet.dart';
import '../../../mutes/presentation/widgets/mute_actions.dart';
import '../../domain/entities/comment.dart';
import '../cubit/comments_cubit.dart';
import '../cubit/mention_suggestions_cubit.dart';
import 'comment_composer.dart';
import 'comment_tile.dart';

/// Opens an article's comments (F11) from the reader's action bar or a post card (F34): a tall bottom sheet (drag the
/// header down to close) with the list, the sort toggle and the composer. Live events (F27) are followed while it's
/// open. Completes with why it closed when a link inside closed it (a profile), else null.
Future<CommentsSheetExit?> showCommentsSheet(
  BuildContext context, {
  required ArticleCard article,
  CommentsCubit Function()? comments,
  MentionSuggestionsCubit Function()? mentions,
}) =>
    showModalBottomSheet<CommentsSheetExit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => (comments?.call() ?? getIt<CommentsCubit>())..load(article.id)),
          BlocProvider(create: (_) => mentions?.call() ?? getIt<MentionSuggestionsCubit>()),
        ],
        child: SizedBox(height: MediaQuery.sizeOf(sheetContext).height * 0.92, child: CommentsView(article: article)),
      ),
    );

/// The comments sheet's content once [CommentsCubit] and [MentionSuggestionsCubit] are provided ([SessionCubit] and
/// [EngagementCubit] come from the app).
class CommentsView extends StatefulWidget {
  const CommentsView({super.key, required this.article, this.reportCubit});

  final ArticleCard article;

  /// Test seam for the report sheet; the app takes the cubit from DI.
  final ReportCubit Function()? reportCubit;

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

/// What the comments sheet and the reader's comments section (F11, `ArticleCommentsSection`) share once
/// [CommentsCubit] is provided above them ([SessionCubit] and [EngagementCubit] come from the app): what each comment's
/// buttons do ([commentCallbacks]: like, reply, the menu's actions, replies paging), the follow states handed to the
/// follow store, and one comment count with the action bar ([commentListeners]).
mixin CommentActions<T extends StatefulWidget> on State<T> {
  /// The article whose comments these are.
  ArticleCard get commentsArticle;

  /// Test seam for the report sheet; the app takes the cubit from DI.
  ReportCubit Function()? get reportCubit;

  late final CommentsCubit _cubit = context.read<CommentsCubit>();
  late final CommentCallbacks _callbacks = CommentCallbacks(
    onLike: _like,
    onReply: _reply,
    onMenu: (comment, action) => unawaited(_menu(comment, action)),
    onMoreReplies: (threadId) => unawaited(_cubit.loadMoreReplies(threadId)),
    onHideReplies: _cubit.hideReplies,
  );

  /// What each comment's buttons do.
  CommentCallbacks get commentCallbacks => _callbacks;

  /// Comments whose author's follow state already went to the follow store.
  final _seeded = <String>{};

  @override
  void initState() {
    super.initState();
    _seedFollows(_cubit.state);
  }

  /// Hands the follow store what the API said about each new comment's author (`isFollowingAuthor`), so "متابعة"
  /// on every row of a writer agrees (F11, F12). Comments already handed over are skipped: their flag is as old as
  /// the page they came with, and a follow made since must stay.
  void _seedFollows(CommentsState state) {
    final follows = context.read<FollowsCubit?>();
    if (follows == null) return;
    final fresh = <String, bool>{};
    void add(Comment comment) {
      final author = comment.author;
      if (author == null || comment.isPlaceholder || !_seeded.add(comment.id)) return;
      fresh[author.id] = comment.isFollowingAuthor || (fresh[author.id] ?? false);
    }

    for (final thread in [...state.threads, for (final c in state.incoming) CommentThread.of(c)]) {
      add(thread.comment);
      thread.replies.forEach(add);
    }
    final myId = context.read<SessionCubit>().state.me?.id;
    fresh.remove(myId);
    if (fresh.isNotEmpty) follows.seed(fresh);
  }

  void _showFailure(Failure? failure) {
    if (failure == null || failure.code == FailureCodes.requestCancelled || !mounted) return;
    showActionMessage(context, localizeCommentFailure(context.l10n, failure));
  }

  Future<void> _like(Comment comment) async {
    if (!requireAccount(context)) return;
    _showFailure(await _cubit.toggleLike(comment.id));
  }

  void _reply(Comment comment) {
    if (!requireAccount(context)) return;
    _cubit.startReply(comment);
  }

  Future<void> _menu(Comment comment, CommentMenuAction action) async {
    final l10n = context.l10n;
    switch (action) {
      case CommentMenuAction.edit:
        _cubit.startEdit(comment);
      case CommentMenuAction.delete:
        if (!await _confirmDelete(l10n.commentsDeleteTitle, l10n.commentsDeleteBody)) return;
        _done(await _cubit.delete(comment.id), l10n.commentsDeleted);
      case CommentMenuAction.pin:
      case CommentMenuAction.unpin:
        _showFailure(await _cubit.setPinned(comment.id, pinned: action == CommentMenuAction.pin));
      case CommentMenuAction.mute:
        // Mute or unmute the commenter (F28), as the article menu's Mute author does; guests get the sign-in prompt.
        final author = comment.author;
        if (author == null || !requireAccount(context)) return;
        await MuteActions.toggleUser(context, userId: author.id, name: author.displayName, fallback: comment.isAuthorMuted);
      case CommentMenuAction.report:
        // The shared report sheet (F22): the sign-in prompt for guests, then "thanks" once sent.
        final author = comment.author;
        await showReportSheet(
          context,
          target: ModerationTargetRef.comment(comment.id),
          cubit: reportCubit,
          author: author == null ? null : ReportAuthor(author.id, author.username),
        );
      case CommentMenuAction.block:
        // Block the commenter (F36): their comments leave this list at once (placeholders keep their threads).
        final author = comment.author;
        if (author == null) return;
        await BlockActions.block(context, userId: author.id, username: author.username);
      case CommentMenuAction.hide:
      case CommentMenuAction.unhide:
        final hide = action == CommentMenuAction.hide;
        final failure = await _cubit.moderate(comment.id, hide ? ModerationAction.hide : ModerationAction.unhide);
        _done(failure, hide ? l10n.commentsHidden : l10n.commentsUnhidden);
      case CommentMenuAction.moderatorDelete:
        if (!await _confirmDelete(l10n.commentsModDeleteTitle, l10n.commentsModDeleteBody)) return;
        _done(await _cubit.moderate(comment.id, ModerationAction.delete), l10n.commentsDeleted);
    }
  }

  /// [message] when the action worked, else why it didn't.
  void _done(Failure? failure, String message) {
    if (failure != null) {
      _showFailure(failure);
    } else {
      _say(message);
    }
  }

  void _say(String message) {
    if (mounted) showActionMessage(context, message);
  }

  Future<bool> _confirmDelete(String title, String body) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: dialogContext.colors.error, foregroundColor: dialogContext.colors.onError),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteConfirm),
          ),
        ],
      ),
    );
    return (confirmed ?? false) && mounted;
  }

  /// [child] with the comments' listeners: the follow store gets each new comment's author, and one comment count holds
  /// for the comments and the action bar.
  Widget commentListeners({required Widget child}) {
    final article = commentsArticle;
    return MultiBlocListener(
      listeners: [
        // One comment count for the comments and the action bar: the page's total and the viewer's own changes go to
        // the engagement store; live counters come back from it (they replace, never add).
        BlocListener<CommentsCubit, CommentsState>(
          listenWhen: (a, b) => a.total != b.total && b.total != null,
          listener: (context, state) => context.read<EngagementCubit>().setCommentCount(article.id, state.total!),
        ),
        BlocListener<EngagementCubit, EngagementState>(
          listenWhen: (a, b) => a.of(article).commentCount != b.of(article).commentCount,
          listener: (context, state) => _cubit.syncTotal(state.of(article).commentCount),
        ),
        BlocListener<CommentsCubit, CommentsState>(
          listenWhen: (a, b) => a.threads != b.threads || a.incoming != b.incoming,
          listener: (_, state) => _seedFollows(state),
        ),
      ],
      child: child,
    );
  }
}

class _CommentsViewState extends State<CommentsView> with CommentActions<CommentsView> {
  final _scroll = ScrollController();

  /// Within this distance of the top, new comments in "Newest" go straight to the top instead of the pill.
  static const _nearTop = 120.0;

  @override
  ArticleCard get commentsArticle => widget.article;

  @override
  ReportCubit Function()? get reportCubit => widget.reportCubit;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scroll.position;
    _cubit.setNearTop(position.pixels <= _nearTop);
    if (position.extentAfter < 400) unawaited(_cubit.loadMore());
  }

  /// A page that leaves the list too short to scroll (the first one has 5 threads) loads the next one, without waiting
  /// for a scroll.
  bool _onMetrics(ScrollMetricsNotification notification) {
    if (notification.depth == 0 && _cubit.state.hasMore && notification.metrics.extentAfter < 400) {
      unawaited(_cubit.loadMore());
    }
    return false;
  }

  Future<void> _refresh() async => _showFailure(await _cubit.refresh());

  void _showIncoming() {
    _cubit.showIncoming();
    if (_scroll.hasClients) {
      unawaited(_scroll.animateTo(0, duration: ReadInMotion.base, curve: Curves.easeOut));
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    return commentListeners(
      child: Material(
        color: context.colors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(article: article),
            const _SortToggle(),
            Divider(height: 1, color: context.colors.border),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _refresh,
                    child: NotificationListener<ScrollMetricsNotification>(
                      onNotification: _onMetrics,
                      child: _CommentsList(controller: _scroll, callbacks: _callbacks),
                    ),
                  ),
                  _NewCommentsPill(onTap: _showIncoming),
                ],
              ),
            ),
            if (signedIn) const CommentComposer() else const CommentGuestPrompt(),
            SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
          ],
        ),
      ),
    );
  }
}

/// "التعليقات (N)" and close; dragging it down closes the sheet.
class _Header extends StatelessWidget {
  const _Header({required this.article});

  final ArticleCard article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final loaded = context.select((CommentsCubit c) => c.state.total);
    final known = context.select((EngagementCubit c) => c.state.of(article).commentCount);
    final total = loaded ?? known;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: ReadInSpace.s2),
          child: Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(ReadInRadius.chip)),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s5, ReadInSpace.s1, ReadInSpace.s2, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.commentsTitleCount(total), style: context.textTheme.titleMedium),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Top / Newest.
class _SortToggle extends StatelessWidget {
  const _SortToggle();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sort = context.select((CommentsCubit c) => c.state.sort);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s4, 0, ReadInSpace.s4, ReadInSpace.s2),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SegmentedButton<CommentSort>(
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: CommentSort.top, label: Text(l10n.commentsSortTop)),
            ButtonSegment(value: CommentSort.newest, label: Text(l10n.commentsSortNewest)),
          ],
          selected: {sort},
          onSelectionChanged: (v) => unawaited(context.read<CommentsCubit>().changeSort(v.first)),
        ),
      ),
    );
  }
}

class _CommentsList extends StatelessWidget {
  const _CommentsList({required this.controller, required this.callbacks});

  final ScrollController controller;
  final CommentCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<CommentsCubit>().state;
    final cubit = context.read<CommentsCubit>();
    final guest = context.select((SessionCubit c) => !c.state.isAuthenticated);
    final Widget sliver = switch (state.status) {
      CommentsStatus.loading => const SliverToBoxAdapter(child: CommentsSkeleton()),
      CommentsStatus.failure => SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(failure: state.failure!, onRetry: cubit.retry),
        ),
      CommentsStatus.ready when state.threads.isEmpty => SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(icon: Icons.forum_outlined, title: l10n.commentsEmptyTitle, body: l10n.commentsEmptyBody),
        ),
      CommentsStatus.ready => SliverList.builder(
          itemCount: state.threads.length + (state.hasMore || state.loadMoreFailure != null ? 1 : 0),
          itemBuilder: (context, i) {
            if (i < state.threads.length) {
              final thread = state.threads[i];
              return CommentThreadView(
                key: ValueKey(thread.id),
                thread: thread,
                callbacks: callbacks,
                pendingIds: state.pendingIds,
                highlighted: state.highlighted,
                guest: guest,
              );
            }
            return Padding(
              padding: const EdgeInsets.all(ReadInSpace.s4),
              child: Center(
                child: state.loadMoreFailure != null
                    ? ErrorView(failure: state.loadMoreFailure!, compact: true, onRetry: cubit.loadMore)
                    : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
              ),
            );
          },
        ),
    };
    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [sliver, const SliverToBoxAdapter(child: SizedBox(height: ReadInSpace.s4))],
    );
  }
}

/// "N تعليقات جديدة": new top-level comments that arrived while the reader was away from the top (or in "Top").
class _NewCommentsPill extends StatelessWidget {
  const _NewCommentsPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = context.select((CommentsCubit c) => c.state.incoming.length);
    if (count == 0) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: ReadInSpace.s3),
        child: Semantics(
          liveRegion: true,
          child: FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
            label: Text(context.l10n.commentsNewPill(count)),
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder rows (static, so "reduce motion" is respected).
class CommentsSkeleton extends StatelessWidget {
  const CommentsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(ReadInSpace.s4),
        child: Column(
          children: [
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: CommentTile.avatarSize, height: CommentTile.avatarSize, radius: CommentTile.avatarSize / 2),
                    const SizedBox(width: CommentTile.avatarGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: i.isEven ? 140 : 110),
                          const SizedBox(height: ReadInSpace.s2),
                          const SkeletonBox(),
                          const SizedBox(height: ReadInSpace.s1),
                          SkeletonBox(width: i.isEven ? 200 : 160),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}
