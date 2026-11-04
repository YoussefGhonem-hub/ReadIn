import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/l10n_x.dart';
import '../../../../core/push/push_platform.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../shared/widgets/action_feedback.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_settings.dart';
import '../cubit/notification_settings_cubit.dart';
import '../widgets/notification_text.dart';

/// Settings → Notifications (F17), signed in only: push + in app, in app only or off for each configurable type, and
/// quiet hours. Security alerts are always on.
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  static const path = '/settings/notifications';

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<NotificationSettingsCubit>()..load(),
        child: const NotificationSettingsView(),
      );
}

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<NotificationSettingsCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationSettings)),
      body: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
        builder: (context, state) => switch (state.status) {
          NotificationSettingsStatus.loading => const Center(child: CircularProgressIndicator()),
          NotificationSettingsStatus.failure => ErrorView(failure: state.failure!, onRetry: () => unawaited(cubit.load())),
          NotificationSettingsStatus.ready => ListView(
              padding: const EdgeInsets.all(ReadInSpace.s4),
              children: [
                const PushBlockedNotice(),
                _Card(
                  title: l10n.notificationSettingsTypesTitle,
                  hint: l10n.notificationSettingsTypesHint,
                  children: [
                    for (final type in NotificationType.configurable) _TypeModeTile(type: type, mode: state.modeOf(type)),
                    const _SecurityAlertsTile(),
                  ],
                ),
                _QuietHoursCard(quietHours: state.settings!.quietHours),
              ],
            ),
        },
      ),
    );
  }
}

/// Saves a change and says why it was refused, if it was.
Future<void> _save(BuildContext context, Future<Failure?> Function(NotificationSettingsCubit cubit) change) async {
  final failure = await change(context.read<NotificationSettingsCubit>());
  if (context.mounted) showActionFailure(context, failure);
}

/// Asks for push permission in context: when a type is set to push (SPEC §21.1).
void askPushPermission() {
  if (!getIt.isRegistered<PushService>()) return;
  final push = getIt<PushService>();
  if (push.permission.value == PushPermission.notDetermined) unawaited(push.enable());
}

/// "Notifications are off for ReadIn in your phone's settings", only while they are.
class PushBlockedNotice extends StatelessWidget {
  const PushBlockedNotice({super.key});

  static final _noPush = ValueNotifier(PushPermission.unsupported);

  @override
  Widget build(BuildContext context) {
    final push = getIt.isRegistered<PushService>() ? getIt<PushService>() : null;
    final colors = context.colors;
    return ValueListenableBuilder(
      valueListenable: push?.permission ?? _noPush,
      builder: (context, permission, _) => permission != PushPermission.denied
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.only(bottom: ReadInSpace.s4),
              padding: const EdgeInsets.all(ReadInSpace.s3),
              decoration: BoxDecoration(color: colors.calloutWarning, borderRadius: BorderRadius.circular(ReadInRadius.md)),
              child: Row(
                children: [
                  Icon(Icons.notifications_off_outlined, color: colors.calloutWarningAccent),
                  const SizedBox(width: ReadInSpace.s3),
                  Expanded(child: Text(context.l10n.notificationsBlocked, style: context.textTheme.bodyMedium)),
                ],
              ),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, this.hint, required this.children});

  final String title;
  final String? hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: ReadInSpace.s4),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ReadInSpace.s4, ReadInSpace.s4, ReadInSpace.s4, ReadInSpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(header: true, child: Text(title, style: context.textTheme.titleMedium)),
                if (hint != null) ...[
                  const SizedBox(height: ReadInSpace.s1),
                  Text(hint!, style: context.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                ],
                const SizedBox(height: ReadInSpace.s2),
                ...children,
              ],
            ),
          ),
        ),
      );
}

class _TypeModeTile extends StatelessWidget {
  const _TypeModeTile({required this.type, required this.mode});

  final NotificationType type;
  final NotificationMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final label = notificationTypeLabel(l10n, type);
    final selectedStyle = context.textTheme.bodyMedium?.copyWith(
      color: mode == NotificationMode.off ? colors.textSecondary : colors.primary,
      fontWeight: FontWeight.w600,
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<NotificationMode>(
          key: ValueKey('mode-${type.wire}'),
          value: mode,
          borderRadius: BorderRadius.circular(ReadInRadius.md),
          style: context.textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
          // Closed, the short name ("Push"); the menu says what each one does ("Push + in app").
          selectedItemBuilder: (_) => [
            for (final option in NotificationMode.values)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(notificationModeLabel(l10n, option, short: true), style: selectedStyle),
              ),
          ],
          items: [
            for (final option in NotificationMode.values)
              DropdownMenuItem(value: option, child: Text(notificationModeLabel(l10n, option))),
          ],
          onChanged: (picked) {
            if (picked == null || picked == mode) return;
            if (picked == NotificationMode.all) askPushPermission();
            unawaited(_save(context, (cubit) => cubit.setMode(type, picked)));
          },
        ),
      ),
    );
  }
}

class _SecurityAlertsTile extends StatelessWidget {
  const _SecurityAlertsTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final secondary = context.colors.textSecondary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.notificationSecurityAlerts),
      subtitle: Text(l10n.notificationSecurityAlertsHint),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            notificationModeLabel(l10n, NotificationMode.all, short: true),
            style: context.textTheme.bodyMedium?.copyWith(color: secondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: ReadInSpace.s2),
          Icon(Icons.lock_outline_rounded, size: 18, color: secondary),
        ],
      ),
    );
  }
}

class _QuietHoursCard extends StatelessWidget {
  const _QuietHoursCard({required this.quietHours});

  final QuietHours quietHours;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = quietHours.enabled;
    return _Card(
      title: l10n.quietHoursTitle,
      hint: l10n.quietHoursHint,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.bedtime_outlined),
          title: Text(l10n.quietHoursSwitch),
          value: enabled,
          onChanged: (on) => unawaited(_save(context, (cubit) => cubit.setQuietHoursEnabled(on))),
        ),
        _TimeTile(
          label: l10n.quietHoursFrom,
          value: quietHours.start,
          enabled: enabled,
          onPicked: (time) => _save(context, (cubit) => cubit.setQuietHours(start: time)),
        ),
        _TimeTile(
          label: l10n.quietHoursTo,
          value: quietHours.end,
          enabled: enabled,
          onPicked: (time) => _save(context, (cubit) => cubit.setQuietHours(end: time)),
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.label, required this.value, required this.enabled, required this.onPicked});

  final String label;

  /// `HH:mm`.
  final String value;
  final bool enabled;
  final Future<void> Function(String time) onPicked;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        enabled: enabled,
        leading: const Icon(Icons.schedule_rounded),
        title: Text(label),
        trailing: Text(
          value,
          textDirection: TextDirection.ltr,
          style: context.textTheme.titleSmall?.copyWith(color: enabled ? null : context.colors.textSecondary),
        ),
        onTap: () async {
          final picked = await showTimePicker(context: context, initialTime: SettingsCubit.parseTime(value));
          if (picked != null) await onPicked(SettingsCubit.formatTime(picked));
        },
      );
}
