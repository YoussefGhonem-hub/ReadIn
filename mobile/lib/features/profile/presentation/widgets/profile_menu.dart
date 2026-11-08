import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../admin/presentation/admin_routes.dart';
import '../../../admin/presentation/widgets/admin_flows.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../../blocks/presentation/widgets/block_actions.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../moderation/presentation/widgets/moderation_flows.dart';
import '../../../moderation/presentation/widgets/report_sheet.dart';
import '../../../mutes/presentation/cubit/mutes_cubit.dart';
import '../../../mutes/presentation/widgets/mute_actions.dart';
import '../../domain/entities/profile.dart';

/// The items of the "⋯" on someone else's profile: Mute or Unmute (F28), Report, then the moderator tools (F22) and
/// the admin's (F23).
enum ProfileMenuItem { mute, block, report, warn, suspend, unsuspend, removeBadge, openInConsole }

/// Anyone can mute and report the user (guests get the sign-in prompt); moderators can warn, and suspend with
/// `users.suspend`. Mute comes first, but never on your own profile ([own]) or the official ReadIn account
/// ([systemAccount], `ProfileDto.isSystemAccount`), which can't be muted. Block (F36) comes under Mute, on everyone but
/// yourself (the official account and staff included).
///
/// F23, with `ProfileDto.admin` (holders of `users.read`): no Warn or Suspend for staff ([staff]); "Unsuspend" instead
/// of "Suspend…" while [suspended]; "Remove verified badge" ([canRemoveBadge]: `verification.manage` on a verified,
/// non-system account) and "Open in console" ([console]: `users.read`).
List<ProfileMenuItem> profileMenuItems({
  required bool moderator,
  required bool canSuspend,
  bool own = false,
  bool systemAccount = false,
  bool staff = false,
  bool suspended = false,
  bool canRemoveBadge = false,
  bool console = false,
}) =>
    [
      if (!own && !systemAccount) ProfileMenuItem.mute,
      if (!own) ProfileMenuItem.block,
      ProfileMenuItem.report,
      if (moderator && !staff) ProfileMenuItem.warn,
      if (moderator && canSuspend && !staff) suspended ? ProfileMenuItem.unsuspend : ProfileMenuItem.suspend,
      if (canRemoveBadge) ProfileMenuItem.removeBadge,
      if (console) ProfileMenuItem.openInConsole,
    ];

/// "⋯" in the app bar of someone else's profile. Mute works like the article menu's Mute author ([MuteActions], the
/// app's [MutesCubit]): it ends the follow, and the confirmation's Undo follows again. Warning and suspending need a
/// [ModerationActionCubit] above (the profile page provides it). After an admin action, [onChanged] reloads the
/// profile, so the menu follows the account's new state.
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key, required this.profile, this.onChanged});

  final UserProfile profile;
  final VoidCallback? onChanged;

  Future<void> _onSelected(BuildContext context, ProfileMenuItem item) async {
    switch (item) {
      case ProfileMenuItem.mute:
        if (!requireAccount(context)) return;
        await MuteActions.toggleUser(context, userId: profile.id, name: profile.displayName, fallback: profile.isMuted);
      case ProfileMenuItem.block:
        // The profile then reads «هذا الحساب غير متاح» with Unblock (the page follows [BlocksCubit]).
        await BlockActions.block(context, userId: profile.id, username: profile.username);
      case ProfileMenuItem.report:
        await showReportSheet(
          context,
          target: ModerationTargetRef.user(profile.id),
          author: ReportAuthor(profile.id, profile.username),
        );
      case ProfileMenuItem.warn:
        await ModerationFlows.warn(context, userId: profile.id, name: profile.displayName);
      case ProfileMenuItem.suspend:
        if (await ModerationFlows.suspend(context, userId: profile.id, name: profile.displayName)) onChanged?.call();
      case ProfileMenuItem.unsuspend:
        if (await ModerationFlows.unsuspend(context, userId: profile.id, name: profile.displayName)) onChanged?.call();
      case ProfileMenuItem.removeBadge:
        if (await AdminFlows.removeBadge(context, userId: profile.id, name: profile.displayName)) onChanged?.call();
      case ProfileMenuItem.openInConsole:
        await context.push<void>(AdminRoutes.user(profile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = context.select((SessionCubit c) => c.state.me);
    final muted = context.select(
      (MutesCubit? c) => c?.state.isUserMuted(profile.id, fallback: profile.isMuted) ?? profile.isMuted,
    );
    final own = profile.isMe || me?.id == profile.id;
    final admin = profile.admin;
    final items = profileMenuItems(
      moderator: me?.isModerator ?? false,
      canSuspend: me?.canSuspend ?? false,
      own: own,
      systemAccount: profile.isSystemAccount,
      // F23: the account's state comes with `users.read`; staff (and yourself) are never warned or suspended.
      staff: own || (admin?.isStaff ?? false),
      suspended: admin?.isSuspended ?? false,
      canRemoveBadge: !own && (me?.canManageVerification ?? false) && profile.isVerified && !profile.isSystemAccount,
      console: !own && (me?.canReadUsers ?? false),
    );
    // The moderator and admin tools sit apart, after a divider.
    final firstTool = items
        .where((item) => item != ProfileMenuItem.mute && item != ProfileMenuItem.block && item != ProfileMenuItem.report)
        .firstOrNull;
    return PopupMenuButton<ProfileMenuItem>(
      tooltip: l10n.profileMenu,
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (item) => unawaited(_onSelected(context, item)),
      itemBuilder: (context) => [
        for (final item in items) ...[
          if (item == firstTool) const PopupMenuDivider(),
          PopupMenuItem(
            value: item,
            child: _ProfileMenuLabel(item: item, muted: me != null && muted, username: profile.username),
          ),
        ],
      ],
    );
  }
}

class _ProfileMenuLabel extends StatelessWidget {
  const _ProfileMenuLabel({required this.item, required this.muted, this.username = ''});

  final ProfileMenuItem item;

  /// For «حظر @username».
  final String username;

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
      ProfileMenuItem.block => (Icons.block_outlined, l10n.blockMenuUser(BlockActions.handle(username))),
      ProfileMenuItem.report => (Icons.flag_outlined, l10n.profileMenuReport),
      ProfileMenuItem.warn => (Icons.report_gmailerrorred_rounded, l10n.profileMenuWarn),
      ProfileMenuItem.suspend => (Icons.block_rounded, l10n.profileMenuSuspend),
      ProfileMenuItem.unsuspend => (Icons.lock_open_rounded, l10n.moderationUnsuspend),
      ProfileMenuItem.removeBadge => (Icons.remove_moderator_outlined, l10n.adminRemoveBadge),
      ProfileMenuItem.openInConsole => (Icons.admin_panel_settings_outlined, l10n.adminOpenInConsole),
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
