import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/current_locale.dart';
import '../../domain/entities/me.dart';
import '../../domain/usecases/auth_usecases.dart';

enum SessionStatus { unknown, guest, authenticated }

class SessionState extends Equatable {
  const SessionState({this.status = SessionStatus.unknown, this.me, this.failure});

  final SessionStatus status;

  /// The SQL Server account; null for guests, or when `/auth/sync` failed.
  final Me? me;
  final Failure? failure;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  /// Signed in, synced and still has to pick interests (F02).
  bool get needsOnboarding => isAuthenticated && me != null && !me!.onboardingCompleted;

  @override
  List<Object?> get props => [status, me, failure];
}

/// App-wide session: Firebase identity → `/auth/sync` → [Me] (SPEC §9.2).
/// Guests can browse; interactions prompt sign-in.
@lazySingleton
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._watch, this._sync, this._getMe, this._signOut, this._locale) : super(const SessionState());

  final WatchAuthState _watch;
  final SyncAccount _sync;
  final GetMe _getMe;
  final SignOut _signOut;
  final CurrentLocale _locale;
  StreamSubscription<String?>? _subscription;

  void start() {
    _subscription ??= _watch().listen(_onUid);
  }

  Future<void> _onUid(String? uid) async {
    if (uid == null) {
      emit(const SessionState(status: SessionStatus.guest));
      return;
    }
    final result = await _sync(uiLanguage: _locale.languageCode);
    emit(result.fold(
      (failure) => SessionState(status: SessionStatus.authenticated, failure: failure),
      (me) => SessionState(status: SessionStatus.authenticated, me: me),
    ));
  }

  /// Re-reads `/me` (e.g. after onboarding saved interests).
  Future<void> refresh() async {
    if (!state.isAuthenticated) return;
    final result = state.me == null ? await _sync(uiLanguage: _locale.languageCode) : await _getMe();
    result.fold(
      (failure) => emit(SessionState(status: state.status, me: state.me, failure: failure)),
      (me) => emit(SessionState(status: SessionStatus.authenticated, me: me)),
    );
  }

  Future<void> signOut() => _signOut();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
