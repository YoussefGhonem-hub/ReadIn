import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../auth/presentation/cubit/linked_accounts_cubit.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../profile/presentation/cubit/privacy_cubit.dart';
import '../../../profile/presentation/widgets/public_reading_stats_switch.dart';
import '../widgets/account_section.dart';
import '../widgets/preference_tiles.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<LinkedAccountsCubit>()..load()),
          BlocProvider(create: (_) => getIt<PrivacyCubit>()),
        ],
        child: const SettingsView(),
      );
}

/// Settings (F18): appearance, languages, reading, privacy, account (phone, password, PIN, linked accounts, sign out,
/// delete).
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<SessionCubit>().state;

    Widget card(String title, List<Widget> children) => Padding(
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
        padding: const EdgeInsets.all(ReadInSpace.s4),
        children: [
          card(l10n.appearance, const [ThemeSelector(), SizedBox(height: ReadInSpace.s5), UiLanguageSelector()]),
          card(l10n.reading, const [
            ArticleLanguageSelector(),
            SizedBox(height: ReadInSpace.s4),
            FontSizeSelector(),
            SizedBox(height: ReadInSpace.s3),
            ReminderTimeTile(),
            DailyNotificationTile(),
          ]),
          // "Who can mention me" joins this card with comments (F11).
          if (session.isAuthenticated) card(l10n.profilePrivacy, const [PublicReadingStatsSwitch()]),
          card(l10n.account, [
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
