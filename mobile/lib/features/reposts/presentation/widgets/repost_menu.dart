import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';

/// What the viewer picked in the Repost menu (F29).
enum RepostMenuAction { repost, withThoughts, editThoughts, undo }

/// The small menu a tap on Repost opens (F29): "Repost" and "Repost with your thoughts" before the viewer reposted the
/// article, "Edit your thoughts" and "Undo repost" after. Null when dismissed.
Future<RepostMenuAction?> showRepostMenu(BuildContext context, {required bool reposted}) =>
    showModalBottomSheet<RepostMenuAction>(
      context: context,
      useSafeArea: true,
      builder: (_) => RepostMenuSheet(reposted: reposted),
    );

/// The menu's items; each pops its [RepostMenuAction].
class RepostMenuSheet extends StatelessWidget {
  const RepostMenuSheet({super.key, required this.reposted});

  final bool reposted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget item(RepostMenuAction action, IconData icon, String label) => ListTile(
          key: ValueKey('repost-menu-${action.name}'),
          minTileHeight: 56,
          leading: Icon(icon),
          title: Text(label),
          onTap: () => Navigator.of(context).pop(action),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: ReadInSpace.s2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: reposted
            ? [
                item(RepostMenuAction.editThoughts, Icons.edit_outlined, l10n.repostMenuEdit),
                item(RepostMenuAction.undo, Icons.undo_rounded, l10n.repostMenuUndo),
              ]
            : [
                item(RepostMenuAction.repost, Icons.repeat_rounded, l10n.repostMenuRepost),
                item(RepostMenuAction.withThoughts, Icons.edit_note_rounded, l10n.repostMenuWithThoughts),
              ],
      ),
    );
  }
}
