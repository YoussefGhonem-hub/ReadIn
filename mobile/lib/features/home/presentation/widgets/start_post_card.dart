import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../auth/domain/entities/me.dart';
import '../../../editor/presentation/pages/my_articles_page.dart';

/// "Start a post" at the top of Home (signed-in writers): the avatar and a pill that opens the editor, then Photo, PDF
/// and Article. The editor has no way yet to open its image or PDF picker from a link, so all three open a new
/// article; the attachments are in its settings sheet (F26). It has no frame of its own: it sits in Home's first block
/// (a `PageBlock`), under the greeting.
class StartPostCard extends StatelessWidget {
  const StartPostCard({super.key, required this.me});

  final Me me;

  static void _openEditor(BuildContext context) =>
      unawaited(GoRouter.maybeOf(context)?.push<void>(EditorRoutes.newArticle));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final pill = StadiumBorder(side: BorderSide(color: colors.border));
    Widget action(String key, IconData icon, Color color, String label) => Expanded(
          child: TextButton.icon(
            key: ValueKey('start-post-$key'),
            onPressed: () => _openEditor(context),
            icon: Icon(icon, color: color, size: 22),
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            style: TextButton.styleFrom(
              foregroundColor: colors.textSecondary,
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s1),
              textStyle: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );
    return Column(
      key: const ValueKey('start-post'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ExcludeSemantics(child: UserAvatar(name: me.displayName, url: me.avatarUrl, size: 44)),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Semantics(
                button: true,
                label: l10n.startPostHint,
                excludeSemantics: true,
                child: Material(
                  color: colors.surface,
                  shape: pill,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const ValueKey('start-post-pill'),
                    onTap: () => _openEditor(context),
                    customBorder: pill,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s4),
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        l10n.startPostHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ReadInSpace.s1),
        Row(
          children: [
            action('photo', Icons.image_outlined, colors.calloutInfoAccent, l10n.startPostPhoto),
            action('pdf', Icons.picture_as_pdf_outlined, colors.calloutDangerAccent, l10n.startPostPdf),
            action('article', Icons.article_outlined, colors.calloutWarningAccent, l10n.startPostArticle),
          ],
        ),
      ],
    );
  }
}
