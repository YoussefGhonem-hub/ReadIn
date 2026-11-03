import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_messages.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/widgets/preference_tiles.dart';
import '../cubit/onboarding_cubit.dart';

/// Onboarding (F02): 1. welcome · 2. interests (min 3) · 3. preferences.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.read<SessionCubit>().state.me;
    return BlocProvider(
      create: (_) => getIt<OnboardingCubit>()
        ..start(signedIn: me != null, fieldIds: me?.interestFieldIds ?? const [], topicIds: me?.interestTopicIds ?? const []),
      child: const OnboardingView(),
    );
  }
}

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (a, b) => !a.completed && b.completed,
      listener: (context, state) async {
        await context.read<SessionCubit>().refresh();
        if (context.mounted) context.go('/home');
      },
      builder: (context, state) {
        final index = state.step.index;
        return Scaffold(
          appBar: state.step == OnboardingStep.welcome
              ? null
              : AppBar(
                  leading: state.step == OnboardingStep.preferences
                      ? IconButton(
                          icon: const BackButtonIcon(),
                          tooltip: context.l10n.back,
                          onPressed: context.read<OnboardingCubit>().backToInterests,
                        )
                      : null,
                  automaticallyImplyLeading: false,
                  title: Text(context.l10n.stepOf(index + 1, 3), style: context.textTheme.bodySmall),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
                      child: LinearProgressIndicator(
                        value: (index + 1) / 3,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(ReadInRadius.chip),
                      ),
                    ),
                  ),
                ),
          body: SafeArea(
            child: switch (state.step) {
              OnboardingStep.welcome => const _WelcomeStep(),
              OnboardingStep.interests => _InterestsStep(state: state),
              OnboardingStep.preferences => _PreferencesStep(state: state),
            },
          ),
        );
      },
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  Future<void> _go(BuildContext context, String location) async {
    await context.read<SettingsCubit>().markWelcomeSeen();
    if (context.mounted) context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(ReadInSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ReadInSpace.s5),
          const Align(alignment: AlignmentDirectional.centerStart, child: AppLogo(size: 30)),
          const Spacer(),
          Container(
            height: 180,
            decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.sheet)),
            alignment: Alignment.center,
            child: Text('☕ 📖 🔥', style: context.textTheme.displaySmall),
          ),
          const SizedBox(height: ReadInSpace.s6),
          Text(l10n.onboardingWelcomeTitle, style: context.textTheme.headlineMedium),
          const SizedBox(height: ReadInSpace.s3),
          Text(l10n.onboardingWelcomeBody, style: context.textTheme.bodyLarge?.copyWith(color: colors.textSecondary)),
          const Spacer(),
          FilledButton(onPressed: () => _go(context, '/auth/sign-up'), child: Text(l10n.getStarted)),
          const SizedBox(height: ReadInSpace.s3),
          OutlinedButton(onPressed: () => _go(context, '/auth/sign-in'), child: Text(l10n.haveAccount)),
          const SizedBox(height: ReadInSpace.s2),
          TextButton(onPressed: () => _go(context, '/home'), child: Text(l10n.browseAsGuest)),
        ],
      ),
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
              const DailyNotificationTile(),
            ],
          ),
        ),
        _BottomBar(
          caption: failure == null ? null : localizeFailure(l10n, failure),
          captionIsError: failure != null,
          child: FilledButton(
            onPressed: state.submitting ? null : context.read<OnboardingCubit>().finish,
            child: state.submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : Text(l10n.finishOnboarding),
          ),
        ),
      ],
    );
  }
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
