import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/learning_path.dart';

/// [text] (an article or path title in either language) as one isolated run, so it can sit inside a sentence of the
/// other direction ("التالي: Intro to DI").
String isolateTitle(String text) => '${Bidi.fsi}$text${Bidi.pdi}';

/// A thin rounded progress bar on the theme's track color.
class PathProgressBar extends StatelessWidget {
  const PathProgressBar({super.key, required this.value, this.color, this.height = 6});

  /// 0–1.
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(value: value, minHeight: height, color: color, backgroundColor: context.colors.border),
      );
}

/// The bar and "readCount/total" of a path (signed in).
class PathProgressRow extends StatelessWidget {
  const PathProgressRow({super.key, required this.progress});

  final PathProgress progress;

  @override
  Widget build(BuildContext context) => Semantics(
        label: context.l10n.pathProgressSemantics(progress.readCount, progress.total),
        container: true,
        excludeSemantics: true,
        child: Row(
          children: [
            Expanded(child: PathProgressBar(value: progress.fraction)),
            const SizedBox(width: ReadInSpace.s2),
            Text(
              '${progress.readCount}/${progress.total}',
              textDirection: TextDirection.ltr,
              style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

/// "✓ Completed": `enrollment.completedAt` is set.
class PathCompletedBadge extends StatelessWidget {
  const PathCompletedBadge({super.key});

  @override
  Widget build(BuildContext context) =>
      InfoTag(label: context.l10n.pathCompleted, icon: Icons.check_rounded, tone: InfoTagTone.success);
}

/// "N articles · M min".
class PathMeta extends StatelessWidget {
  const PathMeta({super.key, required this.path, this.style});

  final LearningPath path;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Text(
      '${l10n.pathArticleCount(path.articleCount)}  ·  ${l10n.pathMinutes(path.readingTimeMinutes)}',
      style: style ?? context.textTheme.bodySmall,
    );
  }
}

/// A path's cover (its first article's), or a token-colored panel with the path icon when there is none. Fills its
/// box: give it a size.
class PathCover extends StatelessWidget {
  const PathCover({super.key, required this.path, this.radius = ReadInRadius.md, this.iconSize = 28});

  final LearningPath path;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = path.coverUrl;
    if (url != null) return AppNetworkImage(url: url, borderRadius: BorderRadius.circular(radius));
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(radius)),
      child: Center(child: Icon(Icons.route_rounded, size: iconSize, color: colors.onPrimaryContainer)),
    );
  }
}

/// A path in a list (`/paths`, a profile's Paths tab): cover, field, title, two lines of description, "N articles ·
/// M min", and for the signed-in viewer the progress and the completion badge.
class PathCardTile extends StatelessWidget {
  const PathCardTile({super.key, required this.path, required this.onTap});

  final LearningPath path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final colors = context.colors;
    final progress = path.progress;
    final description = path.description;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ReadInSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(dimension: 72, child: PathCover(path: path)),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: ReadInSpace.s1,
                          runSpacing: ReadInSpace.s1,
                          children: [
                            InfoTag(label: path.field.nameFor(lang)),
                            if (path.isCompleted) const PathCompletedBadge(),
                          ],
                        ),
                        const SizedBox(height: ReadInSpace.s1),
                        BidiText(path.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall?.copyWith(height: 1.5)),
                        if (description != null) ...[
                          const SizedBox(height: 2),
                          BidiText(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                          ),
                        ],
                        const SizedBox(height: ReadInSpace.s1),
                        PathMeta(path: path),
                      ],
                    ),
                  ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: ReadInSpace.s3),
                PathProgressRow(progress: progress),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Card placeholders while a list of paths loads.
class PathListSkeleton extends StatelessWidget {
  const PathListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: ReadInSpace.s3),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(ReadInSpace.s4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 72, height: 72, radius: ReadInRadius.md),
                      SizedBox(width: ReadInSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 70),
                            SizedBox(height: ReadInSpace.s2),
                            SkeletonBox(),
                            SizedBox(height: ReadInSpace.s2),
                            SkeletonBox(width: 140),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}

/// The field chips of a path list ("All" first), built from the fields present in it. Hidden with fewer than two
/// fields: there would be nothing to filter.
class PathFieldChips extends StatelessWidget {
  const PathFieldChips({super.key, required this.fields, required this.selected, required this.onSelected});

  final List<FieldRef> fields;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (fields.length < 2) return const SizedBox(height: ReadInSpace.s3);
    final lang = Localizations.localeOf(context).languageCode;
    final colors = context.colors;

    Widget chip(String label, String? slug) {
      final isSelected = selected == slug;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: ReadInSpace.s2),
        child: ChoiceChip(
          label: BidiText(label),
          selected: isSelected,
          onSelected: (_) => onSelected(slug),
          selectedColor: colors.primary,
          labelStyle: context.textTheme.labelMedium?.copyWith(
            color: isSelected ? colors.onPrimary : colors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(color: isSelected ? colors.primary : colors.border),
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s5, vertical: ReadInSpace.s3),
        children: [
          chip(context.l10n.filterAll, null),
          for (final field in fields) chip(field.nameFor(lang), field.slug),
        ],
      ),
    );
  }
}
