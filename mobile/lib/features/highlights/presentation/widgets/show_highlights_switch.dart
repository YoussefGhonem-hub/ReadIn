import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

/// Settings → Reading → "Show highlights" (F18, F30): the same switch as the reader's "⋯" item. Saved to the account when
/// signed in (it goes back, with the reason, when that fails); a guest's stays on this device.
class ShowHighlightsSwitch extends StatelessWidget {
  const ShowHighlightsSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shown = context.select((SettingsCubit c) => c.state.showHighlights);
    return SwitchListTile(
      key: const ValueKey('settings-show-highlights'),
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.border_color_outlined),
      title: Text(l10n.highlightSettingTitle),
      subtitle: Text(l10n.highlightSettingHint),
      value: shown,
      onChanged: (show) async {
        final failure = await context.read<SettingsCubit>().setShowHighlights(show);
        if (context.mounted) showActionFailure(context, failure);
      },
    );
  }
}
