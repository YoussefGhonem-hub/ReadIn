import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

// Reading mode (F04), as on the web: a button in the reader's top bar turns it on. The reader then leaves out its top
// bar and its action bar (it sits above the bottom nav, so none shows) and keeps the article and the reading progress
// bar. A small floating "Exit reading mode" control, or system back, turns it off. The choice stays on this device
// ([AppSettings.readingMode], not synced).

/// Whether the reader is in reading mode (F04); rebuilds the caller when it changes.
bool readingModeOf(BuildContext context) => context.select((SettingsCubit c) => c.state.readingMode);

/// The reader's reading mode button, next to the font size in its top bar. Its name is the same on and off, and it
/// says whether it is on (selected), like the web's `aria-pressed` button.
class ReadingModeToggle extends StatelessWidget {
  const ReadingModeToggle({super.key});

  static const buttonKey = ValueKey('reading-mode-toggle');

  @override
  Widget build(BuildContext context) {
    final on = readingModeOf(context);
    return IconButton(
      key: buttonKey,
      tooltip: context.l10n.readingModeToggle,
      isSelected: on,
      icon: const Icon(Icons.chrome_reader_mode_outlined),
      selectedIcon: const Icon(Icons.chrome_reader_mode_rounded),
      onPressed: () => unawaited(context.read<SettingsCubit>().setReadingMode(!on)),
    );
  }
}

/// Wraps the reader for reading mode:
/// - system back (Android's button and gesture) leaves reading mode first, and only then the reader; iOS's back swipe
///   waits meanwhile;
/// - switching keeps the text where it was on screen: the top bar's height comes back as scroll on [controller];
/// - screen readers hear "Reading mode is on" / "off".
class ReadingModeFrame extends StatelessWidget {
  const ReadingModeFrame({super.key, required this.child, this.controller});

  final Widget child;

  /// The reader's scroll view, kept in place as the bars go and come back.
  final ScrollController? controller;

  /// Runs as the choice changes, before the reader rebuilds without (or with) its bars: notes where the scroll view
  /// sits on screen, to put the text back there once the new layout is done.
  void _onChanged(BuildContext context, bool on) {
    if (MediaQuery.maybeAccessibleNavigationOf(context) ?? false) {
      final l10n = context.l10n;
      unawaited(SemanticsService.sendAnnouncement(
        View.of(context),
        on ? l10n.readingModeOn : l10n.readingModeOff,
        Directionality.of(context),
      ));
    }
    // Only the reader on screen moves: one under another page isn't laid out.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final before = _viewportTop();
    if (before == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = this.controller;
      final after = _viewportTop();
      if (controller == null || after == null || !controller.hasClients) return;
      final position = controller.position;
      final target = (position.pixels + after - before).clamp(position.minScrollExtent, position.maxScrollExtent);
      if (target != position.pixels) controller.jumpTo(target);
    });
  }

  /// The top of the scroll view on screen, or null while there is none (the reader is loading).
  double? _viewportTop() {
    final controller = this.controller;
    if (controller == null || !controller.hasClients) return null;
    final box = controller.position.context.notificationContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero).dy;
  }

  @override
  Widget build(BuildContext context) {
    final on = readingModeOf(context);
    return BlocListener<SettingsCubit, AppSettings>(
      listenWhen: (previous, current) => previous.readingMode != current.readingMode,
      listener: (context, settings) => _onChanged(context, settings.readingMode),
      child: PopScope(
        canPop: !on,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && on) unawaited(context.read<SettingsCubit>().setReadingMode(false));
        },
        child: child,
      ),
    );
  }
}

/// "Exit reading mode": a small pill floating at the bottom end corner of the reader, as on the web (on `surface`, a
/// line around it, a raised shadow), for the reader's [Scaffold.floatingActionButton] with
/// [FloatingActionButtonAnimator.noAnimation]: it fades in by itself, unless reduce motion is on.
class ReadingModeExitButton extends StatelessWidget {
  const ReadingModeExitButton({super.key = exitKey});

  static const exitKey = ValueKey('reading-mode-exit');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: animate ? ReadInMotion.base : Duration.zero,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * 6), child: child),
      ),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border),
          shape: const StadiumBorder(),
          elevation: 3,
          shadowColor: colors.scrim,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4),
          textStyle: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        onPressed: () => unawaited(context.read<SettingsCubit>().setReadingMode(false)),
        icon: const Icon(Icons.close_fullscreen_rounded, size: 18),
        label: Text(context.l10n.readingModeExit),
      ),
    );
  }
}
