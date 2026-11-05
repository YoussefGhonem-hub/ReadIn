import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens.g.dart';

/// A block of a page's content on the `bg` canvas, as in LinkedIn's app: full width on `surface`, square, no border.
/// A page's blocks stand [gap] apart (the first one [gap] under the top bar), like the feed's post cards (F34), so the
/// canvas shows between them. A list inside a block runs as rows split by 1 px `border` dividers, and its skeleton,
/// empty and error states show inside the block, where the rows would be.
///
/// It is a [Material], so the ink of the rows inside shows on it. A long list in a sliver wraps each row in its own
/// block, with no margin: the rows still read as one block.
class PageBlock extends StatelessWidget {
  const PageBlock({super.key, required this.child, this.padding = EdgeInsets.zero, this.margin = EdgeInsets.zero});

  /// Between two blocks: the canvas between them (the post cards' gap).
  static const gap = ReadInSpace.s2;

  /// The inline padding of a block's content, as in the post card.
  static const gutter = ReadInSpace.s4;

  /// [gutter] on both sides.
  static const gutters = EdgeInsets.symmetric(horizontal: gutter);

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Around the block, e.g. `EdgeInsets.only(bottom: PageBlock.gap)` before the next one.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: Material(color: context.colors.surface, child: Padding(padding: padding, child: child)),
      );
}
