import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/author_headline.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../blocks/presentation/cubit/blocks_cubit.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../../follow/presentation/widgets/follow_button.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../moderation/presentation/cubit/reported_content_cubit.dart';
import '../../../mutes/presentation/cubit/mutes_cubit.dart';
import '../../../profile/presentation/profile_routes.dart';
import '../../../profile/presentation/widgets/profile_link.dart';
import '../../domain/entities/comment.dart';
import '../cubit/comments_cubit.dart';
import 'comment_body.dart';

/// The overflow menu of a comment, from its `can*` flags. [mute] mutes or unmutes the commenter (F28).
enum CommentMenuAction { edit, delete, pin, unpin, mute, block, report, hide, unhide, moderatorDelete }

/// What a comment's buttons do. The comments sheet wires them to [CommentsCubit]; goldens pass no-ops.
class CommentCallbacks {
  const CommentCallbacks({
    required this.onLike,
    required this.onReply,
    required this.onMenu,
    required this.onMoreReplies,
    this.onHideReplies,
  });

  final ValueChanged<Comment> onLike;
  final ValueChanged<Comment> onReply;
  final void Function(Comment comment, CommentMenuAction action) onMenu;

  /// "Show N more replies", and its retry, for a thread (by id).
  final ValueChanged<String> onMoreReplies;

  /// "Hide replies" for a thread (by id).
  final ValueChanged<String>? onHideReplies;
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
      // Block the commenter (F36), under Mute.
      if ((comment.canReport || guest) && comment.author != null && !comment.isPlaceholder) CommentMenuAction.block,
      if (comment.canReport || guest) CommentMenuAction.report,
      if (comment.canModerate) comment.isHidden ? CommentMenuAction.unhide : CommentMenuAction.hide,
      if (comment.canModerate && !comment.canDelete) CommentMenuAction.moderatorDelete,
    ];

/// A top-level comment and its replies (SPEC F11), Facebook and LinkedIn style: the replies indented by the top-level
/// avatar and its gap, only those [CommentThread.visibleReplies] says; then "↳ show N more replies" and, once more than
/// one reply shows, "Hide replies".
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      // With each comment's own 6 px: 8 px more between threads.
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CommentTile(
            comment: thread.comment,
            callbacks: callbacks,
            pending: pendingIds.contains(thread.id),
            highlighted: highlighted.contains(thread.id),
            guest: guest,
          ),
          for (final reply in thread.visibleReplies)
            CommentTile(
              key: ValueKey('reply-${reply.id}'),
              comment: reply,
              callbacks: callbacks,
              isReply: true,
              pending: pendingIds.contains(reply.id),
              highlighted: highlighted.contains(reply.id),
              guest: guest,
            ),
          _RepliesPager(thread: thread, callbacks: callbacks),
        ],
      ),
    );
  }
}

/// "↳ show N more replies" (or its spinner, or "Couldn't load the replies." with retry) and "Hide replies", under a
/// thread's replies. Nothing when neither applies.
class _RepliesPager extends StatelessWidget {
  const _RepliesPager({required this.thread, required this.callbacks});

  final CommentThread thread;
  final CommentCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final children = <Widget>[];
    if (thread.loadingReplies) {
      children.add(const SizedBox(
        height: 32,
        child: Center(
          widthFactor: 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ));
    } else if (thread.repliesFailure != null) {
      children
        ..add(Padding(
          padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s2 - 2),
          child: Text(
            l10n.commentsRepliesFailed,
            style: context.textTheme.labelMedium?.copyWith(color: colors.error),
          ),
        ))
        ..add(_PagerButton(
          key: const ValueKey('replies-retry'),
          icon: Icons.refresh_rounded,
          label: l10n.retry,
          color: colors.primary,
          onPressed: () => callbacks.onMoreReplies(thread.id),
        ));
    } else if (thread.hasMoreReplies) {
      final more = thread.moreReplies;
      children.add(_PagerButton(
        key: const ValueKey('replies-more'),
        icon: context.isRtl ? Icons.subdirectory_arrow_left_rounded : Icons.subdirectory_arrow_right_rounded,
        label: more > 0 ? l10n.commentsMoreReplies(more) : l10n.commentsMoreRepliesAny,
        color: colors.primary,
        onPressed: () => callbacks.onMoreReplies(thread.id),
      ));
    }
    if (thread.canHideReplies && !thread.loadingReplies) {
      children.add(_PagerButton(
        key: const ValueKey('replies-hide'),
        label: l10n.commentsHideReplies,
        color: colors.textSecondary,
        onPressed: () => callbacks.onHideReplies?.call(thread.id),
      ));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      // The arrow lines up with the replies' avatars.
      padding: const EdgeInsetsDirectional.fromSTEB(CommentTile.replyStart - 6, 0, ReadInSpace.s4, ReadInSpace.s1),
      child: Wrap(spacing: ReadInSpace.s1, crossAxisAlignment: WrapCrossAlignment.center, children: children),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({super.key, this.icon, required this.label, required this.color, required this.onPressed});

  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: ReadInSpace.s1)],
            Flexible(child: Text(label)),
          ],
        ),
      );
}

/// One comment (F11), LinkedIn style: the avatar, then a bubble with the name, ✓, "الكاتب", "Pinned" and "· متابعة"
/// while you don't follow them (never on your own), the time ("edited") at the end and "⋯" in its corner; the writer's
/// title under the name (one line with "…", nothing when they have none); then the text in its own direction. Under the
/// bubble: "Like" (with ♥ n once liked) · "Reply", or "Sending…". The avatar and name open the profile. A comment that
/// just arrived live lights up its bubble. Placeholders (deleted, or hidden from this viewer) and muted writers' comments
/// show one italic line in a bubble instead.
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

  static const avatarSize = 32.0;
  static const replyAvatarSize = 24.0;

  /// Between the avatar and the bubble.
  static const avatarGap = ReadInSpace.s2;

  /// Where a reply starts: under the top-level comment's bubble.
  static const replyStart = ReadInSpace.s4 + avatarSize + avatarGap;

  @override
  Widget build(BuildContext context) {
    final size = isReply ? replyAvatarSize : avatarSize;
    final authorId = comment.author?.id;
    // A muted writer's comment collapses until the viewer shows it (F28); [MutesCubit] knows of mutes made since.
    final muted = context.select(
      (MutesCubit? c) =>
          !comment.isPlaceholder &&
          authorId != null &&
          (c?.state.isUserMuted(authorId, fallback: comment.isAuthorMuted) ?? comment.isAuthorMuted),
    );
    // F36: by someone the viewer blocked in this session (a server placeholder, `isUnavailable`, reads the same).
    final blocked = authorId != null && context.select((BlocksCubit? c) => c?.state.isBlocked(authorId) ?? false);
    // F22 store additions: reported by the viewer, now or before (`reportedByMe`): collapsed, with "Show".
    final reported = !comment.isPlaceholder &&
        context.select(
          (ReportedContentCubit? c) =>
              c?.isReported(ModerationTargetType.comment, comment.id, fallback: comment.reportedByMe) ?? comment.reportedByMe,
        );
    final Widget content = comment.isPlaceholder || blocked
        ? _Placeholder(comment: comment, avatarSize: size, unavailable: blocked || comment.isUnavailable)
        : _MutedCollapse(
            key: ValueKey('muted-${comment.id}'),
            muted: muted || reported,
            reported: reported,
            avatarSize: size,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(comment: comment, size: size),
                const SizedBox(width: avatarGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CommentBubble(comment: comment, callbacks: callbacks, pending: pending, highlighted: highlighted, guest: guest),
                      _Actions(comment: comment, callbacks: callbacks, pending: pending),
                    ],
                  ),
                ),
              ],
            ),
          );
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(isReply ? replyStart : ReadInSpace.s4, 6, ReadInSpace.s4, 6),
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

/// The comment's background: the surface variant, round with a sharper corner by the avatar; the highlight color for a
/// comment that just arrived. [corner] sits in its top-end corner.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.child, this.highlighted = false, this.corner});

  final Widget child;
  final bool highlighted;
  final Widget? corner;

  static const radius = BorderRadiusDirectional.only(
    topStart: Radius.circular(ReadInSpace.s1),
    topEnd: Radius.circular(ReadInRadius.md),
    bottomStart: Radius.circular(ReadInRadius.md),
    bottomEnd: Radius.circular(ReadInRadius.md),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bubble = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : ReadInMotion.slow,
      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s2),
      decoration: BoxDecoration(color: highlighted ? colors.highlight : colors.surfaceVariant, borderRadius: radius),
      child: child,
    );
    if (corner == null) return bubble;
    // Centered on the name line (the bubble's 8 px padding, then 24 px).
    return Stack(
      fit: StackFit.passthrough,
      children: [bubble, PositionedDirectional(top: ReadInSpace.s1, end: 0, child: corner!)],
    );
  }
}

/// A small round icon where the avatar goes, for comments that show one line instead.
class _IconAvatar extends StatelessWidget {
  const _IconAvatar({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceVariant,
        border: context.isDark ? Border.all(color: colors.border) : null,
      ),
      child: Icon(icon, size: size * 0.55, color: colors.textSecondary),
    );
  }
}

/// The one italic line of a placeholder or a muted writer's comment.
TextStyle? _placeholderStyle(BuildContext context) =>
    context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary, fontStyle: FontStyle.italic);

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.comment, required this.avatarSize, this.unavailable = false});

  final Comment comment;
  final double avatarSize;

  /// Someone the viewer is blocked with (F36): «هذا التعليق غير متاح».
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, text) = unavailable
        ? (Icons.block_rounded, l10n.blockCommentUnavailable)
        : comment.isDeleted
            ? (Icons.delete_outline_rounded, l10n.commentsDeletedPlaceholder)
            : (Icons.visibility_off_outlined, l10n.commentsHiddenPlaceholder);
    return Row(
      children: [
        _IconAvatar(icon: icon, size: avatarSize),
        const SizedBox(width: CommentTile.avatarGap),
        Expanded(child: _Bubble(child: Text(text, style: _placeholderStyle(context)))),
      ],
    );
  }
}

/// A comment by a writer the viewer muted (F28): "تعليق من شخص كتمته" with "عرض", which shows it here only (the
/// body is already loaded). Counts and replies don't change. Shows [child] as usual once it isn't muted. A comment
/// the viewer reported ([reported], F22 store additions) collapses the same way: «أبلغت عن هذا المحتوى، ولن يظهر لك
/// بعد الآن».
class _MutedCollapse extends StatefulWidget {
  const _MutedCollapse({super.key, required this.muted, required this.avatarSize, required this.child, this.reported = false});

  final bool muted;
  final bool reported;
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
    return Row(
      children: [
        _IconAvatar(icon: widget.reported ? Icons.flag_outlined : Icons.volume_off_outlined, size: widget.avatarSize),
        const SizedBox(width: CommentTile.avatarGap),
        Expanded(
          child: _Bubble(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.reported ? l10n.reportedHidden : l10n.muteCommentCollapsed,
                    style: _placeholderStyle(context),
                  ),
                ),
                const SizedBox(width: ReadInSpace.s1),
                TextButton(
                  key: ValueKey(widget.reported ? 'reported-comment-show' : 'muted-comment-show'),
                  onPressed: () => setState(() => _shown = true),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    textStyle: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  child: Text(l10n.muteCommentShow),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The bubble of a comment with text: its name line, the writer's title, the moderators' notice, then the text.
class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.callbacks,
    required this.pending,
    required this.highlighted,
    required this.guest,
  });

  final Comment comment;
  final CommentCallbacks callbacks;
  final bool pending;
  final bool highlighted;
  final bool guest;

  /// The width "⋯" takes from the name line (it overlaps the bubble's padding).
  static const _menuReserve = _Menu.size - ReadInSpace.s3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final author = comment.author;
    final hasMenu = !pending && commentMenuActions(comment, guest: guest).isNotEmpty;
    return _Bubble(
      highlighted: highlighted,
      corner: hasMenu ? _Menu(comment: comment, callbacks: callbacks, guest: guest) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(end: hasMenu ? _menuReserve : 0),
            child: _NameLine(comment: comment, pending: pending),
          ),
          if (author?.headline case final headline?)
            AuthorHeadline(
              headline,
              style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w400),
            ),
          if (comment.isHidden) ...[
            const SizedBox(height: ReadInSpace.s1),
            _HiddenNotice(text: l10n.commentsHiddenNotice),
          ],
          const SizedBox(height: ReadInSpace.s1),
          CommentBody(
            body: comment.body!,
            mentions: comment.mentions,
            style: context.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.6, color: colors.textPrimary),
            onMention: pending ? null : (mention) => _openProfile(context, mention.username),
          ),
        ],
      ),
    );
  }
}

/// The bubble's first line: the name (it opens the profile), ✓, "الكاتب", "Pinned" and "· متابعة" at the start; the time
/// and "edited" at the end. When the line is short of room the name is cut with "…", the time takes at most about half,
/// and the tags move to a second line; "· متابعة" moves with the item before it, so a line never starts with its dot.
class _NameLine extends StatelessWidget {
  const _NameLine({required this.comment, required this.pending});

  final Comment comment;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final author = comment.author;
    final nameStyle = context.textTheme.titleSmall?.copyWith(fontSize: 14, height: 1.4);
    final time = commentTimeLabel(l10n, comment.createdAt, now: CommentClock.now(), languageCode: Localizations.localeOf(context).languageCode);
    final meta = [time, if (comment.editedAt != null && !pending) l10n.commentsEdited].join(' · ');
    final name = author == null
        ? Text(l10n.commentsDeletedUser, maxLines: 1, overflow: TextOverflow.ellipsis, style: nameStyle?.copyWith(color: colors.textSecondary))
        : ProfileLink(
            username: author.username,
            beforeOpen: () => _closeSheet(context),
            child: BidiText(author.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: nameStyle),
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: name),
              if (author?.isVerified ?? false) ...[const SizedBox(width: 4), const VerifiedMark()],
            ],
          ),
          if (comment.isArticleAuthor)
            FittedBox(fit: BoxFit.scaleDown, child: InfoTag(label: l10n.commentsAuthorBadge, tone: InfoTagTone.primary)),
          if (comment.isPinned) const _PinnedLabel(),
        ];
        // "· متابعة" is part of the item before it, so its dot never starts a line when the tags wrap.
        if (author != null && !pending) {
          items.last = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: items.last),
              _CommentFollow(
                author: author,
                initiallyFollowing: comment.isFollowingAuthor,
                // What is left of the line once the time took its most, less the dot and room for the name and ✓.
                maxWidth: math.max(0.0, constraints.maxWidth * 0.55 - 40),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(spacing: 6, runSpacing: 2, children: [for (final item in items) _lineItem(item)]),
            ),
            const SizedBox(width: ReadInSpace.s2),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
              child: _lineItem(Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w400),
              )),
            ),
          ],
        );
      },
    );
  }

  /// One item of the line, centered on its 24 px height, so items line up when the tags move to a second line.
  static Widget _lineItem(Widget child) =>
      ConstrainedBox(constraints: const BoxConstraints(minHeight: _height), child: Center(widthFactor: 1, child: child));

  static const _height = 24.0;
}

class _PinnedLabel extends StatelessWidget {
  const _PinnedLabel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.push_pin_rounded, size: 12, color: colors.primary),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            context.l10n.commentsPinned,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// "· متابعة" after the name (and tags) of someone you don't follow (F11, F12), never on your own. Whether it shows is
/// decided when the row first appears, from the follow store (seeded with `isFollowingAuthor`): following from it then
/// reads "Following" here and on every other row, card and profile of that writer. Guests get the sign-in prompt.
class _CommentFollow extends StatefulWidget {
  const _CommentFollow({required this.author, required this.initiallyFollowing, required this.maxWidth});

  final Author author;
  final bool initiallyFollowing;

  /// The button's widest (its word wraps beyond it), so the name before it always keeps some room.
  final double maxWidth;

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 6),
        ExcludeSemantics(child: Text('·', style: context.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary))),
        const SizedBox(width: 2),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: FollowButton(
            userId: widget.author.id,
            name: widget.author.displayName,
            initiallyFollowing: widget.initiallyFollowing,
            text: true,
            dense: true,
            followLabel: context.l10n.commentRowFollow,
          ),
        ),
      ],
    );
  }
}

/// "⋯": the comment's menu (the caller shows it only when the viewer has anything in it).
class _Menu extends StatelessWidget {
  const _Menu({required this.comment, required this.callbacks, required this.guest});

  final Comment comment;
  final CommentCallbacks callbacks;
  final bool guest;

  static const size = 32.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final menu = commentMenuActions(comment, guest: guest);
    final authorId = comment.author?.id;
    // A commenter the viewer muted: the item reads "Unmute commenter" (F28).
    final authorMuted = !guest &&
        context.select(
          (MutesCubit? c) =>
              authorId != null && (c?.state.isUserMuted(authorId, fallback: comment.isAuthorMuted) ?? comment.isAuthorMuted),
        );
    return SizedBox(
      width: size,
      height: size,
      child: PopupMenuButton<CommentMenuAction>(
        tooltip: l10n.commentsMenu,
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary, size: 18),
        onSelected: (action) => callbacks.onMenu(comment, action),
        itemBuilder: (context) => [
          for (final action in menu)
            PopupMenuItem(
              value: action,
              child: _MenuLabel(action: action, authorMuted: authorMuted, username: comment.author?.username ?? ''),
            ),
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

/// Under the bubble: "Like" (♥ n once anyone liked it) · "Reply"; "Sending…" while the comment is on its way.
class _Actions extends StatelessWidget {
  const _Actions({required this.comment, required this.callbacks, required this.pending});

  final Comment comment;
  final CommentCallbacks callbacks;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final label = _actionStyle(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s1),
      child: pending
          ? SizedBox(
              height: 32,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(l10n.commentsSending, style: label),
                ),
              ),
            )
          : Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CommentLikeButton(liked: comment.likedByMe, count: comment.likeCount, onPressed: () => callbacks.onLike(comment)),
                ExcludeSemantics(child: Text('·', style: label?.copyWith(color: colors.textSecondary))),
                Semantics(
                  button: true,
                  label: l10n.commentsReply,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => callbacks.onReply(comment),
                    borderRadius: BorderRadius.circular(ReadInRadius.chip),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Center(widthFactor: 1, child: Text(l10n.commentsReply, style: label)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The actions' text under a comment: 13 px, semibold, secondary.
TextStyle? _actionStyle(BuildContext context) =>
    context.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary, fontWeight: FontWeight.w600);

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.action, this.authorMuted = false, this.username = ''});

  final CommentMenuAction action;

  /// The commenter, for «حظر @username».
  final String username;

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
      CommentMenuAction.block => (Icons.block_outlined, l10n.blockMenuUser(Bidi.ltrIsolate('@$username'))),
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

/// "Like" in a comment's actions: the primary color once the viewer liked it; ♥ n after it when anyone did.
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
    final style = _actionStyle(context)?.copyWith(color: color);
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
          constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.commentsLike, style: style),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.favorite_rounded, size: 14, color: liked ? colors.primary : colors.textSecondary),
                  const SizedBox(width: 2),
                  Text('$count', style: style),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
