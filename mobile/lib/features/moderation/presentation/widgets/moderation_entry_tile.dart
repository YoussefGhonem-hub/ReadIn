import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../cubit/moderation_summary_cubit.dart';
import '../moderation_routes.dart';

/// Settings → Moderation (F22), for `moderation.manage` only: opens the queue, with the number of targets waiting for
/// review as a badge. Needs a [ModerationSummaryCubit] above it; loads it when shown.
class ModerationEntryTile extends StatefulWidget {
  const ModerationEntryTile({super.key});

  @override
  State<ModerationEntryTile> createState() => _ModerationEntryTileState();
}

class _ModerationEntryTileState extends State<ModerationEntryTile> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<ModerationSummaryCubit>().load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final open = context.select((ModerationSummaryCubit c) => c.state?.total);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.shield_outlined),
      title: Text(l10n.moderationQueueEntry),
      subtitle: open == null
          ? null
          : Text(l10n.moderationWaiting(open), style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (open != null && open > 0)
            Badge(
              label: Text(open > 99 ? '99+' : '$open'),
              backgroundColor: colors.error,
              textColor: colors.onError,
            ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: () => unawaited(context.push<void>(ModerationRoutes.home)),
    );
  }
}
