import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/cubit/linked_accounts_cubit.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../highlights/presentation/widgets/show_highlights_switch.dart';
import '../../../moderation/presentation/cubit/moderation_summary_cubit.dart';
import '../../../moderation/presentation/widgets/moderation_entry_tile.dart';
import '../../../mutes/presentation/pages/muted_page.dart';
import '../../../notifications/presentation/pages/notification_settings_page.dart';
import '../../../profile/presentation/cubit/privacy_cubit.dart';
import '../../../profile/presentation/widgets/public_reading_stats_switch.dart';
import '../../../verification/presentation/cubit/verification_cubit.dart';
import '../../../verification/presentation/widgets/verification_entry_tile.dart';
import '../widgets/account_section.dart';
import '../widgets/preference_tiles.dart';
import '../widgets/who_can_mention_selector.dart';
import 'interests_page.dart';

/// A part of Settings a link can open at (`/settings?section=account`, e.g. a security alert, F17).
enum SettingsSection {
  account;

  static SettingsSection? fromQuery(Uri uri) =>
      SettingsSection.values.where((section) => section.name == uri.queryParameters['section']).firstOrNull;
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.section});

  final SettingsSection? section;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<LinkedAccountsCubit>()..load()),
          BlocProvider(create: (_) => getIt<PrivacyCubit>()),
          // App-wide (the actions keep it current); read only by moderators' Moderation entry (F22).
          BlocProvider.value(value: getIt<ModerationSummaryCubit>()),
          // Created (and loaded) when the signed-in-only Writer verification row is built (F19).
          BlocProvider(create: (_) => getIt<VerificationCubit>()..load()),
        ],
        child: SettingsView(section: section),
      );
}

/// Settings (F18): appearance, languages, reading, notifications (F17), privacy, writer verification (F19), moderation
/// (moderators only, F22), account (phone, password, PIN, linked accounts, sign out, delete).
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, this.section});

  /// Scrolled into view once the page is shown.
  final SettingsSection? section;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _scroll = ScrollController();
  final _accountKey = GlobalKey();
  int _revealTries = 0;

  @override
  void initState() {
    super.initState();
    if (widget.section == SettingsSection.account) WidgetsBinding.instance.addPostFrameCallback((_) => _revealAccount());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The list builds lazily: scroll down until the Account card exists, then bring it to the top.
  void _revealAccount() {
    if (!mounted) return;
    final target = _accountKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, duration: Duration.zero);
      return;
    }
    if (!_scroll.hasClients || _revealTries++ > 5) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealAccount());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<SessionCubit>().state;

    Widget card(String title, List<Widget> children, {Key? key}) => Padding(
          key: key,
          padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(ReadInSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: context.textTheme.titleMedium),
                  const SizedBox(height: ReadInSpace.s4),
                  ...children,
                ],
              ),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(ReadInSpace.s4),
        children: [
          card(l10n.appearance, const [ThemeSelector(), SizedBox(height: ReadInSpace.s5), UiLanguageSelector()]),
          card(l10n.reading, [
            // The article language and the reminder live on the account (F18).
            if (!session.isAuthenticated) ...[
              Text(l10n.settingsSignInForSync, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
              const SizedBox(height: ReadInSpace.s3),
            ],
            const ArticleLanguageSelector(confirmSaved: true),
            const SizedBox(height: ReadInSpace.s4),
            const FontSizeSelector(),
            const SizedBox(height: ReadInSpace.s3),
            const ReminderTimeTile(confirmSaved: true),
            // Highlights in the reader (F30): guests too, kept on the device.
            const ShowHighlightsSwitch(),
            // Fields and topics followed after onboarding (F02, F12).
            if (session.isAuthenticated) const _InterestsEntry(),
            // The writers, fields and topics muted from an article's "⋯" (F28), next to what you follow.
            if (session.isAuthenticated) const _MutedEntry(),
          ]),
          // Per-type modes and quiet hours live on the account (F17).
          if (session.isAuthenticated) card(l10n.notifications, const [_NotificationSettingsEntry()]),
          if (session.isAuthenticated)
            card(l10n.profilePrivacy, const [
              PublicReadingStatsSwitch(),
              SizedBox(height: ReadInSpace.s3),
              WhoCanMentionSelector(),
            ]),
          if (session.isAuthenticated) card(l10n.settingsWriting, const [VerificationEntryTile()]),
          if (session.me?.isModerator ?? false) card(l10n.moderationTitle, const [ModerationEntryTile()]),
          card(key: _accountKey, l10n.account, [
            if (session.isAuthenticated)
              const AccountSection()
            else ...[
              Text(l10n.guestMode, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
              const SizedBox(height: ReadInSpace.s4),
              FilledButton(onPressed: () => context.push('/auth/sign-in'), child: Text(l10n.signIn)),
            ],
          ]),
        ],
      ),
    );
  }
}

class _InterestsEntry extends StatelessWidget {
  const _InterestsEntry();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.interests_outlined),
      title: Text(l10n.settingsInterests),
      subtitle: Text(l10n.settingsInterestsHint),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(InterestsPage.path),
    );
  }
}

/// Settings → Muted (F18, F28).
class _MutedEntry extends StatelessWidget {
  const _MutedEntry();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      key: const ValueKey('settings-muted'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.volume_off_outlined),
      title: Text(l10n.muteSettingsEntry),
      subtitle: Text(l10n.muteSettingsEntryHint),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(MutedPage.path),
    );
  }
}

class _NotificationSettingsEntry extends StatelessWidget {
  const _NotificationSettingsEntry();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.notifications_active_outlined),
      title: Text(l10n.notificationSettings),
      subtitle: Text(l10n.notificationSettingsEntryHint),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(NotificationSettingsPage.path),
    );
  }
}
