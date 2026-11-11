import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../admin/presentation/widgets/admin_entry.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/cubit/linked_accounts_cubit.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../blocks/presentation/pages/blocked_page.dart';
import '../../../devotions/presentation/pages/devotions_page.dart' show DevotionsEntryTile;
import '../../../highlights/presentation/widgets/show_highlights_switch.dart';
import '../../../legal/presentation/widgets/legal_links.dart';
import '../../../moderation/presentation/cubit/moderation_summary_cubit.dart';
import '../../../moderation/presentation/widgets/moderation_entry_tile.dart';
import '../../../mutes/presentation/pages/muted_page.dart';
import '../../../notifications/presentation/pages/notification_settings_page.dart';
import '../../../profile/presentation/cubit/privacy_cubit.dart';
import '../../../profile/presentation/widgets/public_reading_stats_switch.dart';
import '../../../support/presentation/pages/support_page.dart' show SupportEntryTile;
import '../../../verification/presentation/cubit/verification_cubit.dart';
import '../../../verification/presentation/widgets/verification_entry_tile.dart';
import '../widgets/account_section.dart';
import '../widgets/preference_tiles.dart';
import '../widgets/settings_block.dart';
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

    // A choice with its label (segments, radios): room above and below, as a row of the block.
    Widget choice(Widget child) => Padding(padding: const EdgeInsets.symmetric(vertical: ReadInSpace.s3), child: child);
    Widget note(String text) => Padding(
          padding: const EdgeInsets.only(bottom: ReadInSpace.s3),
          child: Text(text, style: context.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      // LinkedIn-like: a white block per section on the canvas, its title inside, its rows split by dividers.
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: ReadInSpace.s6),
        children: [
          // The admin console first, for holders of admin.access (F23); it replaces Moderation for them.
          if (session.me?.isAdmin ?? false) const SettingsBlock(rows: [AdminConsoleEntryTile()]),
          // The private corner (F38): the SuperAdmin's alone.
          if (session.me?.canUseDevotions ?? false) const SettingsBlock(rows: [DevotionsEntryTile()]),
          SettingsBlock(title: l10n.appearance, rows: [choice(const ThemeSelector()), choice(const UiLanguageSelector())]),
          SettingsBlock(
            title: l10n.reading,
            // The article language and the reminder live on the account (F18).
            note: session.isAuthenticated ? null : note(l10n.settingsSignInForSync),
            rows: [
              choice(const ArticleLanguageSelector(confirmSaved: true)),
              choice(const FontSizeSelector()),
              const ReminderTimeTile(confirmSaved: true),
              // Highlights in the reader (F30): guests too, kept on the device.
              const ShowHighlightsSwitch(),
              // Fields and topics followed after onboarding (F02, F12).
              if (session.isAuthenticated) const _InterestsEntry(),
              // The writers, fields and topics muted from an article's "⋯" (F28), next to what you follow.
              if (session.isAuthenticated) const _MutedEntry(),
            ],
          ),
          // Per-type modes and quiet hours live on the account (F17).
          if (session.isAuthenticated) SettingsBlock(title: l10n.notifications, rows: const [_NotificationSettingsEntry()]),
          if (session.isAuthenticated)
            SettingsBlock(
              title: l10n.profilePrivacy,
              rows: [
                const PublicReadingStatsSwitch(),
                choice(const WhoCanMentionSelector()),
                // Settings → Blocked accounts (F18, F36).
                const _BlockedEntry(),
              ],
            ),
          if (session.isAuthenticated) SettingsBlock(title: l10n.settingsWriting, rows: const [VerificationEntryTile()]),
          // A moderator without the console (a staff role, later) keeps the queue here (F22).
          if ((session.me?.isModerator ?? false) && !(session.me?.isAdmin ?? false))
            SettingsBlock(title: l10n.moderationTitle, rows: const [ModerationEntryTile()]),
          // Help & support (F35): new tickets and My tickets.
          if (session.me?.canContactSupport ?? false) SettingsBlock(title: l10n.supportHelpTitle, rows: const [SupportEntryTile()]),
          SettingsBlock(
            key: _accountKey,
            title: l10n.account,
            note: session.isAuthenticated ? null : note(l10n.guestMode),
            rows: [
              if (session.isAuthenticated)
                const AccountSection()
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: ReadInSpace.s3),
                  child: FilledButton(onPressed: () => context.push('/auth/sign-in'), child: Text(l10n.signIn)),
                ),
            ],
          ),
          // Settings → Legal (F18, F37): the Terms of Use, the Community Guidelines and the Privacy Policy, for everyone.
          SettingsBlock(title: l10n.legalTitle, rows: const [LegalLinkTiles()]),
        ],
      ),
    );
  }
}

/// Settings → Blocked accounts (F18, F36).
class _BlockedEntry extends StatelessWidget {
  const _BlockedEntry();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      key: const ValueKey('settings-blocked'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.block_outlined),
      title: Text(l10n.blockedTitle),
      subtitle: Text(l10n.blockedSettingsHint),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(BlockedPage.path),
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
