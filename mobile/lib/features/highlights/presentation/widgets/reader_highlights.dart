import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/highlights/rdoc_highlights.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/domain/entities/permissions.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../auth/presentation/widgets/require_account.dart';
import '../../../quote_card/domain/entities/quote_card.dart';
import '../../../quote_card/presentation/widgets/quote_card_sheet.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/article_highlights_cubit.dart';

/// The reader's highlights (F30) around its body: with an [ArticleHighlightsCubit] above (the reader provides one), the
/// article's highlightable blocks select text with the Highlight / Remove toolbar and draw yours and the popular ranges,
/// unless "Hide highlights" is on (F18, F28). The same toolbar offers Share quote (F24). A device copy (offline) has
/// none. Without the cubit (the editor preview) it is just [child].
class ReaderHighlights extends StatefulWidget {
  const ReaderHighlights({super.key, required this.article, required this.child, this.onTextChanged});

  final ArticleDetails article;
  final Widget child;

  /// `highlight.text_mismatch`: the author changed the article meanwhile, so the reader loads it again.
  final VoidCallback? onTextChanged;

  @override
  State<ReaderHighlights> createState() => _ReaderHighlightsState();
}

class _ReaderHighlightsState extends State<ReaderHighlights> {
  ArticleHighlightsCubit? _cubit;

  ArticleCard get _card => widget.article.card;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ArticleHighlightsCubit?>();
    _open(context.read<SettingsCubit>().state.showHighlights);
  }

  @override
  void didUpdateWidget(ReaderHighlights old) {
    super.didUpdateWidget(old);
    if (old.article.card.id != _card.id || old.article.card.language != _card.language) {
      _open(context.read<SettingsCubit>().state.showHighlights);
    }
  }

  /// Hidden highlights aren't fetched until they are shown again.
  void _open(bool shown) {
    if (_cubit == null || !shown || widget.article.isOfflineCopy) return;
    unawaited(_cubit!.open(_card.id, _card.language));
  }

  void _reload() {
    if (_cubit == null || !context.read<SettingsCubit>().state.showHighlights || widget.article.isOfflineCopy) return;
    unawaited(_cubit!.reload());
  }

  void _announce(String message) {
    if (MediaQuery.maybeAccessibleNavigationOf(context) ?? false) {
      unawaited(SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context)));
    }
  }

  Future<void> _highlight(BuildContext _, HighlightSelection selection) async {
    if (!requireAccount(context)) return;
    final l10n = context.l10n;
    final range = selection.range;
    if (selection.status == HighlightSelectionStatus.tooLong) return showActionMessage(context, l10n.errHighlightTooLong);
    if (selection.status != HighlightSelectionStatus.ok || range == null) return;
    final failure = await _cubit!.create(range);
    if (!mounted) return;
    if (failure == null) return _announce(l10n.highlightAdded);
    showActionFailure(context, failure);
    if (failure.code == FailureCodes.highlightTextMismatch) {
      widget.onTextChanged?.call();
      unawaited(_cubit!.reload());
    }
  }

  /// Share quote (F24): 3–400 characters open the quote card sheet (guests too); more say `quote.too_long` without
  /// calling the API.
  void _shareQuote(BuildContext _, HighlightSelection selection) {
    final range = selection.range;
    if (range == null || range.length < QuoteCardLimits.minLength) return;
    if (range.length > QuoteCardLimits.maxLength) return showActionMessage(context, context.l10n.errQuoteCardTooLong);
    unawaited(showQuoteCardSheet(
      context,
      article: _card,
      range: range,
      // `quote.text_mismatch`: the article and its highlights load again, as after `highlight.text_mismatch`.
      onTextChanged: () {
        if (!mounted) return;
        widget.onTextChanged?.call();
        _reload();
      },
    ));
  }

  Future<void> _remove(BuildContext _, String id) async {
    final failure = await _cubit!.remove(id);
    if (!mounted) return;
    if (failure == null) return _announce(context.l10n.highlightRemoved);
    showActionFailure(context, failure);
  }

  void _showCount(BuildContext _, Offset globalPosition, int count) =>
      unawaited(showHighlightCountBubble(context, globalPosition: globalPosition, count: count));

  /// Tapping one of yours offers Remove, as selecting inside it does (and the count, when it is popular too).
  void _showMine(BuildContext _, Offset globalPosition, String id, int count) => unawaited(showHighlightCountBubble(
        context,
        globalPosition: globalPosition,
        count: count,
        onRemove: () => unawaited(_remove(context, id)),
      ));

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) return widget.child;
    final shown = context.select((SettingsCubit c) => c.state.showHighlights);
    final session = context.select((SessionCubit c) => (c.state.isAuthenticated, c.state.me?.canHighlight ?? false));
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsCubit, AppSettings>(
          listenWhen: (previous, current) => previous.showHighlights != current.showHighlights,
          listener: (_, settings) => _open(settings.showHighlights),
        ),
        // Signed in (or out) from the reader: yours come (or go).
        BlocListener<SessionCubit, SessionState>(
          listenWhen: (previous, current) => previous.me?.id != current.me?.id,
          listener: (_, _) => _reload(),
        ),
      ],
      child: BlocBuilder<ArticleHighlightsCubit, ArticleHighlightsState>(
        bloc: cubit,
        builder: (context, state) => RDocHighlights(
          enabled: shown && !widget.article.isOfflineCopy,
          marks: state.marksFor(_card.id, _card.language),
          // Guests get Highlight too: it asks them to sign in.
          canHighlight: !session.$1 || session.$2,
          onHighlight: (context, selection) => unawaited(_highlight(context, selection)),
          onRemove: (context, id) => unawaited(_remove(context, id)),
          onCountTap: _showCount,
          onMineTap: _showMine,
          // Not on an article hidden by moderators (`quote.hidden`).
          onShareQuote: widget.article.isHidden ? null : _shareQuote,
          child: widget.child,
        ),
      ),
    );
  }
}

/// "N قارئ علّموا الجملة دي" in a small bubble above [globalPosition] (below it when there is no room), and, on one of
/// your highlights ([onRemove]), its "شيل العلامة" button; [count] 0 shows no count. A tap anywhere or Back closes it.
Future<void> showHighlightCountBubble(
  BuildContext context, {
  required Offset globalPosition,
  required int count,
  VoidCallback? onRemove,
}) {
  final animate = !MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: animate ? ReadInMotion.fast : Duration.zero,
    pageBuilder: (context, _, _) => HighlightCountBubble(anchor: globalPosition, count: count, onRemove: onRemove),
    transitionBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
  );
}

/// The bubble of [showHighlightCountBubble], placed by [anchor] (global).
class HighlightCountBubble extends StatelessWidget {
  const HighlightCountBubble({super.key, required this.anchor, required this.count, this.onRemove});

  final Offset anchor;

  /// Readers who marked it; 0 shows no count.
  final int count;

  /// One of yours: Remove closes the bubble, then calls this.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final padding = MediaQuery.paddingOf(context);
    final remove = onRemove;
    return CustomSingleChildLayout(
      delegate: _BubbleLayout(anchor: anchor, padding: padding),
      child: Semantics(
        liveRegion: true,
        child: Material(
          type: MaterialType.card,
          color: colors.surfaceRaised,
          elevation: dark ? 0 : 3,
          shadowColor: colors.scrim,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ReadInRadius.md),
            // Dark mode: a border instead of a shadow (SPEC §15.5).
            side: dark ? BorderSide(color: colors.border) : BorderSide.none,
          ),
          child: Padding(
            padding: remove == null
                ? const EdgeInsets.symmetric(horizontal: ReadInSpace.s3, vertical: ReadInSpace.s2)
                : EdgeInsetsDirectional.fromSTEB(count > 0 ? ReadInSpace.s3 : ReadInSpace.s1, ReadInSpace.s1, ReadInSpace.s1, ReadInSpace.s1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (count > 0) ...[
                  Icon(Icons.border_color_outlined, size: 18, color: colors.accent),
                  const SizedBox(width: ReadInSpace.s2),
                  Flexible(
                    child: Text(
                      context.l10n.highlightCount(count),
                      style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
                    ),
                  ),
                ],
                if (remove != null) ...[
                  if (count > 0) const SizedBox(width: ReadInSpace.s2),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: colors.textPrimary),
                    onPressed: () {
                      Navigator.of(context).pop();
                      remove();
                    },
                    icon: const Icon(Icons.format_color_reset_outlined, size: 18),
                    label: Text(context.l10n.highlightRemove),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleLayout extends SingleChildLayoutDelegate {
  _BubbleLayout({required this.anchor, required this.padding});

  final Offset anchor;
  final EdgeInsets padding;

  static const _margin = ReadInSpace.s4;
  static const _gap = ReadInSpace.s5;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: (constraints.maxWidth - _margin * 2).clamp(0, 360));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = (anchor.dx - childSize.width / 2).clamp(_margin, size.width - _margin - childSize.width);
    final above = anchor.dy - _gap - childSize.height;
    final top = above >= padding.top + _margin ? above : anchor.dy + _gap;
    return Offset(left.toDouble(), top.clamp(padding.top, size.height - childSize.height).toDouble());
  }

  @override
  bool shouldRelayout(_BubbleLayout old) => old.anchor != anchor || old.padding != padding;
}
