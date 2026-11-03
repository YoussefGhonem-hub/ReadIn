import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/presentation/session/session_cubit.dart';

/// Profile (F14). Phase 1 shows identity + settings entry; tabs (articles,
/// saved, paths, about) and stats arrive with their features.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = context.watch<SessionCubit>().state;
    final me = session.me;

    final Widget body;
    if (!session.isAuthenticated) {
      body = EmptyView(
        icon: Icons.person_outline_rounded,
        title: l10n.profileGuestTitle,
        body: l10n.profileGuestBody,
        action: Column(
          children: [
            FilledButton(onPressed: () => context.push('/auth/sign-up'), child: Text(l10n.signUp)),
            const SizedBox(height: ReadInSpace.s2),
            TextButton(onPressed: () => context.push('/auth/sign-in'), child: Text(l10n.signIn)),
          ],
        ),
      );
    } else if (me == null) {
      body = ErrorView(
        failure: session.failure ?? const Failure(FailureCodes.userNotSynced),
        onRetry: context.read<SessionCubit>().refresh,
      );
    } else {
      final bioDir = me.bio == null ? null : Bidi.detect(me.bio!);
      body = ListView(
        padding: const EdgeInsets.all(ReadInSpace.s5),
        children: [
          Row(
            children: [
              UserAvatar(name: me.displayName, url: me.avatarUrl, size: 72),
              const SizedBox(width: ReadInSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: BidiText(me.displayName, style: context.textTheme.titleLarge)),
                      if (me.isVerified) ...[const SizedBox(width: 6), const VerifiedMark(size: 18)],
                    ]),
                    Text('@${me.username}', textDirection: TextDirection.ltr, style: context.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (me.bio != null && me.bio!.isNotEmpty) ...[
            const SizedBox(height: ReadInSpace.s4),
            Text(
              Bidi.isolateOppositeRuns(me.bio!, bioDir ?? Directionality.of(context)),
              textDirection: bioDir,
              style: context.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: ReadInSpace.s4),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.editProfile),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoonTitle))),
          ),
          const SizedBox(height: ReadInSpace.s6),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(ReadInRadius.card),
              border: Border.all(color: context.colors.border),
            ),
            child: const ComingSoonView(icon: Icons.insights_outlined),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProfile),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: body,
    );
  }
}
