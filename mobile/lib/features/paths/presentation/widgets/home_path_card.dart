import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/bidi_text.dart';
import '../../../../shared/widgets/page_block.dart';
import '../../domain/entities/learning_path.dart';
import 'path_widgets.dart';

/// The Home learning path card (F03, F09): the enrolled path in progress with "{readCount}/{total}", and its next
/// article as the primary action. Tapping the card opens the path page. A full-width block on the canvas (F34).
class ActivePathCard extends StatelessWidget {
  const ActivePathCard({super.key, required this.path, required this.onOpenPath, required this.onOpenNext});

  final LearningPath path;
  final VoidCallback onOpenPath;
  final ValueChanged<PathArticleRef> onOpenNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final progress = path.progress;
    final next = progress?.next;
    return PageBlock(
      child: InkWell(
        onTap: onOpenPath,
        child: Padding(
          padding: const EdgeInsets.all(PageBlock.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox.square(dimension: 48, child: PathCover(path: path, iconSize: 24)),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.pathsTitle,
                          style: context.textTheme.labelSmall?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        BidiText(path.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: ReadInSpace.s2),
                  InfoTag(label: path.field.nameFor(lang)),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: ReadInSpace.s3),
                PathProgressRow(progress: progress),
              ],
              if (next != null) ...[
                const SizedBox(height: ReadInSpace.s3),
                FilledButton.tonalIcon(
                  onPressed: () => onOpenNext(next),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(l10n.pathNext(isolateTitle(next.title)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The slim "learn step by step with learning paths" row: Home without a path in progress, and guests. A full-width
/// block on the canvas, the whole row one link.
class PathsPromptRow extends StatelessWidget {
  const PathsPromptRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PageBlock(
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: PageBlock.gutter, vertical: ReadInSpace.s3),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(ReadInRadius.md)),
                child: Icon(Icons.route_rounded, size: 20, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: ReadInSpace.s3),
              Expanded(
                child: Text(
                  context.l10n.pathsPrompt,
                  style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
