import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../cubit/follows_cubit.dart';

/// Follow / Following for one writer (F12). Hidden on the viewer's own profile and articles; guests see "Follow" and
/// get the sign-in prompt. Applies at once and rolls back on failure.
class FollowButton extends StatelessWidget {
  const FollowButton({
    super.key,
    required this.userId,
    required this.name,
    this.initiallyFollowing = false,
    this.dense = false,
    this.text = false,
    this.followLabel,
  });

  final String userId;

  /// For the screen reader: "Follow Ahmed".
  final String name;

  /// What the screen loaded (`isFollowingAuthor`, `UserSummaryDto.isFollowing`) until the store knows better.
  final bool initiallyFollowing;
  final bool dense;

  /// A text button with no fill (the post card's header, F34).
  final bool text;

  /// What "Follow" says, e.g. "متابعة" on comment rows (F11). "Following" stays.
  final String? followLabel;

  Future<void> _toggle(BuildContext context) async {
    if (!requireAccount(context)) return;
    final failure = await context.read<FollowsCubit>().toggle(userId, fallback: initiallyFollowing);
    if (context.mounted) showActionFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final (signedIn, myId) = context.select((SessionCubit c) => (c.state.isAuthenticated, c.state.me?.id));
    if (signedIn && myId == userId) return const SizedBox.shrink();
    final follows = context.select((FollowsCubit c) => (c.state.isFollowing(userId, fallback: initiallyFollowing), c.state.isPending(userId)));
    final following = signedIn && follows.$1;
    final pending = follows.$2;
    return FollowButtonView(
      following: following,
      pending: pending,
      name: name,
      dense: dense,
      text: text,
      followLabel: followLabel,
      onPressed: () => _toggle(context),
    );
  }
}

/// The look of [FollowButton]: a filled "Follow", an outlined "✓ Following". While a request is in flight it shows
/// the new state and ignores taps.
class FollowButtonView extends StatelessWidget {
  const FollowButtonView({
    super.key,
    required this.following,
    required this.name,
    required this.onPressed,
    this.pending = false,
    this.dense = false,
    this.text = false,
    this.followLabel,
  });

  final bool following;
  final bool pending;
  final String name;
  final bool dense;

  /// "+ Follow" / "✓ Following" as a text button in the primary color (the post card's header, F34). With [dense],
  /// just the word, sized for a line of text (comment rows, F11).
  final bool text;
  final VoidCallback onPressed;

  /// What "Follow" says when it isn't a person: "Follow field", "Follow topic" (F15). "Following" stays.
  final String? followLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final onTap = pending ? null : onPressed;
    final padding = EdgeInsets.symmetric(horizontal: dense ? 12 : 16);
    const minimumSize = Size(64, 44);
    final label = Text(following ? l10n.followingState : followLabel ?? l10n.follow);
    return Semantics(
      button: true,
      toggled: following,
      label: following ? l10n.unfollowName(name) : l10n.followName(name),
      excludeSemantics: true,
      child: text && dense
          // Inside a line of text (a comment's name line, F11): a bare word, 13 px, no taller than the line.
          ? TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s1),
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                foregroundColor: following ? colors.textSecondary : colors.primary,
                disabledForegroundColor: colors.textSecondary,
                textStyle: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              child: label,
            )
          : text
          ? TextButton.icon(
              onPressed: onTap,
              icon: Icon(following ? Icons.check_rounded : Icons.add_rounded, size: 18),
              label: label,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: dense ? ReadInSpace.s1 : ReadInSpace.s2),
                minimumSize: dense ? const Size(44, 40) : const Size(48, 44),
                foregroundColor: following ? colors.textSecondary : colors.primary,
                disabledForegroundColor: colors.textSecondary,
                textStyle: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            )
          : following
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: label,
              style: OutlinedButton.styleFrom(
                padding: padding,
                minimumSize: minimumSize,
                foregroundColor: colors.textPrimary,
                disabledForegroundColor: colors.textSecondary,
                side: BorderSide(color: colors.border),
              ),
            )
          : FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: label,
              style: FilledButton.styleFrom(
                padding: padding,
                minimumSize: minimumSize,
                disabledBackgroundColor: colors.primary.withValues(alpha: 0.6),
                disabledForegroundColor: colors.onPrimary,
              ),
            ),
    );
  }
}
