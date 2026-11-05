import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/author_headline.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../../follow/presentation/widgets/follow_button.dart';
import '../../../mutes/presentation/cubit/mutes_cubit.dart';
import '../../../profile/presentation/profile_routes.dart';
import '../../../profile/presentation/widgets/profile_link.dart';
import '../../domain/entities/comment.dart';
import '../cubit/comments_cubit.dart';
import 'comment_body.dart';

/// The overflow menu of a comment, from its `can*` flags. [mute] mutes or unmutes the commenter (F28).
enum CommentMenuAction { edit, delete, pin, unpin, mute, report, hide, unhide, moderatorDelete }

/// What a comment's buttons do. The comments sheet wires them to [CommentsCubit]; goldens pass no-ops.
class CommentCallbacks {
  const CommentCallbacks({required this.onLike, required this.onReply, required this.onMenu, required this.onMoreReplies});

  final ValueChanged<Comment> onLike;
  final ValueChanged<Comment> onReply;
  final void Function(Comment comment, CommentMenuAction action) onMenu;
  final ValueChanged<String> onMoreReplies;
}

/// The menu entries [comment] offers the viewer (own: edit/delete; the article's author: pin; readers: mute the
/// commenter, then report; moderators: hide/unhide/delete). A [guest] may mute and report too, as on the web: they get
/// the sign-in prompt first (the server's `canReport` is false for guests, and for your own comments). Mute needs an
/// author (not a deleted account) and a comment that isn't a placeholder.
List<CommentMenuAction> commentMenuActions(Comment comment, {bool guest = false}) => [
      if (comment.canEdit) CommentMenuAction.edit,
      if (comment.canDelete) CommentMenuAction.delete,
      if (comment.canPin && !comment.isReply) comment.isPinned ? CommentMenuAction.unpin : CommentMenuAction.pin,
      if ((comment.canReport || guest) && comment.author != null && !comment.isPlaceholder) CommentMenuAction.mute,
      if (comment.canReport || guest) CommentMenuAction.report,
      if (comment.canModerate) comment.isHidden ? CommentMenuAction.unhide : CommentMenuAction.hide,
      if (comment.canModerate && !comment.canDelete) CommentMenuAction.moderatorDelete,
    ];

/// A top-level comment and its replies: one indented level with a connector line (SPEC F11), then "show N more
/// replies".
class CommentThreadView extends StatelessWidget {
  const CommentThreadView({
    super.key,
    required this.thread,
    required this.callbacks,
    this.pendingIds = const {},
    this.highlighted = const {},
    this.guest = false,
  });

  final CommentThread thread;
  final CommentCallbacks callbacks;
  final Set<String> pendingIds;
  final Set<String> highlighted;

  /// The viewer isn't signed in ([commentMenuActions]).
  final bool guest;

  /// Where the connector line runs: under the center of the top-level avatar.
  static const _lineStart = ReadInSpace.s4 + CommentTile.avatarSize / 2 - 1;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showReplies = thread.replies.isNotEmpty || thread.hasMoreReplies;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommentTile(
          comment: thread.comment,
          callbacks: callbacks,
          pending: pendingIds.contains(thread.id),
          highlighted: highlighted.contains(thread.id),
          guest: guest,
        ),
        if (showReplies)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: _lineStart, bottom: ReadInSpace.s2),
            child: DecoratedBox(
              decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: colors.border, width: 2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final reply in thread.replies)
                    CommentTile(
                      comment: reply,
                      callbacks: callbacks,
                      isReply: true,
                      pending: pendingIds.contains(reply.id),
                      highlighted: highlighted.contains(reply.id),
                      guest: guest,
                    ),
                  if (thread.hasMoreReplies || thread.repliesFailure != null) _MoreReplies(thread: thread, onTap: callbacks.onMoreReplies),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MoreReplies extends StatelessWidget {
  const _MoreReplies({required this.thread, required this.onTap});

  final CommentThread thread;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final failed = thread.repliesFailure != null;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s2),
        child: thread.loadingReplies
            ? const Padding(
                padding: EdgeInsets.all(ReadInSpace.s3),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : TextButton.icon(
                onPressed: () => onTap(thread.id),
                icon: Icon(failed ? Icons.refresh_rounded : Icons.expand_more_rounded, size: 18),
                label: Text(
                  failed
                      ? l10n.retry
                      : thread.moreReplies > 0
                          ? l10n.commentsMoreReplies(thread.moreReplies)
                          : l10n.commentsMoreRepliesAny,
                ),
                style: TextButton.styleFrom(foregroundColor: failed ? colors.error : colors.primary, minimumSize: const Size(44, 40)),
              ),
      ),
    );
  }
}

/// One comment (F11): the avatar, the name with ✓ and "الكاتب", the writer's title under it (one line with "…", in place
/// of the `@username`), "متابعة" while you don't follow them and it isn't you, and "⋯"; then the text in its own
/// direction, and one row with like, reply and the time ("edited"). The avatar and name open the profile.
/// Placeholders (deleted, or hidden from this viewer) show one line instead.
class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.callbacks,
    this.isReply = false,
    this.pending = false,
    this.highlighted = false,
    this.guest = false,
  });

  final Comment comment;
  final CommentCallbacks callbacks;
  final bool isReply;

  /// Not on the server yet: dimmed, "Sending…", no actions.
  final bool pending;

  /// Just arrived live (F27).
  final bool highlighted;

  /// The viewer isn't signed in: the menu still offers Report ([commentMenuActions]).
  final bool guest;

  static const avatarSize = 36.0;
  static const replyAvatarSize = 28.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = isReply ? replyAvatarSize : avatarSize;
    final padding = isReply
        ? const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s3, ReadInSpace.s2, ReadInSpace.s4, 0)
        : const EdgeInsetsDirectional.fromSTEB(ReadInSpace.s4, ReadInSpace.s3, ReadInSpace.s2, 0);
    final authorId = comment.author?.id;
    // A muted writer's comment collapses until the viewer shows it (F28); [MutesCubit] knows of mutes made since.
    final muted = context.select(
      (MutesCubit? c) =>
          !comment.isPlaceholder &&
          authorId != null &&
          (c?.state.isUserMuted(authorId, fallback: comment.isAuthorMuted) ?? comment.isAuthorMuted),
    );
    final Widget content = comment.isPlaceholder
        ? _Placeholder(comment: comment, avatarSize: size)
        : _MutedCollapse(
            key: ValueKey('muted-${comment.id}'),
            muted: muted,
            avatarSize: size,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(comment: comment, size: size),
                const SizedBox(width: ReadInSpace.s3),
                Expanded(child: _Content(comment: comment, callbacks: callbacks, pending: pending, guest: guest)),
              ],
            ),
          );
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : ReadInMotion.slow,
      color: highlighted ? colors.primaryContainer : colors.primaryContainer.withValues(alpha: 0),
      padding: padding,
      child: Opacity(opacity: pending ? 0.6 : 1, child: content),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.comment, required this.size});

  final Comment comment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final author = comment.author;
    if (author == null) return GenericAvatar(size: size);
    return ProfileLink(
      username: author.username,
      beforeOpen: () => _closeSheet(context),
      child: UserAvatar(name: author.displayName, url: author.avatarUrl, size: size),
    );
  }
}

/// Why the comments sheet closed, when it wasn't the viewer closing it.
enum CommentsSheetExit {
  /// A profile opened from the comments: a post card opens them again once the viewer is back (F34).
  openedProfile,
}

/// Comments open in a bottom sheet: close it first so the profile isn't pushed underneath, as "who reacted" does.
void _closeSheet(BuildContext context) {
  if (ModalRoute.of(context) is ModalBottomSheetRoute) {
    unawaited(Navigator.of(context).maybePop(CommentsSheetExit.openedProfile));
  }
}

void _openProfile(BuildContext context, String username) {
  // Taken before closing the sheet, which takes this context out of the tree.
  final router = GoRouter.maybeOf(context);
  _closeSheet(context);
  if (router != null) unawaited(router.push<void>(ProfileRoutes.of(username)));
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.comment, required this.avatarSize});

  final Comment comment;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: ReadInSpace.s3),
      child: Row(
        children: [
          GenericAvatar(size: avatarSize),
          const SizedBox(width: ReadInSpace.s3),
          Icon(comment.isDeleted ? Icons.delete_outline_rounded : Icons.visibility_off_outlined, size: 16, color: colors.textSecondary),
          const SizedBox(width: ReadInSpace.s1),
          Expanded(
            child: Text(
              comment.isDeleted ? l10n.commentsDeletedPlaceholder : l10n.commentsHiddenPlaceholder,
              style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

/// A comment by a writer the viewer muted (F28): "تعليق من شخص كتمته" with "عرض", which shows it here only (the
/// body is already loaded). Counts and replies don't change. Shows [child] as usual once it isn't muted.
class _MutedCollapse extends StatefulWidget {
  const _MutedCollapse({super.key, required this.muted, required this.avatarSize, required this.child});

  final bool muted;
  final double avatarSize;
  final Widget child;

  @override
  State<_MutedCollapse> createState() => _MutedCollapseState();
}

class _MutedCollapseState extends State<_MutedCollapse> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.muted || _shown) return widget.child;
    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
      child: Row(
        children: [
          GenericAvatar(size: widget.avatarSize),
          const SizedBox(width: ReadInSpace.s3),
          Icon(Icons.volume_off_outlined, size: 16, color: colors.textSecondary),
          const SizedBox(width: ReadInSpace.s1),
          Expanded(
            child: Text(
              l10n.muteCommentCollapsed,
              style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ),
          TextButton(
            key: const ValueKey('muted-comment-show'),
            onPressed: () => setState(() => _shown = true),
            style: TextButton.styleFrom(minimumSize: const Size(48, 40), padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2)),
            child: Text(l10n.muteCommentShow),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.comment, required this.callbacks, required this.pending, required this.guest});

  final Comment comment;
  final CommentCallbacks callbacks;
  final bool pending;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final author = comment.author;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comment.isPinned) ...[
          Row(
            children: [
              Icon(Icons.push_pin_rounded, size: 14, color: colors.primary),
              const SizedBox(width: ReadInSpace.s1),
              Text(l10n.commentsPinned, style: context.textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 2),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: author == null
                            ? Text(
                                l10n.commentsDeletedUser,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.titleSmall?.copyWith(color: colors.textSecondary),
                              )
                            : ProfileLink(
                                username: author.username,
                                beforeOpen: () => _closeSheet(context),
                                child: BidiText(
                                  author.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.titleSmall,
                                ),
                              ),
                      ),
                      if (author?.isVerified ?? false) ...[const SizedBox(width: 4), const VerifiedMark()],
                      if (comment.isArticleAuthor) ...[
                        const SizedBox(width: ReadInSpace.s2),
                        InfoTag(label: l10n.commentsAuthorBadge, tone: InfoTagTone.primary),
                      ],
                    ],
                  ),
                  if (author?.headline case final headline?)
                    AuthorHeadline(headline, style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
                ],
              ),
            ),
            if (author != null && !pending) _CommentFollow(author: author, initiallyFollowing: comment.isFollowingAuthor),
            _Menu(comment: comment, callbacks: callbacks, enabled: !pending, guest: guest),
          ],
        ),
        if (comment.isHidden) ...[
          const SizedBox(height: ReadInSpace.s2),
          _HiddenNotice(text: l10n.commentsHiddenNotice),
        ],
        const SizedBox(height: ReadInSpace.s1),
        CommentBody(
          body: comment.body!,
          mentions: comment.mentions,
          onMention: pending ? null : (mention) => _openProfile(context, mention.username),
        ),
        _Actions(comment: comment, callbacks: callbacks, enabled: !pending),
      ],
    );
  }
}

/// "متابعة" on a comment by someone you don't follow (F11, F12), never on your own. Whether it shows is decided when
/// the row first appears, from the follow store (seeded with `isFollowingAuthor`): following from it then reads
/// "✓ Following" here and on every other row, card and profile of that writer. Guests get the sign-in prompt.
class _CommentFollow extends StatefulWidget {
  const _CommentFollow({required this.author, required this.initiallyFollowing});

  final Author author;
  final bool initiallyFollowing;

  @override
  State<_CommentFollow> createState() => _CommentFollowState();
}

class _CommentFollowState extends State<_CommentFollow> {
  bool? _shown;

  @override
  Widget build(BuildContext context) {
    final myId = context.select((SessionCubit? c) => c?.state.me?.id);
    final following = context.select(
      (FollowsCubit? c) => c?.state.isFollowing(widget.author.id, fallback: widget.initiallyFollowing),
    );
    // No follow store above (a screen shown on its own): no button.
    if (following == null || widget.author.id == myId) return const SizedBox.shrink();
    _shown ??= !following;
    if (!_shown!) return const SizedBox.shrink();
    return FollowButton(
      userId: widget.author.id,
      name: widget.author.displayName,
      initiallyFollowing: widget.initiallyFollowing,
      text: true,
      dense: true,
      followLabel: context.l10n.commentRowFollow,
    );
  }
}

/// "⋯": the comment's menu, when the viewer has anything in it.
class _Menu extends StatelessWidget {
  const _Menu({required this.comment, required this.callbacks, required this.enabled, required this.guest});

  final Comment comment;
  final CommentCallbacks callbacks;
  final bool enabled;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final menu = enabled ? commentMenuActions(comment, guest: guest) : const <CommentMenuAction>[];
    if (menu.isEmpty) return const SizedBox(width: ReadInSpace.s1);
    final authorId = comment.author?.id;
    // A commenter the viewer muted: the item reads "Unmute commenter" (F28).
    final authorMuted = !guest &&
        context.select(
          (MutesCubit? c) =>
              authorId != null && (c?.state.isUserMuted(authorId, fallback: comment.isAuthorMuted) ?? comment.isAuthorMuted),
        );
    return SizedBox(
      width: 40,
      height: 40,
      child: PopupMenuButton<CommentMenuAction>(
        tooltip: l10n.commentsMenu,
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary, size: 20),
        onSelected: (action) => callbacks.onMenu(comment, action),
        itemBuilder: (context) => [
          for (final action in menu) PopupMenuItem(value: action, child: _MenuLabel(action: action, authorMuted: authorMuted)),
        ],
      ),
    );
  }
}

class _HiddenNotice extends StatelessWidget {
  const _HiddenNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: ReadInSpace.s1),
      decoration: BoxDecoration(color: colors.calloutWarning, borderRadius: BorderRadius.circular(ReadInRadius.sm)),
      child: Row(
        children: [
          Icon(Icons.visibility_off_outlined, size: 14, color: colors.calloutWarningAccent),
          const SizedBox(width: ReadInSpace.s1),
          Expanded(child: Text(text, style: context.textTheme.labelSmall?.copyWith(color: colors.textPrimary))),
        ],
      ),
    );
  }
}

/// Like and Reply, then the time ("Sending…" while pending) and "edited", in one row.
class _Actions extends StatelessWidget {
  const _Actions({required this.comment, required this.callbacks, required this.enabled});

  final Comment comment;
  final CommentCallbacks callbacks;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final label = context.textTheme.labelMedium?.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600);
    final time = enabled
        ? commentTimeLabel(l10n, comment.createdAt, now: CommentClock.now(), languageCode: Localizations.localeOf(context).languageCode)
        : l10n.commentsSending;
    final meta = [time, if (comment.editedAt != null && enabled) l10n.commentsEdited].join(' · ');
    return Row(
      children: [
        CommentLikeButton(
          liked: comment.likedByMe,
          count: comment.likeCount,
          onPressed: enabled ? () => callbacks.onLike(comment) : null,
        ),
        Semantics(
          button: true,
          label: l10n.commentsReply,
          excludeSemantics: true,
          child: InkWell(
            onTap: enabled ? () => callbacks.onReply(comment) : null,
            borderRadius: BorderRadius.circular(ReadInRadius.chip),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
                child: Center(widthFactor: 1, child: Text(l10n.commentsReply, style: label)),
              ),
            ),
          ),
        ),
        const SizedBox(width: ReadInSpace.s2),
        Flexible(
          child: Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.action, this.authorMuted = false});

  final CommentMenuAction action;

  /// The viewer muted the commenter: "Unmute commenter".
  final bool authorMuted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (icon, text) = switch (action) {
      CommentMenuAction.edit => (Icons.edit_outlined, l10n.edit),
      CommentMenuAction.delete => (Icons.delete_outline_rounded, l10n.deleteAction),
      CommentMenuAction.pin => (Icons.push_pin_outlined, l10n.commentsPin),
      CommentMenuAction.unpin => (Icons.push_pin_rounded, l10n.commentsUnpin),
      CommentMenuAction.mute => authorMuted
          ? (Icons.volume_up_outlined, l10n.muteMenuUnmuteCommenter)
          : (Icons.volume_off_outlined, l10n.muteMenuCommenter),
      CommentMenuAction.report => (Icons.flag_outlined, l10n.commentsReport),
      CommentMenuAction.hide => (Icons.visibility_off_outlined, l10n.commentsModHide),
      CommentMenuAction.unhide => (Icons.visibility_outlined, l10n.commentsModUnhide),
      CommentMenuAction.moderatorDelete => (Icons.delete_forever_outlined, l10n.commentsModDelete),
    };
    final destructive = action == CommentMenuAction.delete || action == CommentMenuAction.moderatorDelete;
    final color = destructive ? colors.error : colors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: ReadInSpace.s3),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}

/// ♡ n: filled in the primary color when the viewer liked it. The count is hidden at 0.
class CommentLikeButton extends StatelessWidget {
  const CommentLikeButton({super.key, required this.liked, required this.count, this.onPressed});

  final bool liked;
  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final color = liked ? colors.primary : colors.textSecondary;
    return Semantics(
      button: true,
      toggled: liked,
      label: liked ? l10n.commentsUnlike : l10n.commentsLike,
      value: l10n.commentsLikesCount(count),
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(ReadInRadius.chip),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 18, color: color),
                if (count > 0) ...[
                  const SizedBox(width: ReadInSpace.s1),
                  Text('$count', style: context.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
