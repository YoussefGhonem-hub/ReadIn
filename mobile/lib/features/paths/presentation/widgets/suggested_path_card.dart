import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../domain/entities/learning_path.dart';
import 'path_widgets.dart';

/// "Suggested path" on Home (F03, F09): a published path the reader hasn't joined, with its cover, field, title and
/// "N articles · M min". The card and "Start path" open the path page, where joining happens; "See all" opens the
/// list of paths. A full-width block on the canvas, like the post cards around it (F34).
class SuggestedPathCard extends StatelessWidget {
  const SuggestedPathCard({super.key, required this.path, required this.onOpenPath, required this.onSeeAll});

  final LearningPath path;
  final VoidCallback onOpenPath;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    return PageBlock(
      key: ValueKey('suggested-path-${path.slug}'),
      child: InkWell(
        onTap: onOpenPath,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(PageBlock.gutter, ReadInSpace.s1, ReadInSpace.s1, ReadInSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.suggestedPathTitle,
                        style: context.textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('suggested-path-see-all'),
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                    child: Text(l10n.exploreSeeAll, semanticsLabel: l10n.exploreSeeAllSection(l10n.pathsTitle)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox.square(dimension: 64, child: PathCover(path: path, iconSize: 26)),
                    const SizedBox(width: ReadInSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoTag(label: path.field.nameFor(lang)),
                          const SizedBox(height: ReadInSpace.s1),
                          BidiText(
                            path.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 2),
                          PathMeta(path: path),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ReadInSpace.s3),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s3),
                child: FilledButton.tonalIcon(
                  key: const ValueKey('suggested-path-start'),
                  onPressed: onOpenPath,
                  icon: const Icon(Icons.route_rounded, size: 20),
                  label: Text(l10n.pathStart),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
