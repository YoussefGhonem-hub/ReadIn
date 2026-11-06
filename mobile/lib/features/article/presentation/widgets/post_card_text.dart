import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/rdoc/blocks/text_blocks.dart';
import '../../../../shared/rdoc/rdoc_view.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../domain/entities/article.dart';
import '../cubit/post_cards_cubit.dart';

/// The text of a post card under its title (F34), inside the card's [RDocScope]: the excerpt cut at
/// [PostExcerpt.maxLines] lines with "… Read more", or, once expanded, the preview drawn by the reader's own RDoc
/// renderer, then "Read the full article" (when there is more) and "Show less". Expanding only adds below.
class PostCardText extends StatelessWidget {
  const PostCardText({
    super.key,
    required this.article,
    required this.view,
    required this.onExpand,
    required this.onCollapse,
    required this.onRetry,
    required this.onOpen,
    required this.toggleFocus,
    this.completeWrapper,
  });

  final ArticleCard article;
  final PostCardView view;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onRetry;

  /// Opens the reader ("Read the full article").
  final VoidCallback onOpen;

  /// "Read more" and "Show less" share it, so the keyboard focus stays on the card when it expands or collapses.
  final FocusNode toggleFocus;

  /// Wraps a preview that is the whole article (counting it as read, F34).
  final Widget Function(Widget child)? completeWrapper;

  @override
  Widget build(BuildContext context) {
    final excerpt = article.excerpt;
    if (!view.expanded) {
      if (excerpt == null) {
        // No excerpt yet: the title alone, and "Read more" loads the beginning.
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: _ToggleButton(label: context.l10n.postReadMore, expanded: false, focusNode: toggleFocus, onPressed: onExpand),
        );
      }
      return PostExcerpt(
        text: excerpt,
        direction: RDocScope.of(context).baseDirection,
        continues: article.hasMore,
        onExpand: onExpand,
        focusNode: toggleFocus,
      );
    }

    final preview = view.preview;
    final Widget body = switch (view.status) {
      PreviewStatus.ready when preview != null => _wrapComplete(preview, RDocColumn(preview.content)),
      PreviewStatus.failure => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (excerpt != null) _WholeExcerpt(text: excerpt),
            ErrorView(failure: view.failure!, compact: true, onRetry: onRetry),
          ],
        ),
      _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (excerpt != null) _WholeExcerpt(text: excerpt),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: ReadInSpace.s3),
              child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
            ),
          ],
        ),
    };
    final complete = view.status == PreviewStatus.ready && (preview?.isComplete ?? false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: ReadInSpace.s2,
          children: [
            if (view.status == PreviewStatus.ready && !complete)
              TextButton.icon(
                onPressed: onOpen,
                // Mirrors itself in RTL.
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(context.l10n.postReadFullArticle),
                style: TextButton.styleFrom(minimumSize: const Size(48, 44), padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2)),
              ),
            _ToggleButton(label: context.l10n.postShowLess, expanded: true, focusNode: toggleFocus, onPressed: onCollapse),
          ],
        ),
      ],
    );
  }

  Widget _wrapComplete(ArticlePreview preview, Widget child) =>
      preview.isComplete && completeWrapper != null ? completeWrapper!(child) : child;
}

/// "Read more" with no excerpt to tap, and "Show less": a real button that says whether the card is expanded.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.label, required this.expanded, required this.focusNode, required this.onPressed});

  final String label;
  final bool expanded;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        expanded: expanded,
        child: TextButton(
          focusNode: focusNode,
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 44),
            padding: const EdgeInsets.symmetric(horizontal: ReadInSpace.s2),
            foregroundColor: context.colors.textSecondary,
            textStyle: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          child: Text(label),
        ),
      );
}

/// The excerpt in full while the preview loads or failed, so nothing jumps.
class _WholeExcerpt extends StatelessWidget {
  const _WholeExcerpt({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final direction = RDocScope.of(context).baseDirection;
    return Text(Bidi.isolateOppositeRuns(text, direction), textDirection: direction, style: rdocBodyStyle(context, direction));
  }
}

/// A post card's excerpt cut at [maxLines] lines, with "… اقرأ المزيد" / "… Read more" ending the last line in its own
/// isolate (so it never covers the text or breaks mixed text, SPEC §14.2). The excerpt is cut at a word. With no more
/// than fits ([continues] false), the text shows whole, with no button. A tap anywhere on it expands the card.
class PostExcerpt extends StatelessWidget {
  const PostExcerpt({
    super.key,
    required this.text,
    required this.direction,
    required this.continues,
    required this.onExpand,
    this.focusNode,
  });

  static const maxLines = 4;

  final String text;

  /// The article's direction (RTL for `ar-EG`, LTR for `en`).
  final TextDirection direction;

  /// The article goes on after [text] (`hasMore`).
  final bool continues;
  final VoidCallback onExpand;
  final FocusNode? focusNode;

  /// "… Read more": the label is an isolate in its own (the UI's) direction; the "…" stays outside it, so it follows
  /// the excerpt's last word even when the article and the UI read in opposite directions.
  static String moreLabel(String readMore) => '… ${Bidi.fsi}$readMore${Bidi.pdi}';

  /// What the collapsed card shows of [text] before [more]: null when the whole text fits in [maxLines] lines and
  /// nothing follows it (no button), else the longest beginning cut at a word that leaves room for [more] on the last
  /// line. Opposite-direction runs are isolated after cutting, so a cut never leaves an isolate open.
  ///
  /// [style] must be the style the text is drawn with, inherited parts included ([drawnStyle]): measuring with less
  /// (say, without the theme's letter spacing) cuts too little, and "… Read more" spills past the last line.
  @visibleForTesting
  static String? fit({
    required String text,
    required String more,
    required TextStyle style,
    required TextStyle moreStyle,
    required double maxWidth,
    required TextDirection direction,
    required bool continues,
    TextScaler textScaler = TextScaler.noScaling,
    Locale? locale,
    TextHeightBehavior? textHeightBehavior,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
  }) {
    bool fits(String body, {required bool withMore}) {
      final painter = TextPainter(
        text: TextSpan(style: style, children: [
          TextSpan(text: Bidi.isolateOppositeRuns(body, direction)),
          if (withMore) TextSpan(text: more, style: moreStyle),
        ]),
        textDirection: direction,
        textScaler: textScaler,
        maxLines: maxLines,
        locale: locale,
        textHeightBehavior: textHeightBehavior,
        textWidthBasis: textWidthBasis,
      )..layout(maxWidth: maxWidth);
      final result = !painter.didExceedMaxLines;
      painter.dispose();
      return result;
    }

    if (!continues && fits(text, withMore: false)) return null;
    if (fits(text, withMore: true)) return text;
    // The ends of words, shortest first; binary search for the longest beginning that leaves room for [more].
    final ends = <int>[
      for (var i = 1; i < text.length; i++)
        if (_isSpace(text.codeUnitAt(i)) && !_isSpace(text.codeUnitAt(i - 1))) i,
    ];
    var low = 0;
    var high = ends.length - 1;
    var best = -1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (fits(text.substring(0, ends[mid]), withMore: true)) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    if (best >= 0) return text.substring(0, ends[best]);
    // One very long word: cut it by characters.
    var length = text.length;
    while (length > 1 && !fits(text.substring(0, length), withMore: true)) {
      length = (length * 0.8).floor();
    }
    return text.substring(0, length);
  }

  static bool _isSpace(int c) => c == 0x20 || c == 0x0A || c == 0x09 || c == 0xA0;

  /// The style a [Text] given [style] really draws with: merged into the ambient [DefaultTextStyle] (the theme's letter
  /// spacing, for one) and made bold when the system asks for bold text, as [Text.build] does.
  @visibleForTesting
  static TextStyle drawnStyle(BuildContext context, TextStyle style) {
    var drawn = style.inherit ? DefaultTextStyle.of(context).style.merge(style) : style;
    if (MediaQuery.boldTextOf(context)) drawn = drawn.merge(const TextStyle(fontWeight: FontWeight.bold));
    return drawn;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final defaults = DefaultTextStyle.of(context);
    // Measured and drawn with the same style, so the cut leaves exactly the room "… Read more" takes.
    final style = drawnStyle(context, rdocBodyStyle(context, direction));
    final moreStyle = style.copyWith(color: colors.primary, fontWeight: FontWeight.w600);
    final more = moreLabel(l10n.postReadMore);
    return LayoutBuilder(
      builder: (context, constraints) {
        final shown = fit(
          text: text,
          more: more,
          style: style,
          moreStyle: moreStyle,
          maxWidth: constraints.maxWidth,
          direction: direction,
          continues: continues,
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
          textHeightBehavior: defaults.textHeightBehavior ?? DefaultTextHeightBehavior.maybeOf(context),
          textWidthBasis: defaults.textWidthBasis,
        );
        if (shown == null) {
          return Text(Bidi.isolateOppositeRuns(text, direction), textDirection: direction, style: style);
        }
        return Semantics(
          button: true,
          expanded: false,
          onTapHint: l10n.postReadMore,
          child: InkWell(
            focusNode: focusNode,
            onTap: onExpand,
            borderRadius: BorderRadius.circular(ReadInRadius.sm),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: Bidi.isolateOppositeRuns(shown, direction)),
                TextSpan(text: more, style: moreStyle),
              ]),
              textDirection: direction,
              style: style,
              maxLines: maxLines,
              overflow: TextOverflow.clip,
            ),
          ),
        );
      },
    );
  }
}
