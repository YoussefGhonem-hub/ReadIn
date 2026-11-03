import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/usecases/profile_usecases.dart';

class PrivacyState extends Equatable {
  const PrivacyState({this.publicReadingStats = false, this.pending = false});

  final bool publicReadingStats;

  /// A change is being saved: the switch shows the new value and ignores taps.
  final bool pending;

  @override
  List<Object?> get props => [publicReadingStats, pending];
}

/// "Show my reading stats on my public profile" (F14, F18): `PUT /me/privacy`, applied at once and rolled back when
/// the API refuses it. Otherwise it follows `MeDto.privacy` from the session.
@injectable
class PrivacyCubit extends Cubit<PrivacyState> {
  PrivacyCubit(this._setPublicReadingStats, SessionCubit session)
      : super(PrivacyState(publicReadingStats: session.state.me?.publicReadingStats ?? false)) {
    _subscription = session.stream.listen((session) {
      final me = session.me;
      if (me != null && !state.pending && !isClosed) emit(PrivacyState(publicReadingStats: me.publicReadingStats));
    });
  }

  final SetPublicReadingStats _setPublicReadingStats;
  late final StreamSubscription<SessionState> _subscription;

  /// Null on success (or nothing to do), else the failure after rolling back.
  Future<Failure?> setPublicReadingStats(bool visible) async {
    if (state.pending || state.publicReadingStats == visible) return null;
    final before = state.publicReadingStats;
    emit(PrivacyState(publicReadingStats: visible, pending: true));
    final result = await _setPublicReadingStats(visible: visible);
    if (isClosed) return null;
    final failure = result.failureOrNull;
    emit(PrivacyState(publicReadingStats: failure == null ? visible : before));
    return failure;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
