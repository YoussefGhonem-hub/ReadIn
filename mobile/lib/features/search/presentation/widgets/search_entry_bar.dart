import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../search_routes.dart';

/// Explore's search bar (F16): looks like the search box and opens the search screen, where the typing happens.
class SearchEntryBar extends StatelessWidget {
  const SearchEntryBar({super.key});

  static const height = 48.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ReadInRadius.md),
      side: BorderSide(color: colors.border),
    );
    return Semantics(
      button: true,
      label: l10n.searchHint,
      excludeSemantics: true,
      onTap: () => _open(context),
      child: Material(
        color: colors.surfaceVariant,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('search-entry'),
          onTap: () => _open(context),
          customBorder: shape,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: colors.textSecondary),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Text(
                      l10n.searchHint,
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
