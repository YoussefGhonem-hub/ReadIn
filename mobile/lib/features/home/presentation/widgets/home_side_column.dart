import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../follow/presentation/widgets/suggested_writers.dart';
import '../../../profile/presentation/profile_routes.dart';
import '../../../reading/presentation/widgets/reading_summary.dart';
import 'me_sheet.dart';

/// Home's side column on wide screens (tablets, ≥ [width] + the feed): the profile card, this week's reading and
/// writers to follow. Guests get an invitation to sign in. Scrolls on its own, beside the feed.
class HomeSideColumn extends StatelessWidget {
  const HomeSideColumn({super.key});

  static const width = 340.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = context.select((SessionCubit c) => c.state.isAuthenticated ? c.state.me : null);
    Widget card(Widget child) => Card(child: Padding(padding: const EdgeInsets.all(ReadInSpace.s4), child: child));
    const gap = SizedBox(height: ReadInSpace.s3);
    return ListView(
      key: const ValueKey('home-side-column'),
      padding: const EdgeInsetsDirectional.fromSTEB(0, ReadInSpace.s4, ReadInSpace.s5, ReadInSpace.s5),
      children: me == null
          ? [
              card(Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.profileGuestTitle, style: context.textTheme.titleMedium),
                  const SizedBox(height: ReadInSpace.s1),
                  Text(l10n.profileGuestBody, style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: ReadInSpace.s4),
                  FilledButton(onPressed: () => context.push('/auth/sign-up'), child: Text(l10n.signUp)),
                  const SizedBox(height: ReadInSpace.s2),
                  OutlinedButton(onPressed: () => context.push('/auth/sign-in'), child: Text(l10n.signIn)),
                ],
              )),
            ]
          : [
              card(MeHeader(
                me: me,
                onViewProfile: () => unawaited(GoRouter.maybeOf(context)?.push<void>(ProfileRoutes.of(me.username))),
              )),
              gap,
              const ReadingSummary(),
              gap,
              card(const SuggestedWritersList()),
            ],
    );
  }
}
