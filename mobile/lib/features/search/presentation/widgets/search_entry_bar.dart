import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../search_routes.dart';

/// The search bar (F16): looks like the search box and opens the search screen, where the typing happens. [pill] is
/// the shorter, fully rounded one in the tabs' top bar.
class SearchEntryBar extends StatelessWidget {
  const SearchEntryBar({super.key, this.pill = false});

  static const height = 48.0;

  /// The top bar's height for it.
  static const pillHeight = 40.0;

  final bool pill;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final ShapeBorder shape = pill
        ? const StadiumBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReadInRadius.md), side: BorderSide(color: colors.border));
    return Semantics(
      button: true,
      label: l10n.searchHint,
      excludeSemantics: true,
      onTap: () => _open(context),
      child: Material(
        // The pill is a well of the canvas in the white top bar (it shows in dark mode too).
        color: pill ? colors.bg : colors.surfaceVariant,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('search-entry'),
          onTap: () => _open(context),
          customBorder: shape,
          child: SizedBox(
            height: pill ? pillHeight : height,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: pill ? ReadInSpace.s3 : ReadInSpace.s4),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: colors.textSecondary, size: pill ? 20 : 24),
                  SizedBox(width: pill ? ReadInSpace.s2 : ReadInSpace.s3),
                  Expanded(
                    child: Text(
                      pill ? l10n.searchPillHint : l10n.searchHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _open(BuildContext context) => unawaited(GoRouter.maybeOf(context)?.push<void>(SearchRoutes.path));
}
