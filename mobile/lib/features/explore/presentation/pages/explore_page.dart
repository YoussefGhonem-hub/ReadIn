import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../paths/presentation/path_routes.dart';
import '../../../paths/presentation/widgets/home_path_card.dart';

/// Explore (F15, Phase 2). Until it ships, the way in to the learning paths (F09).
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.navExplore), automaticallyImplyLeading: false),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(ReadInSpace.s5, ReadInSpace.s3, ReadInSpace.s5, 0),
              child: PathsPromptRow(onTap: () => context.push(PathRoutes.list)),
            ),
            const Expanded(child: ComingSoonView(icon: Icons.explore_outlined)),
          ],
        ),
      );
}
