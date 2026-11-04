import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/app_settings.dart';
import '../cubit/settings_cubit.dart';

/// Says how saving a preference to the account went (F18, as the web does): why it failed, and "Settings saved ✓"
/// for the account-only ones when [confirm] is set.
Future<void> _report(BuildContext context, Future<Failure?> change, {bool confirm = false}) async {
  final failure = await change;
  if (!context.mounted) return;
  if (failure != null) return showActionFailure(context, failure);
  if (confirm) showActionMessage(context, context.l10n.settingsSaved);
}

/// Labeled section used by settings and onboarding.
class PreferenceSection extends StatelessWidget {
  const PreferenceSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.textTheme.labelMedium?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: ReadInSpace.s2),
          child,
        ],
      );
}

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.select((SettingsCubit c) => c.state.theme);
    return PreferenceSection(
      title: l10n.theme,
      child: SegmentedButton<ThemePreference>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: ThemePreference.system, label: Text(l10n.themeSystem), icon: const Icon(Icons.brightness_auto_outlined)),
          ButtonSegment(value: ThemePreference.light, label: Text(l10n.themeLight), icon: const Icon(Icons.light_mode_outlined)),
          ButtonSegment(value: ThemePreference.dark, label: Text(l10n.themeDark), icon: const Icon(Icons.dark_mode_outlined)),
        ],
        selected: {theme},
        onSelectionChanged: (v) => _report(context, context.read<SettingsCubit>().setTheme(v.first)),
      ),
    );
  }
}

class UiLanguageSelector extends StatelessWidget {
  const UiLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.select((SettingsCubit c) => c.state.uiLanguage);
    return PreferenceSection(
      title: l10n.uiLanguage,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'ar', label: Text(l10n.languageArabic)),
          ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
        ],
        selected: {language},
        onSelectionChanged: (v) => _report(context, context.read<SettingsCubit>().setUiLanguage(v.first)),
      ),
    );
  }
}

/// `مصري + English` / `English only` (F02 step 3, F18). It lives on the account: disabled for guests (Settings says
/// to sign in).
class ArticleLanguageSelector extends StatelessWidget {
  const ArticleLanguageSelector({super.key, this.confirmSaved = false});

  /// Says "Settings saved ✓" once the account has it (Settings; onboarding stays quiet).
  final bool confirmSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.select((SettingsCubit c) => c.state.articleLanguage);
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    final cubit = context.read<SettingsCubit>();
    Widget option(String value, String label) => RadioListTile<String>(
          value: value,
          title: Text(label),
          contentPadding: EdgeInsets.zero,
          enabled: signedIn,
        );
    return PreferenceSection(
      title: l10n.articleLanguageLabel,
      child: RadioGroup<String>(
        groupValue: language,
        onChanged: (v) {
          if (v != null && signedIn) unawaited(_report(context, cubit.setArticleLanguage(v), confirm: confirmSaved));
        },
        child: Column(children: [option('ar-EG', l10n.articleLangArEg), option('en', l10n.articleLangEn)]),
      ),
    );
  }
}

/// The daily article's reminder time (F17, F18): on the account, so disabled for guests.
class ReminderTimeTile extends StatelessWidget {
  const ReminderTimeTile({super.key, this.confirmSaved = false});

  /// See [ArticleLanguageSelector.confirmSaved].
  final bool confirmSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = context.select((SettingsCubit c) => c.state.reminderTime);
    final signedIn = context.select((SessionCubit c) => c.state.isAuthenticated);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: signedIn,
      leading: const Icon(Icons.schedule_rounded),
      title: Text(l10n.reminderTimeLabel),
      trailing: Text(value, textDirection: TextDirection.ltr, style: context.textTheme.titleSmall),
      onTap: () async {
        final cubit = context.read<SettingsCubit>();
        final picked = await showTimePicker(context: context, initialTime: SettingsCubit.parseTime(value));
        if (picked != null && context.mounted) await _report(context, cubit.setReminderTime(picked), confirm: confirmSaved);
      },
    );
  }
}

class FontSizeSelector extends StatelessWidget {
  const FontSizeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = context.select((SettingsCubit c) => c.state.fontSize);
    return PreferenceSection(
      title: l10n.fontSize,
      child: SegmentedButton<ArticleFontSize>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: ArticleFontSize.s, label: Text(l10n.fontSizeS)),
          ButtonSegment(value: ArticleFontSize.m, label: Text(l10n.fontSizeM)),
          ButtonSegment(value: ArticleFontSize.l, label: Text(l10n.fontSizeL)),
          ButtonSegment(value: ArticleFontSize.xl, label: Text(l10n.fontSizeXl)),
        ],
        selected: {size},
        onSelectionChanged: (v) => context.read<SettingsCubit>().setFontSize(v.first),
      ),
    );
  }
}
