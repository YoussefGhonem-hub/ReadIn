import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/push/push_platform.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/entities/app_settings.dart';
import '../cubit/settings_cubit.dart';

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
        onSelectionChanged: (v) => context.read<SettingsCubit>().setTheme(v.first),
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
        onSelectionChanged: (v) => context.read<SettingsCubit>().setUiLanguage(v.first),
      ),
    );
  }
}

/// `مصري + English` / `English only` (F02 step 3, F18).
class ArticleLanguageSelector extends StatelessWidget {
  const ArticleLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = context.select((SettingsCubit c) => c.state.articleLanguage);
    final cubit = context.read<SettingsCubit>();
    Widget option(String value, String label) => RadioListTile<String>(
          value: value,
          title: Text(label),
          contentPadding: EdgeInsets.zero,
        );
    return PreferenceSection(
      title: l10n.articleLanguageLabel,
      child: RadioGroup<String>(
        groupValue: language,
        onChanged: (v) {
          if (v != null) cubit.setArticleLanguage(v);
        },
        child: Column(children: [option('ar-EG', l10n.articleLangArEg), option('en', l10n.articleLangEn)]),
      ),
    );
  }
}

class ReminderTimeTile extends StatelessWidget {
  const ReminderTimeTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = context.select((SettingsCubit c) => c.state.reminderTime);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule_rounded),
      title: Text(l10n.reminderTimeLabel),
      trailing: Text(value, textDirection: TextDirection.ltr, style: context.textTheme.titleSmall),
      onTap: () async {
        final cubit = context.read<SettingsCubit>();
        final picked = await showTimePicker(context: context, initialTime: SettingsCubit.parseTime(value));
        if (picked != null) await cubit.setReminderTime(picked);
      },
    );
  }
}

/// Turning the switch on is where push permission is asked, in context (SPEC §21.1).
class DailyNotificationTile extends StatelessWidget {
  const DailyNotificationTile({super.key});

  static final _noPush = ValueNotifier(PushPermission.unsupported);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = context.select((SettingsCubit c) => c.state.dailyNotifications);
    final push = getIt.isRegistered<PushService>() ? getIt<PushService>() : null;
    return ValueListenableBuilder(
      valueListenable: push?.permission ?? _noPush,
      builder: (context, permission, _) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.notifications_active_outlined),
        title: Text(l10n.notificationsLabel),
        subtitle: switch (permission) {
          PushPermission.denied => Text(l10n.notificationsBlocked),
          PushPermission.granted => null,
          _ => Text(l10n.notificationsHint),
        },
        value: enabled,
        onChanged: (on) {
          unawaited(context.read<SettingsCubit>().setDailyNotifications(on));
          if (on && push != null) unawaited(push.enable());
        },
      ),
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
