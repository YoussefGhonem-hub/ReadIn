import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../moderation/presentation/widgets/moderation_flows.dart';
import '../../../moderation/presentation/widgets/report_sheet.dart';
import '../../domain/entities/profile.dart';

/// The items of the "⋯" on someone else's profile (F22).
enum ProfileMenuItem { report, warn, suspend }

/// Anyone can report the user (guests get the sign-in prompt); moderators can warn, and suspend with `users.suspend`.
List<ProfileMenuItem> profileMenuItems({required bool moderator, required bool canSuspend}) => [
      ProfileMenuItem.report,
      if (moderator) ProfileMenuItem.warn,
      if (moderator && canSuspend) ProfileMenuItem.suspend,
    ];

/// "⋯" in the app bar of someone else's profile. Warning and suspending need a [ModerationActionCubit] above (the
/// profile page provides it).
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key, required this.profile});

  final UserProfile profile;

  Future<void> _onSelected(BuildContext context, ProfileMenuItem item) async {
    switch (item) {
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
    final items = profileMenuItems(moderator: me?.isModerator ?? false, canSuspend: me?.canSuspend ?? false);
    return PopupMenuButton<ProfileMenuItem>(
      tooltip: l10n.profileMenu,
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (item) => unawaited(_onSelected(context, item)),
      itemBuilder: (context) => [
        for (final item in items) ...[
          if (item == ProfileMenuItem.warn) const PopupMenuDivider(),
          PopupMenuItem(value: item, child: _ProfileMenuLabel(item: item)),
        ],
      ],
    );
  }
}

class _ProfileMenuLabel extends StatelessWidget {
  const _ProfileMenuLabel({required this.item});

  final ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (icon, text) = switch (item) {
      ProfileMenuItem.report => (Icons.flag_outlined, l10n.profileMenuReport),
      ProfileMenuItem.warn => (Icons.report_gmailerrorred_rounded, l10n.profileMenuWarn),
      ProfileMenuItem.suspend => (Icons.block_rounded, l10n.profileMenuSuspend),
    };
    final color = item == ProfileMenuItem.warn ? colors.textPrimary : colors.error;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: ReadInSpace.s3),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}
