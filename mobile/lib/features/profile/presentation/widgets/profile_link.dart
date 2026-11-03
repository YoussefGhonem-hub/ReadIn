import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../profile_routes.dart';

/// Makes an author's name or avatar open their profile (F14). The look of [child] doesn't change; screen readers
/// hear the name as a link to the profile.
class ProfileLink extends StatelessWidget {
  const ProfileLink({super.key, required this.username, required this.child, this.beforeOpen});

  final String username;
  final Widget child;

  /// Runs first, e.g. closing the sheet the link is in.
  final VoidCallback? beforeOpen;

  void _open(BuildContext context) {
    // Taken before [beforeOpen]: closing a sheet takes this context out of the tree.
    final router = GoRouter.maybeOf(context);
    beforeOpen?.call();
    if (router != null) unawaited(router.push<void>(ProfileRoutes.of(username)));
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Semantics(
          link: true,
          hint: context.l10n.profileOpenHint,
          // Its own ink layer: the link also works where no Material is above (and paints nothing at rest).
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => _open(context),
              borderRadius: BorderRadius.circular(ReadInRadius.sm),
              child: child,
            ),
          ),
        ),
      );
}
