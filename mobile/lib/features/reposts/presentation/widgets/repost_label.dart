import 'package:flutter/material.dart';

import '../../../../core/bidi/bidi.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../article/domain/entities/article.dart';
import '../../../profile/presentation/widgets/profile_link.dart';

/// "أعاد نشره {name}" / "{name} و N غيره أعادوا نشره" over a post card that a repost placed (F29, the F34 label row).
/// The name opens the reposter's profile; it keeps its own direction inside the sentence (SPEC §14.2).
class RepostLabelText extends StatelessWidget {
  const RepostLabelText({super.key, required this.label});

  final RepostLabel label;

  /// The sentence, with the name isolated in its own direction.
  static String textOf(AppLocalizations l10n, RepostLabel label) {
    final name = '${Bidi.fsi}${label.user.displayName}${Bidi.pdi}';
    return label.othersCount > 0 ? l10n.repostLabelMany(name, label.othersCount) : l10n.repostLabelOne(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final style = context.textTheme.labelMedium?.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w600);
    final name = '${Bidi.fsi}${label.user.displayName}${Bidi.pdi}';
    final text = textOf(l10n, label);
    // The name in bold: split the sentence around it.
    final at = text.indexOf(name);
    final spans = at < 0
        ? [TextSpan(text: text)]
        : [
            TextSpan(text: text.substring(0, at)),
            TextSpan(text: name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
            TextSpan(text: text.substring(at + name.length)),
          ];
    return ProfileLink(
      username: label.user.username,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Row(
          children: [
            Icon(Icons.repeat_rounded, size: 16, color: colors.textSecondary),
            const SizedBox(width: ReadInSpace.s1),
            Flexible(
              child: Text.rich(TextSpan(children: spans), maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
            ),
          ],
        ),
      ),
    );
  }
}
