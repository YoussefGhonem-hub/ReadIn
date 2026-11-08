import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/moderation.dart';
import '../cubit/reported_content_cubit.dart';

/// Whether [card] is collapsed for the viewer (F22 store additions): they reported the article, or the repost that
/// placed it, before (`reportedByMe`) or in this session ([ReportedContentCubit]). Call it while building.
bool cardReportedByMe(BuildContext context, ArticleCard card) => context.select((ReportedContentCubit? c) {
      final article = c?.isReported(ModerationTargetType.article, card.id, fallback: card.reportedByMe) ?? card.reportedByMe;
      final repost = card.repostedBy;
      final repostId = repost?.repostId;
      if (article || repost == null || repostId == null) return article;
      return c?.isReported(ModerationTargetType.repost, repostId, fallback: repost.reportedByMe) ?? repost.reportedByMe;
    });

/// A card the viewer reported, folded to «أبلغت عن هذا المحتوى، ولن يظهر لك بعد الآن» with «عرض», which shows it here
/// only. It stays in its list (F22 store additions: hidden for the reporter at once, never for anyone else).
class ReportedCollapse extends StatefulWidget {
  const ReportedCollapse({super.key, required this.reported, required this.child});

  final bool reported;
  final Widget child;

  @override
  State<ReportedCollapse> createState() => _ReportedCollapseState();
}

class _ReportedCollapseState extends State<ReportedCollapse> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.reported || _shown) return widget.child;
    final l10n = context.l10n;
    final colors = context.colors;
    return Material(
      key: const ValueKey('reported-collapse'),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s3, ReadInSpace.s2, ReadInSpace.s3),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 20, color: colors.textSecondary),
            const SizedBox(width: ReadInSpace.s3),
            Expanded(
              child: Text(l10n.reportedHidden, style: context.textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
            ),
            TextButton(
              key: const ValueKey('reported-show'),
              onPressed: () => setState(() => _shown = true),
              child: Text(l10n.muteCommentShow),
            ),
          ],
        ),
      ),
    );
  }
}
