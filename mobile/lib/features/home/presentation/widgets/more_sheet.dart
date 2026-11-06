import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../auth/domain/entities/me.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../moderation/presentation/moderation_routes.dart';
import '../../../mutes/presentation/pages/muted_page.dart';
import '../../../notifications/presentation/cubit/unread_badge_cubit.dart';
import '../../../paths/presentation/path_routes.dart';
import '../../../reading/presentation/pages/reading_stats_page.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/pages/interests_page.dart';
import '../../../verification/presentation/pages/verification_page.dart';

/// Opens the More sheet ("المزيد") from the bottom bar. The sheet lives on the root navigator, so the session, the
/// settings and the unread count ([unread], when there is one) are handed over from [context].
Future<void> showMoreSheet(BuildContext context, {UnreadBadgeCubit? unread}) {
  final session = context.read<SessionCubit>();
  final settings = context.read<SettingsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: session),
        BlocProvider.value(value: settings),
        if (unread != null) BlocProvider.value(value: unread),
      ],
      child: const MoreSheet(),
    ),
  );
}

/// "More": who is signed in (a tap opens their profile), the app's language and dark mode right at hand, then the
/// other screens as a grid: Profile, Notifications (with the unread count), My paths, Reading stats, Interests,
/// Muted, Writer verification (until verified), Moderation (`moderation.manage` only) and Settings; Sign out last.
/// Guests get Create account / Sign in, the language, dark mode and Settings.
class MoreSheet extends StatelessWidget {
  const MoreSheet({super.key});

  static const _padding = EdgeInsets.symmetric(horizontal: ReadInSpace.s5);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = context.select((SessionCubit c) => c.state.isAuthenticated ? c.state.me : null);
    final tiles = <_Shortcut>[
      if (me != null) ...[
        _Shortcut('profile', Icons.person_outline_rounded, l10n.navProfile, _Tint.primary, '/profile', tab: true),
        _Shortcut('notifications', Icons.notifications_none_rounded, l10n.notifications, _Tint.amber, '/notifications'),
        _Shortcut('paths', Icons.route_outlined, l10n.pathsTabMine, _Tint.blue, PathRoutes.mine),
        _Shortcut('stats', Icons.insights_rounded, l10n.readingStatsTitle, _Tint.green, ReadingStatsPage.path),
        _Shortcut('interests', Icons.interests_outlined, l10n.settingsInterests, _Tint.rose, InterestsPage.path),
        _Shortcut('muted', Icons.volume_off_outlined, l10n.muteSettingsEntry, _Tint.neutral, MutedPage.path),
        if (!me.isVerified)
          _Shortcut('verification', Icons.verified_outlined, l10n.verificationTitle, _Tint.blue, VerificationPage.path),
        if (me.isModerator)
          _Shortcut('moderation', Icons.shield_outlined, l10n.moderationTitle, _Tint.rose, ModerationRoutes.home),
      ],
      _Shortcut('settings', Icons.settings_outlined, l10n.settings, _Tint.neutral, '/settings'),
    ];
    return SingleChildScrollView(
      key: const ValueKey('more-sheet'),
      padding: const EdgeInsets.only(bottom: ReadInSpace.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: _padding,
            child: me == null ? const _GuestHeader() : _MeCard(me: me),
          ),
          const SizedBox(height: ReadInSpace.s4),
          const Padding(padding: _padding, child: _QuickSettings()),
          const SizedBox(height: ReadInSpace.s4),
          Padding(
            padding: _padding,
            child: _ShortcutGrid(tiles: tiles),
          ),
          if (me != null) ...[
            const SizedBox(height: ReadInSpace.s3),
            Padding(
              padding: _padding,
              child: TextButton.icon(
                key: const ValueKey('more-sign-out'),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.error,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  final session = context.read<SessionCubit>();
                  Navigator.of(context).pop();
                  unawaited(session.signOut());
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.signOut),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Closes the sheet, then opens [location] over the current screen, or switches to that tab ([tab]).
  static void go(BuildContext context, String location, {bool tab = false}) {
    // Taken first: closing the sheet takes this context out of the tree.
    final router = GoRouter.maybeOf(context);
    Navigator.of(context).pop();
    if (router == null) return;
    if (tab) {
      router.go(location);
    } else {
      unawaited(router.push<void>(location));
    }
  }
}

/// The signed-in user on a soft green card: avatar, name (with the Verified badge) and @username; a tap opens their
/// profile.
class _MeCard extends StatelessWidget {
  const _MeCard({required this.me});

  final Me me;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(ReadInRadius.card);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [colors.primaryContainer, colors.surfaceVariant],
          ),
        ),
        child: InkWell(
          key: const ValueKey('more-profile-card'),
          borderRadius: radius,
          onTap: () => MoreSheet.go(context, '/profile', tab: true),
          child: Padding(
            padding: const EdgeInsets.all(ReadInSpace.s4),
            child: Row(
              children: [
                UserAvatar(name: me.displayName, url: me.avatarUrl, size: 52),
                const SizedBox(width: ReadInSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: BidiText(
                              me.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (me.isVerified) ...[const SizedBox(width: 4), const VerifiedMark(size: 16)],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Bidi.ltrIsolate('@${me.username}'),
                        style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const GenericAvatar(size: 52),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.profileGuestTitle, style: context.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    l10n.profileGuestBody,
                    style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ReadInSpace.s3),
        Row(
          children: [
            Expanded(
              child: FilledButton(onPressed: () => MoreSheet.go(context, '/auth/sign-up'), child: Text(l10n.signUp)),
            ),
            const SizedBox(width: ReadInSpace.s2),
            Expanded(
              child: OutlinedButton(onPressed: () => MoreSheet.go(context, '/auth/sign-in'), child: Text(l10n.signIn)),
            ),
          ],
        ),
      ],
    );
  }
}

/// The app's language (العربية / English) and dark mode, changed in place: the sheet stays open and turns with them.
/// Both are saved like Settings saves them (on this device, and on the account when signed in).
class _QuickSettings extends StatelessWidget {
  const _QuickSettings();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final language = context.select((SettingsCubit c) => c.state.uiLanguage);
    // The theme on screen: the saved light or dark, or the platform's brightness for "system".
    final dark = Theme.of(context).brightness == Brightness.dark;
    Future<void> save(Future<Failure?> change) async {
      final failure = await change;
      if (context.mounted) showActionFailure(context, failure);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ReadInRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _SettingRow(
            icon: Icons.translate_rounded,
            tint: _Tint.blue,
            label: l10n.uiLanguage,
            trailing: _LanguageToggle(
              value: language,
              onChanged: (code) => unawaited(save(context.read<SettingsCubit>().setUiLanguage(code))),
            ),
          ),
          Divider(height: 1, indent: ReadInSpace.s4, endIndent: ReadInSpace.s4, color: colors.border),
          MergeSemantics(
            child: _SettingRow(
              icon: dark ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
              tint: _Tint.amber,
              label: l10n.moreDarkMode,
              trailing: Switch(
                key: const ValueKey('more-dark-mode'),
                value: dark,
                onChanged: (on) => unawaited(
                  save(context.read<SettingsCubit>().setTheme(on ? ThemePreference.dark : ThemePreference.light)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.tint, required this.label, required this.trailing});

  final IconData icon;
  final _Tint tint;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = tint.colors(context.colors);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: ReadInSpace.s4, end: ReadInSpace.s3),
        child: Row(
          children: [
            _IconBadge(icon: icon, background: background, foreground: foreground, size: 36),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Text(label, style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// العربية | English, the chosen one filled in green. Each name is written in its own language, so either reader
/// finds theirs.
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    Widget option(String code, String label) {
      final selected = value == code;
      return Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          key: ValueKey('more-language-$code'),
          borderRadius: BorderRadius.circular(ReadInRadius.chip),
          onTap: selected ? null : () => onChanged(code),
          child: AnimatedContainer(
            duration: ReadInMotion.base,
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(ReadInRadius.chip),
            ),
            child: Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: selected ? colors.onPrimary : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: colors.surfaceVariant, borderRadius: BorderRadius.circular(ReadInRadius.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [option('ar', l10n.languageArabic), option('en', l10n.languageEnglish)],
      ),
    );
  }
}

/// One of the grid's screens.
class _Shortcut {
  const _Shortcut(this.id, this.icon, this.label, this.tint, this.location, {this.tab = false});

  final String id;
  final IconData icon;
  final String label;
  final _Tint tint;
  final String location;

  /// A tab of the bottom bar's shell (switched to) rather than a screen opened over it.
  final bool tab;
}

/// The screens three to a row; the tiles of a row share its height (the tallest name sets it).
class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.tiles});

  final List<_Shortcut> tiles;

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < tiles.length; start += _columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: ReadInSpace.s3));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var column = 0; column < _columns; column++) ...[
                if (column > 0) const SizedBox(width: ReadInSpace.s3),
                Expanded(
                  child: start + column < tiles.length ? _ShortcutTile(tile: tiles[start + column]) : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.tile});

  final _Shortcut tile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = tile.tint.colors(colors);
    final unread = tile.id == 'notifications' ? context.select((UnreadBadgeCubit? c) => c?.state ?? 0) : 0;
    final radius = BorderRadius.circular(ReadInRadius.card);
    Widget icon = _IconBadge(icon: tile.icon, background: background, foreground: foreground, size: 44);
    if (unread > 0) {
      icon = Badge(label: Text(unread > 9 ? '9+' : '$unread'), child: icon);
    }
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('more-tile-${tile.id}'),
        onTap: () => MoreSheet.go(context, tile.location, tab: tile.tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2, vertical: ReadInSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: ReadInSpace.s2),
              Text(
                tile.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.background, required this.foreground, required this.size});

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Icon(icon, size: size * 0.5, color: foreground),
  );
}

/// The soft color pairs (background, icon) that tell the grid's screens apart, from the theme's callout tokens.
enum _Tint {
  primary,
  amber,
  blue,
  green,
  rose,
  neutral;

  (Color, Color) colors(ReadInColors c) => switch (this) {
    primary => (c.primaryContainer, c.onPrimaryContainer),
    amber => (c.accentContainer, c.calloutWarningAccent),
    blue => (c.calloutInfo, c.calloutInfoAccent),
    green => (c.calloutTip, c.calloutTipAccent),
    rose => (c.calloutDanger, c.calloutDangerAccent),
    neutral => (c.surfaceVariant, c.textSecondary),
  };
}
