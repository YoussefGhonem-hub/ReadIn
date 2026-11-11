import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/utils/link_opener.dart';
import '../cubit/devotions_cubits.dart';

/// The font of the Uthmani text (assets/fonts/AmiriQuran-Regular.ttf, OFL).
const quranFontFamily = 'Amiri Quran';

/// `12` → `١٢`: ayah numbers and counters in the Arabic-Indic digits of the mushaf.
String arabicIndicDigits(int value) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((d) => digits[int.parse(d)]).join();
}

/// A count in the UI's digits: Arabic-Indic in Arabic («١ من ٣»), as the mushaf writes them; Western in English.
String devotionsCount(BuildContext context, int value) =>
    context.l10n.localeName.startsWith('ar') ? arabicIndicDigits(value) : '$value';

/// The counter of a dhikr or a du'a: «المتبقي: ١ من ٣» while repetitions are left, then «تم» with a check.
class DevotionsCounter extends StatelessWidget {
  const DevotionsCounter({super.key, required this.left, required this.total});

  final int left;
  final int total;

  /// What a screen reader says for it.
  static String label(BuildContext context, int left, int total) => left == 0
      ? context.l10n.devotionsDone
      : context.l10n.devotionsLeft(devotionsCount(context, left), devotionsCount(context, total));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedSwitcher(
      duration: ReadInMotion.fast,
      child: left == 0
          ? Row(
              key: const ValueKey('done'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: colors.primary, size: 20),
                const SizedBox(width: ReadInSpace.s1),
                Text(context.l10n.devotionsDone, style: context.textTheme.labelLarge?.copyWith(color: colors.primary)),
              ],
            )
          : Container(
              key: ValueKey('left-$left'),
              padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s1),
              decoration: BoxDecoration(
                color: colors.accentContainer,
                borderRadius: BorderRadius.circular(ReadInRadius.chip),
              ),
              child: Text(
                label(context, left, total),
                style: context.textTheme.labelLarge?.copyWith(color: colors.textPrimary),
              ),
            ),
    );
  }
}

/// − / + for the text of the surahs and the adhkar ([DevotionsTextSizeCubit], kept on the device).
class DevotionsTextSizeActions extends StatelessWidget {
  const DevotionsTextSizeActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<DevotionsTextSizeCubit>();
    context.watch<DevotionsTextSizeCubit>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('devotions-text-smaller'),
          tooltip: l10n.devotionsTextSmaller,
          onPressed: cubit.canShrink ? () => unawaited(cubit.shrink()) : null,
          icon: const Icon(Icons.text_decrease_rounded),
        ),
        IconButton(
          key: const ValueKey('devotions-text-larger'),
          tooltip: l10n.devotionsTextLarger,
          onPressed: cubit.canGrow ? () => unawaited(cubit.grow()) : null,
          icon: const Icon(Icons.text_increase_rounded),
        ),
      ],
    );
  }
}

/// The source line under a text, its link opening in the browser.
class DevotionsSource extends StatelessWidget {
  const DevotionsSource({super.key, required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      key: const ValueKey('devotions-source'),
      onPressed: () => unawaited(openExternalLink(url)),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
      ),
    ),
  );
}

/// A page's content width on large phones and tablets in landscape: the text keeps a readable measure.
class DevotionsColumn extends StatelessWidget {
  const DevotionsColumn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4),
        child: child,
      ),
    ),
  );
}
