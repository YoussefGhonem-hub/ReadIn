import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../domain/entities/app_settings.dart';
import '../cubit/settings_cubit.dart';

/// The theme a tap on [ThemeToggleButton] picks: the opposite of the one [shown] now. "System" has already resolved to
/// the platform's brightness in [shown], so it flips to an explicit light or dark.
ThemePreference toggledTheme(Brightness shown) => shown == Brightness.dark ? ThemePreference.light : ThemePreference.dark;

/// The sun / moon in the tabs' top bar: one tap flips light ↔ dark and saves it like Settings → Appearance does
/// ([SettingsCubit.setTheme]: on this device, and on the account when signed in). A moon in light mode, a sun in dark.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  Future<void> _toggle(BuildContext context, Brightness shown) async {
    final failure = await context.read<SettingsCubit>().setTheme(toggledTheme(shown));
    if (context.mounted) showActionFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The theme on screen: the saved light or dark, or the platform's brightness for "system".
    final shown = Theme.of(context).brightness;
    final dark = shown == Brightness.dark;
    final label = dark ? l10n.themeSwitchToLight : l10n.themeSwitchToDark;
    // One node for screen readers: the button, its label, and "on" while dark.
    return MergeSemantics(
      child: Semantics(
        toggled: dark,
        child: IconButton(
          key: const ValueKey('theme-toggle'),
          tooltip: label,
          onPressed: () => unawaited(_toggle(context, shown)),
          icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        ),
      ),
    );
  }
}
