import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/state_views.dart';

/// Saved articles & collections (F13), with offline cache (F25).
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) => ComingSoonPage(title: context.l10n.navSaved, icon: Icons.bookmark_border_rounded);
}
