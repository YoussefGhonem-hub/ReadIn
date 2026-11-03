import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n_x.dart';
import '../../../../shared/widgets/state_views.dart';

/// Notification center (F17, Phase 2).
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => ComingSoonPage(
        title: context.l10n.notifications,
        icon: Icons.notifications_none_rounded,
        showBack: true,
      );
}
