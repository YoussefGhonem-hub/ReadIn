import 'package:equatable/equatable.dart';

import 'app_notification.dart';

/// How a notification type reaches the user (`NotificationMode`): [all] = push + the notification center, [inApp] =
/// the center only, [off] = nothing at all. The wire name is [name].
enum NotificationMode {
  all,
  inApp,
  off;

  /// Null for a mode this app version doesn't know.
  static NotificationMode? fromWire(String? wire) => values.where((mode) => mode.name == wire).firstOrNull;
}

/// No pushes between [start] and [end] (`HH:mm`, the user's time zone). Security alerts still arrive.
class QuietHours extends Equatable {
  const QuietHours({this.enabled = true, this.start = '23:00', this.end = '07:00'});

  final bool enabled;
  final String start;
  final String end;

  static final _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// Both times are `HH:mm` and differ (an empty window means nothing).
  bool get isValid => _time.hasMatch(start) && _time.hasMatch(end) && start != end;

  QuietHours copyWith({bool? enabled, String? start, String? end}) =>
      QuietHours(enabled: enabled ?? this.enabled, start: start ?? this.start, end: end ?? this.end);

  @override
  List<Object?> get props => [enabled, start, end];
}

/// `NotificationSettingsDto` (F17): quiet hours and a mode per configurable type. A type that isn't listed has the
/// default mode, [NotificationMode.all].
class NotificationSettings extends Equatable {
  const NotificationSettings({this.quietHours = const QuietHours(), this.types = const {}});

  final QuietHours quietHours;
  final Map<NotificationType, NotificationMode> types;

  static const defaultMode = NotificationMode.all;

  NotificationMode modeOf(NotificationType type) => types[type] ?? defaultMode;

  NotificationSettings withMode(NotificationType type, NotificationMode mode) =>
      NotificationSettings(quietHours: quietHours, types: {...types, type: mode});

  NotificationSettings withQuietHours(QuietHours quietHours) => NotificationSettings(quietHours: quietHours, types: types);

  @override
  List<Object?> get props => [quietHours, types];
}
