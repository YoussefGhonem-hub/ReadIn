import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../auth/domain/entities/me.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../editor/presentation/pages/my_articles_page.dart';
import '../../../moderation/presentation/moderation_routes.dart';
import '../../../paths/presentation/path_routes.dart';
import '../../../profile/presentation/profile_routes.dart';
import '../../../reading/presentation/widgets/reading_summary.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/widgets/preference_tiles.dart';
import '../../../verification/presentation/pages/verification_page.dart';

/// Opens the "Me" sheet ("أنا") from the top bar's avatar. The sheet lives on the root navigator, so the session and
/// settings it reads are handed over from [context].
Future<void> showMeSheet(BuildContext context) {
  final session = context.read<SessionCubit>();
  final settings = context.read<SettingsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => MultiBlocProvider(
      providers: [BlocProvider.value(value: session), BlocProvider.value(value: settings)],
      child: const MeSheet(),
    ),
  );
}

/// "Me": who is signed in and a "View profile" button, this week's reading, Settings, My paths, My articles, writer
/// verification (until verified), Moderation (`moderation.manage` only), Appearance (light / dark / system) and Sign
/// out. Guests get Create account / Sign in, Settings and Appearance.
class MeSheet extends StatelessWidget {
  const MeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.select((SessionCubit c) => c.state.isAuthenticated ? c.state.me : null);
    return SingleChildScrollView(
      key: const ValueKey('me-sheet'),
      padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: me == null ? _guest(context) : _signedIn(context, me),
      ),
    );
  }

  static const _padding = EdgeInsets.symmetric(horizontal: ReadInSpace.s5);

  List<Widget> _signedIn(BuildContext context, Me me) {
    final l10n = context.l10n;
    return [
      Padding(
        padding: _padding,
        child: MeHeader(me: me, onViewProfile: () => _go(context, ProfileRoutes.of(me.username))),
      ),
      const SizedBox(height: ReadInSpace.s4),
      Padding(padding: _padding, child: ReadingSummary(beforeOpen: () => Navigator.of(context).pop())),
      const SizedBox(height: ReadInSpace.s3),
      const Divider(),
      _Item(icon: Icons.settings_outlined, label: l10n.settings, onTap: () => _go(context, '/settings')),
      _Item(icon: Icons.route_outlined, label: l10n.pathsTabMine, onTap: () => _go(context, PathRoutes.mine)),
      // The Write tab: switch to it rather than stack it.
      if (me.canWrite)
        _Item(
          icon: Icons.article_outlined,
          label: l10n.myArticlesTitle,
          onTap: () => _go(context, EditorRoutes.myArticles, tab: true),
        ),
      if (!me.isVerified)
        _Item(icon: Icons.verified_outlined, label: l10n.verificationTitle, onTap: () => _go(context, VerificationPage.path)),
      if (me.isModerator)
        _Item(icon: Icons.shield_outlined, label: l10n.moderationTitle, onTap: () => _go(context, ModerationRoutes.home)),
      const Divider(),
      const SizedBox(height: ReadInSpace.s3),
      const Padding(padding: _padding, child: ThemeSelector(key: ValueKey('me-appearance'))),
      const SizedBox(height: ReadInSpace.s3),
      const Divider(),
      _Item(
        key: const ValueKey('me-sign-out'),
        icon: Icons.logout_rounded,
        label: l10n.signOut,
        onTap: () {
          final session = context.read<SessionCubit>();
          Navigator.of(context).pop();
          unawaited(session.signOut());
        },
      ),
    ];
  }

  List<Widget> _guest(BuildContext context) {
    final l10n = context.l10n;
    return [
      Padding(
        padding: _padding,
        child: Row(
          children: [
            const GenericAvatar(size: 56),
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
      ),
      const SizedBox(height: ReadInSpace.s4),
      Padding(
        padding: _padding,
        child: FilledButton(onPressed: () => _go(context, '/auth/sign-up'), child: Text(l10n.signUp)),
      ),
      const SizedBox(height: ReadInSpace.s2),
      Padding(
        padding: _padding,
        child: OutlinedButton(onPressed: () => _go(context, '/auth/sign-in'), child: Text(l10n.signIn)),
      ),
      const SizedBox(height: ReadInSpace.s3),
      const Divider(),
      _Item(icon: Icons.settings_outlined, label: l10n.settings, onTap: () => _go(context, '/settings')),
      const Divider(),
      const SizedBox(height: ReadInSpace.s3),
      const Padding(padding: _padding, child: ThemeSelector(key: ValueKey('me-appearance'))),
    ];
  }

  /// Closes the sheet, then opens [location] over the current screen, or switches to that tab ([tab]).
  static void _go(BuildContext context, String location, {bool tab = false}) {
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

/// The avatar, name (with the Verified badge), @username and a line of bio, then "View profile": the Me sheet's
/// header, and the profile card of Home's side column on tablets.
class MeHeader extends StatelessWidget {
  const MeHeader({super.key, required this.me, required this.onViewProfile});

  final Me me;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bio = me.bio?.trim() ?? '';
    final bioDir = Bidi.detect(bio) ?? Directionality.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            UserAvatar(name: me.displayName, url: me.avatarUrl, size: 56),
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
                  Text(
                    Bidi.ltrIsolate('@${me.username}'),
                    style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                  ),
                  if (bio.isNotEmpty)
                    Text(
                      Bidi.isolateOppositeRuns(bio, bioDir),
                      textDirection: bioDir,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ReadInSpace.s3),
        OutlinedButton(
          key: const ValueKey('me-view-profile'),
          onPressed: onViewProfile,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 40),
            shape: const StadiumBorder(),
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.primary),
          ),
          child: Text(context.l10n.meViewProfile),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5),
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      );
}
