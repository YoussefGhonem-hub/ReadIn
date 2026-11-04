import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/me.dart';
import '../../domain/usecases/auth_usecases.dart';

enum SessionStatus { unknown, guest, authenticated }

/// Screens a signed-in user must pass, in this order, before anything else (SPEC §9.2).
enum AccountGate { changePassword, setRecoveryPin, completeProfile, onboarding }

class SessionState extends Equatable {
  const SessionState({this.status = SessionStatus.unknown, this.me, this.failure});

  final SessionStatus status;

  /// The account; null for guests, or while a stored session couldn't be restored (offline).
  final Me? me;
  final Failure? failure;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  /// The first guard that applies: `mustChangePassword` → `mustSetRecoveryPin` → profile incomplete → onboarding.
  AccountGate? get gate {
    final me = this.me;
    if (!isAuthenticated || me == null) return null;
    if (me.mustChangePassword) return AccountGate.changePassword;
    if (me.mustSetRecoveryPin) return AccountGate.setRecoveryPin;
    if (!me.isProfileComplete) return AccountGate.completeProfile;
    if (!me.onboardingCompleted) return AccountGate.onboarding;
    return null;
  }

  @override
  List<Object?> get props => [status, me, failure];
}

/// App-wide session (SPEC §9.3): the splash restores it with `POST /auth/refresh`, then every sign in, token refresh,
/// account change and sign out arrives through [WatchSession]. Guests can browse and read.
@lazySingleton
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._watch, this._restore, this._getMe, this._signOut, this._signOutEverywhere)
      : super(const SessionState());

  final WatchSession _watch;
  final RestoreSession _restore;
  final GetMe _getMe;
  final SignOut _signOut;
  final SignOutEverywhere _signOutEverywhere;
  StreamSubscription<Me?>? _subscription;

  Future<void> start() async {
    if (_subscription != null) return;
    _subscription = _watch().listen(_onUser);
    final result = await _restore();
    if (state.status != SessionStatus.unknown) return; // a change already arrived
    result.fold(
      (failure) => emit(_endedBy(failure)
          ? SessionState(status: SessionStatus.guest, failure: failure)
          // Offline with a stored session: stay signed in; the next call or [refresh] restores it.
          : SessionState(status: SessionStatus.authenticated, failure: failure)),
      (me) => emit(me == null ? const SessionState(status: SessionStatus.guest) : _signedIn(me)),
    );
  }

  /// The refresh token was rejected or the account is suspended: the session is over.
  static bool _endedBy(Failure failure) => failure.statusCode == 401 || failure.statusCode == 403;

  /// A session that the server ended for a suspended account keeps the `user.suspended` failure (F22): the app opens
  /// Sign in with it, saying until when.
  void _onUser(Me? me) =>
      emit(me == null ? SessionState(status: SessionStatus.guest, failure: _watch.endedBy) : _signedIn(me));

  static SessionState _signedIn(Me me) => SessionState(status: SessionStatus.authenticated, me: me);

  /// Re-reads `/me` (after onboarding, or to retry a restore that failed offline).
  Future<void> refresh() async {
    if (!state.isAuthenticated) return;
    final result = await _getMe();
    if (result.failureOrNull case final failure?) {
      if (state.isAuthenticated) emit(SessionState(status: state.status, me: state.me, failure: failure));
    }
  }

  /// Unregisters push, ends the session on the server and forgets it here.
  Future<void> signOut() => _signOut();

  /// Signs every other device out; null on success.
  Future<Failure?> signOutEverywhere() async => (await _signOutEverywhere()).failureOrNull;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
