import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/update_policy.dart';
import '../../domain/usecases/check_app_update.dart';

class AppUpdateState extends Equatable {
  const AppUpdateState({this.requirement});

  /// Non-null: this version is no longer supported, and the Update page replaces the app.
  final UpdateRequirement? requirement;

  bool get mustUpdate => requirement != null;

  @override
  List<Object?> get props => [requirement];
}

/// The forced update check (`GET /app/update-policy`): at startup, beside the session restore and never holding up the
/// splash, and when the app returns to the foreground, at most once every [resumeInterval]. The last policy received is
/// kept on the device, so an app told to update stays blocked when it starts offline; a network error never blocks.
@lazySingleton
class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit(this._check, {@ignoreParam DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(const AppUpdateState());

  static const resumeInterval = Duration(minutes: 30);

  final CheckAppUpdate _check;
  final DateTime Function() _clock;
  DateTime? _lastCheck;
  Future<void>? _checking;

  /// Once, at startup: the saved policy first (offline), then the server's.
  Future<void> start() async {
    if (_lastCheck != null) return;
    _lastCheck = _clock();
    final cached = await _check.cached();
    if (!isClosed && cached != null) emit(AppUpdateState(requirement: cached));
    await _fetch();
  }

  /// The app came back to the foreground: checks again when the last check is [resumeInterval] old.
  Future<void> resumed() async {
    final last = _lastCheck;
    if (last == null || _checking != null || _clock().difference(last) < resumeInterval) return;
    _lastCheck = _clock();
    await _fetch();
  }

  Future<void> _fetch() => _checking ??= _load().whenComplete(() => _checking = null);

  /// The server's answer replaces what the app had; an error keeps it.
  Future<void> _load() async {
    final result = await _check.fetch();
    if (!isClosed && result.isOk) emit(AppUpdateState(requirement: result.valueOrNull));
  }
}
