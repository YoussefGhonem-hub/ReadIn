import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../cubit/privacy_cubit.dart';

/// "Show on my public profile" for the reading stats (F14, F18). Needs a [PrivacyCubit] above it; used on the own
/// profile and in Settings → Privacy.
class PublicReadingStatsSwitch extends StatelessWidget {
  const PublicReadingStatsSwitch({super.key});

  Future<void> _set(BuildContext context, bool visible) async {
    final failure = await context.read<PrivacyCubit>().setPublicReadingStats(visible);
    if (context.mounted) showActionFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<PrivacyCubit>().state;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 56,
      title: Text(l10n.profilePublicReadingStats, style: context.textTheme.bodyLarge),
      subtitle: Text(
        state.publicReadingStats ? l10n.profilePublicReadingStatsOn : l10n.profilePublicReadingStatsOff,
        style: context.textTheme.bodySmall,
      ),
      value: state.publicReadingStats,
      // While saving, the switch shows the new value and ignores taps (no double submit).
      onChanged: state.pending ? null : (visible) => _set(context, visible),
    );
  }
}
