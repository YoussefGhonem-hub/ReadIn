import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../cubit/follows_cubit.dart';

/// Follow / Following for one writer (F12). Hidden on the viewer's own profile and articles; guests see "Follow" and
/// get the sign-in prompt. Applies at once and rolls back on failure.
class FollowButton extends StatelessWidget {
  const FollowButton({super.key, required this.userId, required this.name, this.initiallyFollowing = false, this.dense = false});

  final String userId;

  /// For the screen reader: "Follow Ahmed".
  final String name;

  /// What the screen loaded (`isFollowingAuthor`, `UserSummaryDto.isFollowing`) until the store knows better.
  final bool initiallyFollowing;
  final bool dense;

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
  });

  final bool following;
  final bool pending;
  final String name;
  final bool dense;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final onTap = pending ? null : onPressed;
    final padding = EdgeInsets.symmetric(horizontal: dense ? 12 : 16);
    const minimumSize = Size(64, 44);
    final label = Text(following ? l10n.followingState : l10n.follow);
    return Semantics(
      button: true,
      toggled: following,
      label: following ? l10n.unfollowName(name) : l10n.followName(name),
      excludeSemantics: true,
      child: following
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
