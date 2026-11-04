import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../profile/presentation/profile_routes.dart';
import '../../../profile/presentation/widgets/profile_link.dart';
import '../../domain/entities/comment.dart';
import '../cubit/comments_cubit.dart';
import 'comment_body.dart';

/// The overflow menu of a comment, from its `can*` flags.
enum CommentMenuAction { edit, delete, pin, unpin, report, hide, unhide, moderatorDelete }

/// What a comment's buttons do. The comments sheet wires them to [CommentsCubit]; goldens pass no-ops.
class CommentCallbacks {
  const CommentCallbacks({required this.onLike, required this.onReply, required this.onMenu, required this.onMoreReplies});

  final ValueChanged<Comment> onLike;
  final ValueChanged<Comment> onReply;
  final void Function(Comment comment, CommentMenuAction action) onMenu;
  final ValueChanged<String> onMoreReplies;
}

/// The menu entries [comment] offers the viewer (own: edit/delete; the article's author: pin; readers: report;
/// moderators: hide/unhide/delete). A [guest] may report too, as on the web: the report sheet asks them to sign in
/// first (the server's `canReport` is false for guests).
List<CommentMenuAction> commentMenuActions(Comment comment, {bool guest = false}) => [
      if (comment.canEdit) CommentMenuAction.edit,
      if (comment.canDelete) CommentMenuAction.delete,
      if (comment.canPin && !comment.isReply) comment.isPinned ? CommentMenuAction.unpin : CommentMenuAction.pin,
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

/// One comment: avatar, name, `@username`, ✓, "الكاتب", pinned, relative time, "edited", the text in its own
/// direction, then like, reply and the overflow menu. Placeholders (deleted, or hidden from this viewer) show one
/// line instead.
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
    final Widget content = comment.isPlaceholder
        ? _Placeholder(comment: comment, avatarSize: size)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(comment: comment, size: size),
              const SizedBox(width: ReadInSpace.s3),
              Expanded(child: _Content(comment: comment, callbacks: callbacks, pending: pending, guest: guest)),
            ],
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

/// Comments open in a bottom sheet: close it first so the profile isn't pushed underneath, as "who reacted" does.
void _closeSheet(BuildContext context) {
  if (ModalRoute.of(context) is ModalBottomSheetRoute) unawaited(Navigator.of(context).maybePop());
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
    final meta = context.textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final time = pending
        ? l10n.commentsSending
        : commentTimeLabel(l10n, comment.createdAt, now: CommentClock.now(), languageCode: Localizations.localeOf(context).languageCode);
    final metaParts = [
      if (author != null) Bidi.ltrIsolate('@${author.username}'),
      time,
      if (comment.editedAt != null && !pending) l10n.commentsEdited,
    ];
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
                      child: BidiText(author.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall),
                    ),
            ),
            if (author?.isVerified ?? false) ...[const SizedBox(width: 4), const VerifiedMark()],
            if (comment.isArticleAuthor) ...[
              const SizedBox(width: ReadInSpace.s2),
              InfoTag(label: l10n.commentsAuthorBadge, tone: InfoTagTone.primary),
            ],
          ],
        ),
        Text(metaParts.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: meta),
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
        _Actions(comment: comment, callbacks: callbacks, enabled: !pending, guest: guest),
      ],
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

class _Actions extends StatelessWidget {
  const _Actions({required this.comment, required this.callbacks, required this.enabled, required this.guest});

  final Comment comment;
  final CommentCallbacks callbacks;
  final bool enabled;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final menu = enabled ? commentMenuActions(comment, guest: guest) : const <CommentMenuAction>[];
    final label = context.textTheme.labelMedium?.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600);
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
        const Spacer(),
        if (menu.isNotEmpty)
          PopupMenuButton<CommentMenuAction>(
            tooltip: l10n.commentsMenu,
            icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary, size: 20),
            onSelected: (action) => callbacks.onMenu(comment, action),
            itemBuilder: (context) => [
              for (final action in menu) PopupMenuItem(value: action, child: _MenuLabel(action: action)),
            ],
          ),
      ],
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.action});

  final CommentMenuAction action;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (icon, text) = switch (action) {
      CommentMenuAction.edit => (Icons.edit_outlined, l10n.edit),
      CommentMenuAction.delete => (Icons.delete_outline_rounded, l10n.deleteAction),
      CommentMenuAction.pin => (Icons.push_pin_outlined, l10n.commentsPin),
      CommentMenuAction.unpin => (Icons.push_pin_rounded, l10n.commentsUnpin),
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
