import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/devotions.dart';
import '../cubit/devotions_cubits.dart';
import '../widgets/devotions_widgets.dart';

/// The morning or evening adhkar (F38): Hisn al-Muslim's chapter, verbatim with its notes, the adhkar of the other
/// time left out. Each card counts the repetitions down on a tap; «إعادة» starts over.
class AdhkarPage extends StatelessWidget {
  const AdhkarPage({super.key, required this.session, this.cubit, this.textSize});

  final AdhkarSession session;

  /// Test seams; the app takes them from DI.
  final AdhkarCubit? cubit;
  final DevotionsTextSizeCubit? textSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => (cubit ?? getIt<AdhkarCubit>())..load(session)),
        BlocProvider.value(value: textSize ?? getIt<DevotionsTextSizeCubit>()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(session == AdhkarSession.morning ? l10n.devotionsMorning : l10n.devotionsEvening),
          actions: [
            const DevotionsTextSizeActions(),
            Builder(
              builder: (context) => IconButton(
                key: const ValueKey('adhkar-reset'),
                tooltip: l10n.devotionsReset,
                onPressed: context.read<AdhkarCubit>().reset,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ),
          ],
        ),
        body: BlocBuilder<AdhkarCubit, AdhkarState>(
          builder: (context, state) => switch (state.status) {
            DevotionsStatus.loading => const Center(child: CircularProgressIndicator()),
            DevotionsStatus.failure => ErrorView(
              failure: state.failure!,
              onRetry: () => context.read<AdhkarCubit>().load(session),
            ),
            DevotionsStatus.ready => _AdhkarList(state: state),
          },
        ),
      ),
    );
  }
}

class _AdhkarList extends StatelessWidget {
  const _AdhkarList({required this.state});

  final AdhkarState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final items = state.items;
    return ListView.separated(
      key: const ValueKey('adhkar-list'),
      padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s4),
      itemCount: items.length + 2,
      separatorBuilder: (_, _) => const SizedBox(height: ReadInSpace.s3),
      itemBuilder: (context, i) {
        if (i == 0) {
          return DevotionsColumn(
            child: Text(
              '${l10n.devotionsProgress(state.doneCount, items.length)} · ${l10n.devotionsTapToCount}',
              key: const ValueKey('adhkar-progress'),
              style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          );
        }
        if (i == items.length + 1) {
          return DevotionsColumn(
            child: DevotionsSource(label: l10n.devotionsAdhkarSource, url: state.book!.sourceUrl),
          );
        }
        final dhikr = items[i - 1];
        return DevotionsColumn(
          child: _DhikrCard(key: ValueKey('dhikr-${dhikr.id}'), dhikr: dhikr, left: state.left(dhikr)),
        );
      },
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({super.key, required this.dhikr, required this.left});

  final Dhikr dhikr;
  final int left;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scale = context.watch<DevotionsTextSizeCubit>().state;
    final done = left == 0;
    return Semantics(
      button: !done,
      label: DevotionsCounter.label(context, left, dhikr.repeat),
      child: Material(
        color: done ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReadInRadius.card),
          side: BorderSide(color: done ? colors.primary.withValues(alpha: 0.4) : colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: done
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  context.read<AdhkarCubit>().count(dhikr);
                },
          child: Padding(
            padding: const EdgeInsets.all(ReadInSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dhikr.text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.start,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontSize: 19 * scale,
                    height: 2,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: ReadInSpace.s3),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: DevotionsCounter(left: left, total: dhikr.repeat),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
