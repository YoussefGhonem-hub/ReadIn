import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../moderation/presentation/widgets/moderation_labels.dart' show embedContent;
import '../../domain/entities/writer_category.dart';
import '../category_routes.dart';

/// The reader's "في قسم {name}" / "In {name}" under the byline (F31): a link to the writer's category page. The name
/// keeps its own direction inside the sentence.
class CategoryLink extends StatelessWidget {
  const CategoryLink({super.key, required this.username, required this.category});

  final String username;
  final WriterCategoryRef category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = context.l10n.articleInCategory(embedContent(category.name));
    void open() => unawaited(GoRouter.maybeOf(context)?.push<void>(CategoryRoutes.of(username, category.slug)));
    return Semantics(
      link: true,
      label: label,
      hint: context.l10n.categoryOpenHint,
      onTap: open,
      excludeSemantics: true,
      child: TextButton(
        key: const ValueKey('article-category-link'),
        onPressed: open,
        // It reads like a line of the byline: the ink is only as tall as the line (32 dp), and Material's padded tap
        // target gives a finger 48 dp around it (SPEC §26).
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s1),
          tapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ReadInRadius.sm)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 16, color: colors.primary),
            const SizedBox(width: ReadInSpace.s1),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
