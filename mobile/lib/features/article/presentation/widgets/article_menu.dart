import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../article_pdf/presentation/cubit/article_pdf_cubit.dart';
import '../../../article_pdf/presentation/widgets/article_pdf_widgets.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../../highlights/presentation/cubit/article_highlights_cubit.dart';
import '../../../moderation/domain/entities/moderation.dart';
import '../../../moderation/presentation/widgets/moderation_flows.dart';
import '../../../moderation/presentation/widgets/report_sheet.dart';
import '../../../mutes/presentation/cubit/mutes_cubit.dart';
import '../../../mutes/presentation/widgets/mute_actions.dart';
import '../../../mutes/presentation/widgets/mute_topics_sheet.dart';
import '../../../profile/presentation/widgets/profile_header.dart' show ProfileBioText;
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/article.dart';
import '../cubit/article_cubit.dart';

/// The items of an article's "⋯" menu (SPEC F28), in the order the menu shows them; moderator tools (F22) come last,
/// after a divider.
enum ArticleMenuItem {
  showLess,

  /// "إخفاء الـ Highlights" / "إظهار الـ Highlights" (F30): the reader, your own article too. No sign-in needed.
  highlights,
  follow,
  muteAuthor,
  muteTopics,

  /// "تحميل PDF" (F33): your own article, in the reader.
  downloadPdf,
  report,
  hide,
  unhide;

  /// Moderator tools (F22).
  bool get isModeration => this == hide || this == unhide;
}

/// What an article's menu offers the viewer, in the SPEC F28 order. Someone else's article: Show less, Follow author,
/// Mute author, Mute topics and Report (follow and mute need an author: a deleted account has none, [hasAuthor]).
/// Your own article: Mute topics, and in the reader ([pdf]) "تحميل PDF" (F33). Moderators can also hide or unhide it
/// (F22). Guests see the reader's items and get the sign-in prompt for every one of them, except Hide highlights. The
/// reader ([highlights]) has "إخفاء الـ Highlights" right after Show less (F30), on your own article too.
List<ArticleMenuItem> articleMenuItems({
  required bool own,
  required bool moderator,
  required bool hidden,
  bool hasAuthor = true,
  bool pdf = false,
  bool highlights = false,
}) =>
    [
      if (!own) ArticleMenuItem.showLess,
      if (highlights) ArticleMenuItem.highlights,
      if (!own && hasAuthor) ...[ArticleMenuItem.follow, ArticleMenuItem.muteAuthor],
      ArticleMenuItem.muteTopics,
      if (own && pdf) ArticleMenuItem.downloadPdf,
      if (!own) ArticleMenuItem.report,
      if (moderator) hidden ? ArticleMenuItem.unhide : ArticleMenuItem.hide,
    ];

/// The reader action bar's "⋯" (F22, F28). Hiding needs an [ModerationActionCubit] and the [ArticleCubit] above, and
/// "تحميل PDF" on your own article an [ArticlePdfCubit] (F33; the reader provides them all).
class ArticleMenuButton extends StatelessWidget {
  const ArticleMenuButton({super.key, required this.article});

  final ArticleDetails article;

  @override
  Widget build(BuildContext context) => ArticleMenuView(
        card: article.card,
        hidden: article.isHidden,
        // The moderator still sees it, now with the banner and the note they gave.
        onModerated: context.read<ArticleCubit>().setModeration,
      );
}

/// "⋯" for one article: the reader's ([ArticleMenuButton]) and the post card's header (F34), the same menu (F28).
/// Show less and Mute author confirm with Undo ([MuteActions]); Mute topics opens its sheet; Follow author uses
/// [FollowsCubit]. Hiding and unhiding need an [ModerationActionCubit] above; [onModerated] then gets the article's new
/// moderation (null once visible again). With an [ArticlePdfCubit] above (the reader, not a post card), your own
/// article also has "تحميل PDF" (F33): the version on screen, "بنجهز الـ PDF…" and disabled while it is built.
class ArticleMenuView extends StatelessWidget {
  const ArticleMenuView({super.key, required this.card, required this.hidden, required this.onModerated});

  final ArticleCard card;
  final bool hidden;
  final ValueChanged<ArticleModeration?> onModerated;

  Future<void> _onSelected(BuildContext context, ArticleMenuItem item) async {
    // Hide highlights works for guests too: their choice stays on the device (F30).
    if (item == ArticleMenuItem.highlights) {
      final settings = context.read<SettingsCubit>();
      final failure = await settings.setShowHighlights(!settings.state.showHighlights);
      if (context.mounted) showActionFailure(context, failure);
      return;
    }
    // Every other item needs an account (F28); moderators are signed in.
    if (!requireAccount(context)) return;
    final author = card.author;
    final target = ModerationTargetRef.article(card.id);
    switch (item) {
      case ArticleMenuItem.showLess:
        await MuteActions.showLess(context, card);
      case ArticleMenuItem.highlights:
        break;
      case ArticleMenuItem.follow:
        if (author == null) return;
        final failure = await context.read<FollowsCubit>().toggle(author.id, fallback: card.isFollowingAuthor);
        if (context.mounted) showActionFailure(context, failure);
      case ArticleMenuItem.muteAuthor:
        if (author == null) return;
        // On a muted writer's article (the reader) the item unmutes.
        if (context.read<MutesCubit>().state.isUserMuted(author.id, fallback: card.isAuthorMuted)) {
          await MuteActions.unmuteAuthor(context, userId: author.id, name: author.displayName);
        } else {
          await MuteActions.muteAuthor(context, author);
        }
      case ArticleMenuItem.muteTopics:
        await showMuteTopicsSheet(context, article: card);
      case ArticleMenuItem.downloadPdf:
        // The page's context, never the popup's: this menu's own button anchors the share sheet (iPad).
        await downloadArticlePdf(context, articleId: card.id, languages: [card.language]);
      case ArticleMenuItem.report:
        await showReportSheet(context, target: target);
      case ArticleMenuItem.hide:
        if (await ModerationFlows.hideWithNote(context, target) case final note?) {
          onModerated(ArticleModeration(hiddenAt: DateTime.now().toUtc(), note: note.isEmpty ? null : note));
        }
      case ArticleMenuItem.unhide:
        if (await ModerationFlows.unhide(context, target)) onModerated(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final me = context.select((SessionCubit c) => c.state.me);
    final authorId = card.author?.id;
    final following = context.select(
      (FollowsCubit? c) =>
          authorId != null && (c?.state.isFollowing(authorId, fallback: card.isFollowingAuthor) ?? card.isFollowingAuthor),
    );
    final authorMuted = context.select(
      (MutesCubit? c) => authorId != null && (c?.state.isUserMuted(authorId, fallback: card.isAuthorMuted) ?? card.isAuthorMuted),
    );
    // Null without an [ArticlePdfCubit] above: a post card's menu has no "تحميل PDF".
    final pdfBuilding = context.select((ArticlePdfCubit? c) => c?.state.isBuilding(card.id));
    // The reader's highlights (F30): only with an [ArticleHighlightsCubit] above, so not on a post card.
    final highlights = context.select((ArticleHighlightsCubit? c) => c != null);
    final highlightsShown = context.select((SettingsCubit? c) => c?.state.showHighlights ?? true);
    final items = articleMenuItems(
      own: me != null && me.id == authorId,
      moderator: me?.isModerator ?? false,
      hidden: hidden,
      hasAuthor: authorId != null,
      pdf: pdfBuilding != null,
      highlights: highlights,
    );
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<ArticleMenuItem>(
      tooltip: l10n.articleMenu,
      icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary),
      onSelected: (item) => unawaited(_onSelected(context, item)),
      itemBuilder: (context) => [
        for (final item in items) ...[
          // Moderator tools sit apart from the reader's items.
          if (item.isModeration && item != items.first) const PopupMenuDivider(),
          PopupMenuItem(
            value: item,
            // A PDF being built: "بنجهز الـ PDF…", and another tap does nothing.
            enabled: !(item == ArticleMenuItem.downloadPdf && pdfBuilding == true),
            child: _ArticleMenuLabel(
              item: item,
              following: me != null && following,
              authorMuted: me != null && authorMuted,
              pdfBuilding: pdfBuilding == true,
              highlightsShown: highlightsShown,
            ),
          ),
        ],
      ],
    );
  }
}

class _ArticleMenuLabel extends StatelessWidget {
  const _ArticleMenuLabel({
    required this.item,
    required this.following,
    required this.authorMuted,
    this.pdfBuilding = false,
    this.highlightsShown = true,
  });

  final ArticleMenuItem item;

  /// The viewer follows the author: "Unfollow author".
  final bool following;

  /// The viewer muted the author: "Unmute author".
  final bool authorMuted;

  /// The article's PDF is being built: "Preparing the PDF…" with a spinner.
  final bool pdfBuilding;

  /// Highlights are drawn: "Hide highlights" (else "Show highlights").
  final bool highlightsShown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final (icon, text) = switch (item) {
      ArticleMenuItem.showLess => (Icons.thumb_down_off_alt_outlined, l10n.articleMenuShowLess),
      ArticleMenuItem.highlights => highlightsShown
          ? (Icons.format_color_reset_outlined, l10n.highlightMenuHide)
          : (Icons.border_color_outlined, l10n.highlightMenuShow),
      ArticleMenuItem.follow => following
          ? (Icons.person_remove_outlined, l10n.articleMenuUnfollow)
          : (Icons.person_add_alt_outlined, l10n.articleMenuFollow),
      ArticleMenuItem.muteAuthor => authorMuted
          ? (Icons.volume_up_outlined, l10n.articleMenuUnmuteAuthor)
          : (Icons.volume_off_outlined, l10n.articleMenuMuteAuthor),
      ArticleMenuItem.muteTopics => (Icons.label_off_outlined, l10n.articleMenuMuteTopics),
      ArticleMenuItem.downloadPdf => (Icons.picture_as_pdf_outlined, pdfBuilding ? l10n.pdfPreparing : l10n.pdfDownload),
      ArticleMenuItem.report => (Icons.flag_outlined, l10n.articleMenuReport),
      ArticleMenuItem.hide => (Icons.visibility_off_outlined, l10n.articleMenuHide),
      ArticleMenuItem.unhide => (Icons.visibility_outlined, l10n.articleMenuUnhide),
    };
    final color = switch (item) {
      ArticleMenuItem.report => colors.error,
      ArticleMenuItem.downloadPdf when pdfBuilding => colors.textSecondary,
      _ => colors.textPrimary,
    };
    return Row(
      children: [
        if (item == ArticleMenuItem.downloadPdf && pdfBuilding)
          SizedBox.square(
            dimension: 20,
            child: Padding(padding: const EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2, color: color)),
          )
        else
          Icon(icon, size: 20, color: color),
        const SizedBox(width: ReadInSpace.s3),
        Flexible(child: Text(text, style: TextStyle(color: color))),
      ],
    );
  }
}

// "Hidden by moderators" above a hidden article, for its author and moderators (the only ones who can open it), with
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
