import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../moderation/presentation/widgets/moderation_flows.dart';
import '../../../moderation/presentation/widgets/report_sheet.dart';
import '../../../profile/presentation/widgets/profile_header.dart' show ProfileBioText;
import '../../domain/entities/article.dart';
import '../cubit/article_cubit.dart';

/// The items of the reader's "⋯" menu (SPEC F28). F28 adds show less, hide highlights, follow and mute here.
enum ArticleMenuItem { report, hide, unhide }

/// What [article]'s menu offers the viewer: readers and guests can report it (not their own article); moderators can
/// hide or unhide it. Guests get the sign-in prompt when they pick an item.
List<ArticleMenuItem> articleMenuItems({required bool own, required bool moderator, required bool hidden}) => [
      if (!own) ArticleMenuItem.report,
      if (moderator) hidden ? ArticleMenuItem.unhide : ArticleMenuItem.hide,
    ];

/// The reader action bar's "⋯" (F22, F28). Nothing when it has no item for the viewer. Hiding needs an
/// [ModerationActionCubit] and the [ArticleCubit] above (the reader provides them).
class ArticleMenuButton extends StatelessWidget {
  const ArticleMenuButton({super.key, required this.article});

  final ArticleDetails article;

  Future<void> _onSelected(BuildContext context, ArticleMenuItem item) async {
    final target = ModerationTargetRef.article(article.card.id);
    switch (item) {
      case ArticleMenuItem.report:
        await showReportSheet(context, target: target);
      case ArticleMenuItem.hide:
        final cubit = context.read<ArticleCubit>();
        // The moderator still sees it, now with the banner and the note they gave.
        if (await ModerationFlows.hideWithNote(context, target) case final note?) {
          cubit.setModeration(ArticleModeration(hiddenAt: DateTime.now().toUtc(), note: note.isEmpty ? null : note));
        }
      case ArticleMenuItem.unhide:
        final cubit = context.read<ArticleCubit>();
        if (await ModerationFlows.unhide(context, target)) cubit.setModeration(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final me = context.select((SessionCubit c) => c.state.me);
    final items = articleMenuItems(
      own: me != null && me.id == article.card.author?.id,
      moderator: me?.isModerator ?? false,
      hidden: article.isHidden,
    );
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<ArticleMenuItem>(
      tooltip: l10n.articleMenu,
      icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary),
      onSelected: (item) => unawaited(_onSelected(context, item)),
      itemBuilder: (context) => [
        for (final item in items) ...[
          // Moderator tools sit apart from the reader's items.
          if (item != items.first && item != ArticleMenuItem.report && items.contains(ArticleMenuItem.report))
            const PopupMenuDivider(),
          PopupMenuItem(value: item, child: _ArticleMenuLabel(item: item)),
        ],
      ],
    );
  }
}

class _ArticleMenuLabel extends StatelessWidget {
  const _ArticleMenuLabel({required this.item});

  final ArticleMenuItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (icon, text) = switch (item) {
      ArticleMenuItem.report => (Icons.flag_outlined, l10n.articleMenuReport),
      ArticleMenuItem.hide => (Icons.visibility_off_outlined, l10n.articleMenuHide),
      ArticleMenuItem.unhide => (Icons.visibility_outlined, l10n.articleMenuUnhide),
    };
    final color = item == ArticleMenuItem.report ? colors.error : colors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: ReadInSpace.s3),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}

/// "Hidden by moderators" above a hidden article, for its author and moderators (the only ones who can open it), with
/// the moderator's note when there is one (F22).
class HiddenArticleBanner extends StatelessWidget {
  const HiddenArticleBanner({super.key, required this.moderation});

  final ArticleModeration moderation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final note = moderation.note;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(ReadInSpace.s3),
        decoration: BoxDecoration(
          color: colors.calloutWarning,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          border: BorderDirectional(start: BorderSide(color: colors.calloutWarningAccent, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.visibility_off_outlined, size: 20, color: colors.calloutWarningAccent),
            const SizedBox(width: ReadInSpace.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.articleHiddenBannerTitle, style: context.textTheme.titleSmall?.copyWith(color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(l10n.articleHiddenBannerBody, style: context.textTheme.bodySmall?.copyWith(color: colors.textPrimary)),
                  if (note != null && note.trim().isNotEmpty) ...[
                    const SizedBox(height: ReadInSpace.s2),
                    Text(l10n.noticeNoteLabel, style: context.textTheme.labelSmall?.copyWith(color: colors.textSecondary)),
                    // The moderator's words in their own direction.
                    ProfileBioText(note, style: context.textTheme.bodySmall?.copyWith(color: colors.textPrimary, height: 1.5)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
