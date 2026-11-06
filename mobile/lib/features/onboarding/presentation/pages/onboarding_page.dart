import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../notifications/presentation/cubit/notification_settings_cubit.dart';
import '../../../notifications/presentation/widgets/daily_article_switch.dart';
import '../../../settings/presentation/widgets/preference_tiles.dart';
import '../cubit/onboarding_cubit.dart';

/// Onboarding (F02) for new accounts, after Complete profile: interests (min 3) and preferences. The welcome step is
/// the Welcome screen before sign up (SPEC §9.2), so this screen has two steps of its own and counts them "1 of 2",
/// "2 of 2".
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.read<SessionCubit>().state.me;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<OnboardingCubit>()
            ..start(signedIn: me != null, fieldIds: me?.interestFieldIds ?? const [], topicIds: me?.interestTopicIds ?? const []),
        ),
        // The daily-article switch of the last step is the account's `daily_article` mode (F17): loaded from the start.
        BlocProvider(create: (_) => getIt<NotificationSettingsCubit>()..load(), lazy: me == null),
      ],
      child: const OnboardingView(),
    );
  }
}

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  /// The steps this screen counts: interests, then preferences.
  static const steps = 2;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (a, b) => !a.completed && b.completed,
      listener: (context, state) async {
        await context.read<SessionCubit>().refresh();
        if (context.mounted) context.go('/home');
      },
      builder: (context, state) {
        // Interests is step 1 and preferences step 2: the welcome step came before sign up.
        final step = state.step.index;
        const steps = OnboardingView.steps;
        // One white page, the bar too and with no line under it (its progress is its edge), as on Sign in.
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: state.step == OnboardingStep.welcome
              ? null
              : AppBar(
                  shape: const Border(),
                  leading: state.step == OnboardingStep.preferences
                      ? IconButton(
                          icon: const BackButtonIcon(),
                          tooltip: context.l10n.back,
                          onPressed: context.read<OnboardingCubit>().backToInterests,
                        )
                      : null,
                  automaticallyImplyLeading: false,
                  title: Text(context.l10n.stepOf(step, steps), style: context.textTheme.bodySmall),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
                      child: LinearProgressIndicator(
                        value: step / steps,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(ReadInRadius.chip),
                      ),
                    ),
                  ),
                ),
          body: SafeArea(
            child: switch (state.step) {
              // Only while start() runs: guests never get here (the router sends them to Welcome).
              OnboardingStep.welcome => const Center(child: CircularProgressIndicator()),
              OnboardingStep.interests => _InterestsStep(state: state),
              OnboardingStep.preferences => _PreferencesStep(state: state),
            },
          ),
        );
      },
    );
  }
}

class _InterestsStep extends StatelessWidget {
  const _InterestsStep({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<OnboardingCubit>();
    final lang = Localizations.localeOf(context).languageCode;

    final Widget body;
    if (state.loadingFields && state.fields.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.fieldsFailure != null && state.fields.isEmpty) {
      body = ErrorView(failure: state.fieldsFailure!, onRetry: cubit.loadFields);
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s5),
        children: [
          Text(l10n.interestsTitle, style: context.textTheme.headlineSmall),
          const SizedBox(height: ReadInSpace.s2),
          Text(l10n.interestsSubtitle, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s5),
          Wrap(
            spacing: ReadInSpace.s2,
            runSpacing: ReadInSpace.s2,
            children: [
              for (final field in state.fields)
                FilterChip(
                  label: BidiText(field.nameFor(lang)),
                  selected: state.selectedFieldIds.contains(field.id),
                  onSelected: (_) => cubit.toggleField(field),
                ),
            ],
          ),
          for (final field in state.fields.where((f) => state.selectedFieldIds.contains(f.id)))
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
                      selected: state.selectedTopicIds.contains(topic.id),
                      onSelected: (_) => cubit.toggleTopic(topic),
                    ),
                ],
              ),
            ],
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: body),
        _BottomBar(
          caption: l10n.interestsSelected(state.selectedCount),
          child: FilledButton(onPressed: state.canContinue ? cubit.goToPreferences : null, child: Text(l10n.next)),
        ),
      ],
    );
  }
}

class _PreferencesStep extends StatelessWidget {
  const _PreferencesStep({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = state.submitFailure;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s5),
            children: [
              Text(l10n.preferencesTitle, style: context.textTheme.headlineSmall),
              const SizedBox(height: ReadInSpace.s2),
              Text(l10n.preferencesSubtitle, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
              const SizedBox(height: ReadInSpace.s5),
              const ArticleLanguageSelector(),
              const SizedBox(height: ReadInSpace.s4),
              const ReminderTimeTile(),
              const DailyArticleSwitch(),
            ],
          ),
        ),
        _BottomBar(
          caption: failure == null ? null : localizeFailure(l10n, failure),
          captionIsError: failure != null,
          child: FilledButton(
            onPressed: state.submitting ? null : () => _finish(context),
            child: state.submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : Text(l10n.finishOnboarding),
          ),
        ),
      ],
    );
  }
}

/// The reminder step is where the user just chose daily notifications, so
/// push permission is asked here, in context (SPEC §21.1), before finishing.
Future<void> _finish(BuildContext context) async {
  final cubit = context.read<OnboardingCubit>();
  if (DailyArticleSwitch.isOn(context.read<NotificationSettingsCubit>().state) && getIt.isRegistered<PushService>()) {
    await getIt<PushService>().enable();
  }
  await cubit.finish();
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child, this.caption, this.captionIsError = false});

  final Widget child;
  final String? caption;
  final bool captionIsError;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s3, ReadInSpace.s5, ReadInSpace.s4),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.colors.border))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (caption != null) ...[
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(color: captionIsError ? context.colors.error : null),
              ),
              const SizedBox(height: ReadInSpace.s2),
            ],
            child,
          ],
        ),
      );
}
