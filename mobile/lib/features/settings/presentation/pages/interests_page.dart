import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../cubit/interests_cubit.dart';

/// Settings → Your interests (F02, F12), signed in only: the onboarding chips, each followed or unfollowed at once.
class InterestsPage extends StatelessWidget {
  const InterestsPage({super.key});

  static const path = '/settings/interests';

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<InterestsCubit>()..load(),
        child: const InterestsView(),
      );
}

class InterestsView extends StatelessWidget {
  const InterestsView({super.key});

  /// Says why a change went back: "Keep at least 3 interests" when it was the last ones.
  static Future<void> _save(BuildContext context, Future<Failure?> change) async {
    final failure = await change;
    if (failure == null || !context.mounted) return;
    if (failure.code == FailureCodes.interestsMinThree) return showActionMessage(context, context.l10n.interestsKeepThree);
    showActionFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<InterestsCubit>();
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsInterests)),
      body: BlocBuilder<InterestsCubit, InterestsState>(
        builder: (context, state) {
          if (state.loading && state.fields.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.failure != null && state.fields.isEmpty) {
            return ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load()));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s8),
            children: [
              Text(l10n.interestsPageIntro, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
              const SizedBox(height: ReadInSpace.s2),
              Text(l10n.interestsSelected(state.count), style: context.textTheme.labelMedium),
              const SizedBox(height: ReadInSpace.s4),
              Wrap(
                spacing: ReadInSpace.s2,
                runSpacing: ReadInSpace.s2,
                children: [
                  for (final field in state.fields)
                    FilterChip(
                      label: BidiText(field.nameFor(lang)),
                      selected: state.fieldIds.contains(field.id),
                      onSelected: (_) => unawaited(_save(context, cubit.toggleField(field))),
                    ),
                ],
              ),
              for (final field in state.fields.where(state.showsTopicsOf))
                if ((state.topics[field.id] ?? const []).isNotEmpty) ...[
                  const SizedBox(height: ReadInSpace.s5),
                  BidiText(field.nameFor(lang), style: context.textTheme.titleSmall),
                  const SizedBox(height: ReadInSpace.s2),
                  Wrap(
                    spacing: ReadInSpace.s2,
                    runSpacing: ReadInSpace.s2,
                    children: [
                      for (final topic in state.topics[field.id]!)
                        FilterChip(
                          label: BidiText(topic.nameFor(lang)),
                          selected: state.topicIds.contains(topic.id),
                          onSelected: (_) => unawaited(_save(context, cubit.toggleTopic(topic))),
                        ),
                    ],
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}
