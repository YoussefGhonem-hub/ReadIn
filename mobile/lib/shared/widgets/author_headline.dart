import 'package:flutter/material.dart';

import '../../core/bidi/bidi.dart';
import '../../core/theme/theme_x.dart';

/// The writer's title (F14) under their name on post cards, the reader's author row and comments: one line with "…".
/// It is laid out in its own direction (`dir="auto"`, SPEC §14.2), so an English title in the Arabic UI is cut at its
/// own end, with the opposite-script runs inside it isolated. Secondary text, as on web. Callers leave it out when there
/// is none.
class AuthorHeadline extends StatelessWidget {
  const AuthorHeadline(this.headline, {super.key, this.style});

  final String headline;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final direction = Bidi.detect(headline) ?? Directionality.of(context);
    return Text(
      Bidi.isolateOppositeRuns(headline, direction),
      textDirection: direction,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style ?? context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
    );
  }
}
