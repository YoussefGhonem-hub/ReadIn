import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/state_views.dart';

/// Article editor (F05) — AppFlowy editor with RDoc converters, next milestone.
class EditorPage extends StatelessWidget {
  const EditorPage({super.key});

  @override
  Widget build(BuildContext context) => ComingSoonPage(title: context.l10n.navWrite, icon: Icons.edit_note_rounded);
}
