import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/usecases/notification_usecases.dart';

enum NotificationSettingsStatus { loading, ready, failure }

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({this.status = NotificationSettingsStatus.loading, this.settings, this.failure});

  final NotificationSettingsStatus status;

  /// What the screen shows: the saved settings plus changes on their way to the server.
  final NotificationSettings? settings;
  final Failure? failure;

  NotificationMode modeOf(NotificationType type) => settings?.modeOf(type) ?? NotificationSettings.defaultMode;

  @override
  List<Object?> get props => [status, settings, failure];
}

/// Settings → Notifications (F17): a mode per configurable type and quiet hours (`GET/PUT /me/notification-settings`).
/// Every change shows at once and is saved right away, one save after another; a refused save (e.g.
/// `notification.quiet_hours_invalid`) puts the last saved settings back and returns the failure for a message.
@injectable
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit(this._get, this._update) : super(const NotificationSettingsState());

  final GetNotificationSettings _get;
  final UpdateNotificationSettings _update;

  /// The settings the server has.
  NotificationSettings? _saved;
  Future<void> _saving = Future.value();

  Future<void> load() async {
    if (state.status != NotificationSettingsStatus.loading) emit(const NotificationSettingsState());
    final result = await _get();
    if (isClosed) return;
    result.fold(
      (failure) => emit(NotificationSettingsState(status: NotificationSettingsStatus.failure, failure: failure)),
      (settings) {
        _saved = settings;
        emit(NotificationSettingsState(status: NotificationSettingsStatus.ready, settings: settings));
      },
    );
  }

  Future<Failure?> setMode(NotificationType type, NotificationMode mode) {
    if (!type.isConfigurable) return Future.value();
    return _change((settings) => settings.withMode(type, mode));
  }

  Future<Failure?> setQuietHoursEnabled(bool enabled) =>
      _change((settings) => settings.withQuietHours(settings.quietHours.copyWith(enabled: enabled)));

  /// `HH:mm` times; null keeps that end.
  Future<Failure?> setQuietHours({String? start, String? end}) =>
      _change((settings) => settings.withQuietHours(settings.quietHours.copyWith(start: start, end: end)));

  Future<Failure?> _change(NotificationSettings Function(NotificationSettings settings) edit) async {
    final current = state.settings;
    if (state.status != NotificationSettingsStatus.ready || current == null) return null;
    final next = edit(current);
    if (next == current) return null;
    emit(NotificationSettingsState(status: NotificationSettingsStatus.ready, settings: next));

    final done = Completer<Failure?>();
    _saving = _saving.then((_) async {
      final result = await _update(next);
      final failure = result.failureOrNull;
      if (failure == null) {
        _saved = next;
      } else if (!isClosed && state.settings == next) {
        // Only the latest change rolls the screen back; a later one is still on its way.
        emit(NotificationSettingsState(status: NotificationSettingsStatus.ready, settings: _saved));
      }
      done.complete(failure);
    });
    return done.future;
  }
}
