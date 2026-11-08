import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

/// The admin bar's Notifications tab (F23): the notification center, kept while another tab is open. Each time the tab
/// comes back into view it reads the list again and marks everything seen, so the tab's badge clears. A row opens its
/// link like its push: a `support_ticket` notification opens the console's ticket page.
class AdminNotificationsTab extends StatefulWidget {
  const AdminNotificationsTab({super.key, this.cubit});

  /// Test seam; the app takes a new one from DI.
  final NotificationsCubit? cubit;

  @override
  State<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<AdminNotificationsTab> {
  late final NotificationsCubit _cubit = widget.cubit ?? getIt<NotificationsCubit>();

  /// Whether the tab was in view at the last check; null before the first.
  bool? _shown;

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.open());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The shell keeps the tabs that aren't open (and a page pushed over them) with their tickers off.
    final shown = TickerMode.valuesOf(context).enabled;
    if (_shown == false && shown) unawaited(_cubit.refresh());
    _shown = shown;
  }

  @override
  void dispose() {
    if (widget.cubit == null) unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(value: _cubit, child: const NotificationsView());
}
