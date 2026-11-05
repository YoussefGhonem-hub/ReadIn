import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/tokens.g.dart';
import '../../../article/domain/entities/article.dart';
import '../cubit/mutes_cubit.dart';

/// A card of a list that applies mutes (F28: Home, field pages, Explore, tag pages, Related). It folds away once the
/// viewer mutes its writer, field or topic or marks it "show less", and opens again in place on Undo. Wrap the card
/// with its gap, so nothing is left behind. The writer's own pages (profile tabs, category pages) don't use it.
///
/// A field page passes its own field and the picked topic ([keepFieldId], [keepTopicId]): those stay, as on the
/// server. Without a [MutesCubit] above (tests of other screens), nothing folds.
class MuteGate extends StatelessWidget {
  const MuteGate({super.key, required this.article, required this.child, this.keepFieldId, this.keepTopicId});

  final ArticleCard article;
  final Widget child;
  final String? keepFieldId;
  final String? keepTopicId;

  @override
  Widget build(BuildContext context) {
    final hidden = context.select(
      (MutesCubit? c) => c?.state.hides(article, keepFieldId: keepFieldId, keepTopicId: keepTopicId) ?? false,
    );
    return FoldAway(folded: hidden, child: child);
  }
}

/// Whether mutes and "show less" fold away every one of [cards] (F28), as [MuteGate] decides it, so the list shows its
/// own empty state (or keeps loading, [LoadMoreWhileHidden]) and a section hides its heading. False for no cards (the
/// list's own empty case) and without a [MutesCubit] above. Call it while building: it follows [MutesCubit].
bool mutesHideAll(BuildContext context, Iterable<ArticleCard> cards, {String? keepFieldId, String? keepTopicId}) =>
    cards.isNotEmpty &&
    context.select(
      (MutesCubit? c) =>
          c != null && cards.every((card) => c.state.hides(card, keepFieldId: keepFieldId, keepTopicId: keepTopicId)),
    );

/// The footer of a paged list that applies mutes, which asks for the next page itself while [active]: every card
/// loaded so far is folded away ([mutesHideAll]) and the list has more, so no scroll would. The list's empty state
/// shows only once nothing is left to load.
class LoadMoreWhileHidden extends StatelessWidget {
  const LoadMoreWhileHidden({super.key, required this.active, required this.onLoadMore, required this.child});

  /// All the loaded cards are hidden, there is a next page, and no page is loading or failed (the footer's Retry
  /// asks again then).
  final bool active;
  final VoidCallback onLoadMore;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) onLoadMore();
      });
    }
    return child;
  }
}

/// [child] at its own height, or folded to nothing while [folded]: it shrinks and fades out (or back in), at once when
/// "reduce motion" is on. A folded child keeps its state but takes no taps, focus or screen-reader attention.
class FoldAway extends StatefulWidget {
  const FoldAway({super.key, required this.folded, required this.child});

  final bool folded;
  final Widget child;

  @override
  State<FoldAway> createState() => _FoldAwayState();
}

class _FoldAwayState extends State<FoldAway> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ReadInMotion.base,
    value: widget.folded ? 0 : 1,
  );
  late final Animation<double> _size = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(FoldAway old) {
    super.didUpdateWidget(old);
    if (old.folded == widget.folded) return;
    final target = widget.folded ? 0.0 : 1.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = target;
    } else {
      _controller.animateTo(target);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return ExcludeFocus(
            excluding: widget.folded,
            child: ExcludeSemantics(
              excluding: widget.folded,
              child: IgnorePointer(
                ignoring: widget.folded,
                // Fully folded: not painted at all. The same widgets either way, so the card keeps its state; it is
                // clipped only while it folds, so a card at rest paints exactly as without the gate.
                child: Offstage(
                  offstage: value == 0,
                  child: ClipRect(
                    clipBehavior: value == 1 ? Clip.none : Clip.hardEdge,
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      heightFactor: _size.value,
                      child: Opacity(opacity: value, child: child),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: widget.child,
      );
}
