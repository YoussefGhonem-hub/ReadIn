import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/state_views.dart';

/// Explore (F15, Phase 2).
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) => ComingSoonPage(title: context.l10n.navExplore, icon: Icons.explore_outlined);
}
