import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../moderation/presentation/widgets/moderation_labels.dart';
import '../admin_routes.dart';

/// On a suspended account's profile, which only holders of `users.read` can open (F23, `ProfileDto.admin`): until
/// when it is suspended, that others can't see it, and "Open in console".
class AdminSuspendedProfileBanner extends StatelessWidget {
  const AdminSuspendedProfileBanner({super.key, required this.userId, this.until, this.padding = EdgeInsets.zero});

  final String userId;

  /// When the suspension ends; null = permanently.
  final DateTime? until;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: padding,
      child: Semantics(
        container: true,
        child: Container(
          key: const ValueKey('profile-suspended-banner'),
          padding: const EdgeInsets.all(ReadInSpace.s3),
          decoration: BoxDecoration(
            color: colors.calloutDanger,
            borderRadius: BorderRadius.circular(ReadInRadius.md),
            border: BorderDirectional(start: BorderSide(color: colors.calloutDangerAccent, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.block_rounded, size: 20, color: colors.calloutDangerAccent),
              const SizedBox(width: ReadInSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.suspendedUntil(until), style: context.textTheme.titleSmall?.copyWith(color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(l10n.adminSuspendedProfileHint, style: context.textTheme.bodySmall?.copyWith(color: colors.textPrimary)),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                        onPressed: () => unawaited(context.push<void>(AdminRoutes.user(userId))),
                        child: Text(l10n.adminOpenInConsole),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
