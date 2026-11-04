import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/push/push_platform.dart';
import '../../../../core/push/push_service.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_settings.dart';
import '../cubit/notification_settings_cubit.dart';

/// Onboarding's "daily article notification" switch (F02): the account's `daily_article` mode (F17), on = push + in
/// app, off = off. Turning it on is where push permission is asked, in context (SPEC §21.1). Needs a
/// [NotificationSettingsCubit]; the switch waits for its settings.
class DailyArticleSwitch extends StatelessWidget {
  const DailyArticleSwitch({super.key});

  static final _noPush = ValueNotifier(PushPermission.unsupported);

  /// The switch is on (the default until the settings load).
  static bool isOn(NotificationSettingsState state) => state.modeOf(NotificationType.dailyArticle) == NotificationMode.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<NotificationSettingsCubit>().state;
    final push = getIt.isRegistered<PushService>() ? getIt<PushService>() : null;
    return ValueListenableBuilder(
      valueListenable: push?.permission ?? _noPush,
      builder: (context, permission, _) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.notifications_active_outlined),
        title: Text(l10n.notificationsLabel),
        subtitle: switch (permission) {
          PushPermission.denied => Text(l10n.notificationsBlocked),
          PushPermission.granted => null,
          _ => Text(l10n.notificationsHint),
        },
        value: isOn(state),
        onChanged: state.status != NotificationSettingsStatus.ready
            ? null
            : (on) async {
                if (on && push != null) unawaited(push.enable());
                final failure = await context
                    .read<NotificationSettingsCubit>()
                    .setMode(NotificationType.dailyArticle, on ? NotificationMode.all : NotificationMode.off);
                if (context.mounted) showActionFailure(context, failure);
              },
      ),
    );
  }
}
