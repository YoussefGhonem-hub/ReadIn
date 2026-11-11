import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/devotions.dart';
import '../cubit/devotions_cubits.dart';
import '../widgets/devotions_widgets.dart';
import 'devotions_page.dart';

/// A surah of the private corner (F38): Tanzil's Uthmani text in the Amiri Quran font, the ayat flowing as in a
/// mushaf, each closed by the end-of-ayah mark with its number. The basmala opens the surah on its own line.
class SurahPage extends StatelessWidget {
  const SurahPage({super.key, required this.number, this.cubit, this.textSize});

  final int number;

  /// Test seams; the app takes them from DI.
  final SurahCubit? cubit;
  final DevotionsTextSizeCubit? textSize;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => (cubit ?? getIt<SurahCubit>())..load(number)),
      BlocProvider.value(value: textSize ?? getIt<DevotionsTextSizeCubit>()),
    ],
    child: Scaffold(
      appBar: AppBar(
        title: Text(DevotionsPage.surahName(context.l10n, number)),
        actions: const [DevotionsTextSizeActions()],
      ),
      body: BlocBuilder<SurahCubit, SurahState>(
        builder: (context, state) => switch (state.status) {
          DevotionsStatus.loading => const Center(child: CircularProgressIndicator()),
          DevotionsStatus.failure => ErrorView(
            failure: state.failure!,
            onRetry: () => context.read<SurahCubit>().load(number),
          ),
          DevotionsStatus.ready => _SurahText(surah: state.surah!),
        },
      ),
    ),
  );
}

class _SurahText extends StatelessWidget {
  const _SurahText({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scale = context.watch<DevotionsTextSizeCubit>().state;
    final style = TextStyle(fontFamily: quranFontFamily, fontSize: 26 * scale, height: 2.1, color: colors.textPrimary);
    final markStyle = style.copyWith(color: colors.primary);
    final opening = surah.opening;
    return SingleChildScrollView(
      key: const ValueKey('surah-text'),
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s5),
      child: DevotionsColumn(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s2),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(ReadInRadius.md),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'سُورَةُ ${surah.name}',
                  textAlign: TextAlign.center,
                  style: style.copyWith(fontSize: 24 * scale, height: 1.6, color: colors.onPrimaryContainer),
                ),
              ),
              if (opening != null) ...[
                const SizedBox(height: ReadInSpace.s3),
                Text(opening, key: const ValueKey('surah-opening'), textAlign: TextAlign.center, style: style),
              ],
              const SizedBox(height: ReadInSpace.s2),
              Text.rich(
                TextSpan(
                  children: [
                    for (var n = 1; n <= surah.ayat.length; n++) ...[
                      TextSpan(text: surah.ayahText(n)),
                      // U+06DD ARABIC END OF AYAH encloses the digits that follow it.
                      TextSpan(text: ' ۝${arabicIndicDigits(n)} ', style: markStyle),
                    ],
                  ],
                ),
                key: const ValueKey('surah-ayat'),
                textAlign: TextAlign.justify,
                style: style,
              ),
              const SizedBox(height: ReadInSpace.s4),
              DevotionsSource(label: context.l10n.devotionsQuranSource, url: surah.sourceUrl),
            ],
          ),
        ),
      ),
    );
  }
}
