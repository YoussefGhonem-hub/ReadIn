import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../moderation/presentation/widgets/moderation_flows.dart';
import '../../../moderation/presentation/widgets/report_sheet.dart';
import '../../../mutes/presentation/cubit/mutes_cubit.dart';
import '../../../mutes/presentation/widgets/mute_actions.dart';
import '../../domain/entities/profile.dart';

/// The items of the "⋯" on someone else's profile: Mute or Unmute (F28), Report, then the moderator tools (F22).
enum ProfileMenuItem { mute, report, warn, suspend }

/// Anyone can mute and report the user (guests get the sign-in prompt); moderators can warn, and suspend with
/// `users.suspend`. Mute comes first, but never on your own profile ([own]) or the official ReadIn account
/// ([systemAccount], `ProfileDto.isSystemAccount`), which can't be muted.
List<ProfileMenuItem> profileMenuItems({
  required bool moderator,
  required bool canSuspend,
  bool own = false,
  bool systemAccount = false,
}) =>
    [
      if (!own && !systemAccount) ProfileMenuItem.mute,
      ProfileMenuItem.report,
      if (moderator) ProfileMenuItem.warn,
      if (moderator && canSuspend) ProfileMenuItem.suspend,
    ];

/// "⋯" in the app bar of someone else's profile. Mute works like the article menu's Mute author ([MuteActions], the
/// app's [MutesCubit]): it ends the follow, and the confirmation's Undo follows again. Warning and suspending need a
/// [ModerationActionCubit] above (the profile page provides it).
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key, required this.profile});

  final UserProfile profile;

  Future<void> _onSelected(BuildContext context, ProfileMenuItem item) async {
    switch (item) {
      case ProfileMenuItem.mute:
        if (!requireAccount(context)) return;
        await MuteActions.toggleUser(context, userId: profile.id, name: profile.displayName, fallback: profile.isMuted);
      case ProfileMenuItem.report:
        await showReportSheet(context, target: ModerationTargetRef.user(profile.id));
      case ProfileMenuItem.warn:
        await ModerationFlows.warn(context, userId: profile.id, name: profile.displayName);
      case ProfileMenuItem.suspend:
        await ModerationFlows.suspend(context, userId: profile.id, name: profile.displayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = context.select((SessionCubit c) => c.state.me);
    final muted = context.select(
      (MutesCubit? c) => c?.state.isUserMuted(profile.id, fallback: profile.isMuted) ?? profile.isMuted,
    );
    final items = profileMenuItems(
      moderator: me?.isModerator ?? false,
      canSuspend: me?.canSuspend ?? false,
      own: profile.isMe || me?.id == profile.id,
      systemAccount: profile.isSystemAccount,
    );
    return PopupMenuButton<ProfileMenuItem>(
      tooltip: l10n.profileMenu,
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (item) => unawaited(_onSelected(context, item)),
      itemBuilder: (context) => [
        for (final item in items) ...[
          if (item == ProfileMenuItem.warn) const PopupMenuDivider(),
          PopupMenuItem(value: item, child: _ProfileMenuLabel(item: item, muted: me != null && muted)),
        ],
      ],
    );
  }
}

class _ProfileMenuLabel extends StatelessWidget {
  const _ProfileMenuLabel({required this.item, required this.muted});

  final ProfileMenuItem item;

  /// The viewer muted this user: "Unmute user".
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (icon, text) = switch (item) {
      ProfileMenuItem.mute => muted
          ? (Icons.volume_up_outlined, l10n.muteMenuUnmuteUser)
          : (Icons.volume_off_outlined, l10n.muteMenuUser),
      ProfileMenuItem.report => (Icons.flag_outlined, l10n.profileMenuReport),
      ProfileMenuItem.warn => (Icons.report_gmailerrorred_rounded, l10n.profileMenuWarn),
      ProfileMenuItem.suspend => (Icons.block_rounded, l10n.profileMenuSuspend),
    };
    final color = item == ProfileMenuItem.report || item == ProfileMenuItem.suspend ? colors.error : colors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: ReadInSpace.s3),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}
