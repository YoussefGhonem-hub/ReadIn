import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/domain/entities/me.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/usecases/profile_usecases.dart';

class PrivacyState extends Equatable {
  const PrivacyState({this.publicReadingStats = false, this.whoCanMention = MentionPolicy.everyone, this.pending = false});

  PrivacyState.of(PrivacySettings settings, {bool pending = false})
      : this(publicReadingStats: settings.publicReadingStats, whoCanMention: settings.whoCanMention, pending: pending);

  final bool publicReadingStats;
  final MentionPolicy whoCanMention;

  /// A change is being saved: the controls show the new value and ignore taps.
  final bool pending;

  PrivacySettings get settings => PrivacySettings(publicReadingStats: publicReadingStats, whoCanMention: whoCanMention);

  @override
  List<Object?> get props => [publicReadingStats, whoCanMention, pending];
}

/// Settings → Privacy and the own profile (F14, F18): "show my reading stats on my public profile" and "who can mention
/// me". A change is applied at once, sent as the whole privacy object (`PUT /me/privacy`) and rolled back when the API
/// refuses it. Otherwise it follows `MeDto.privacy` from the session.
@injectable
class PrivacyCubit extends Cubit<PrivacyState> {
  PrivacyCubit(this._setPrivacy, SessionCubit session)
      : super(PrivacyState.of(session.state.me?.privacy ?? const PrivacySettings())) {
    _subscription = session.stream.listen((session) {
      final me = session.me;
      if (me != null && !state.pending && !isClosed) emit(PrivacyState.of(me.privacy));
    });
  }

  final SetPrivacy _setPrivacy;
  late final StreamSubscription<SessionState> _subscription;

  /// Null on success (or nothing to do), else the failure after rolling back.
  Future<Failure?> setPublicReadingStats(bool visible) => _save(state.settings.copyWith(publicReadingStats: visible));

  /// Null on success (or nothing to do), else the failure after rolling back.
  Future<Failure?> setWhoCanMention(MentionPolicy policy) => _save(state.settings.copyWith(whoCanMention: policy));

  /// One change at a time: while one is saving, another is ignored (the controls are disabled anyway).
  Future<Failure?> _save(PrivacySettings next) async {
    final before = state.settings;
    if (state.pending || next == before) return null;
    emit(PrivacyState.of(next, pending: true));
    final result = await _setPrivacy(next);
    if (isClosed) return null;
    final failure = result.failureOrNull;
    emit(PrivacyState.of(failure == null ? next : before));
    return failure;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
