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
import '../../../moderation/presentation/cubit/moderation_summary_cubit.dart';
import '../../../moderation/presentation/widgets/moderation_entry_tile.dart';
import '../../../notifications/presentation/pages/notification_settings_page.dart';
import '../../../profile/presentation/cubit/privacy_cubit.dart';
import '../../../profile/presentation/widgets/public_reading_stats_switch.dart';
import '../widgets/account_section.dart';
import '../widgets/preference_tiles.dart';

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
        ],
        child: SettingsView(section: section),
      );
}

/// Settings (F18): appearance, languages, reading, notifications (F17), privacy, moderation (moderators only, F22),
/// account (phone, password, PIN, linked accounts, sign out, delete).
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
          card(l10n.reading, const [
            ArticleLanguageSelector(),
            SizedBox(height: ReadInSpace.s4),
            FontSizeSelector(),
            SizedBox(height: ReadInSpace.s3),
            ReminderTimeTile(),
          ]),
          // Per-type modes and quiet hours live on the account (F17).
          if (session.isAuthenticated) card(l10n.notifications, const [_NotificationSettingsEntry()]),
          // "Who can mention me" joins this card with comments (F11).
          if (session.isAuthenticated) card(l10n.profilePrivacy, const [PublicReadingStatsSwitch()]),
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
