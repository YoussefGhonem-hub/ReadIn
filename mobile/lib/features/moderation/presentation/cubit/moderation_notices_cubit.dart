import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/moderation.dart';
import '../../domain/usecases/moderation_usecases.dart';

/// The signed-in user's unacknowledged moderation notices (F22): a warning, or one of their articles was hidden.
/// Loaded once the session is restored or a user signs in; each is shown as a dialog until "Got it". Empty for guests.
@lazySingleton
class ModerationNoticesCubit extends Cubit<List<ModerationNotice>> {
  ModerationNoticesCubit(this._getNotices, this._acknowledge, SessionCubit session) : super(const []) {
    _follow(session.state);
    _subscription = session.stream.listen(_follow);
  }

  final GetModerationNotices _getNotices;
  final AcknowledgeModerationNotice _acknowledge;
  StreamSubscription<SessionState>? _subscription;
  String? _userId;
  int _version = 0;

  void _follow(SessionState session) {
    if (session.status == SessionStatus.unknown) return; // the stored session isn't restored yet
    final userId = session.isAuthenticated ? session.me?.id : null;
    if (userId == _userId) return;
    _userId = userId;
    _version++;
    if (state.isNotEmpty) emit(const []);
    if (userId != null) unawaited(load());
  }

  /// `GET /me/moderation-notices`, oldest first. A failure (offline) waits for the next sign in or start.
  Future<void> load() async {
    if (_userId == null) return;
    final version = ++_version;
    final result = await _getNotices();
    if (isClosed || version != _version) return;
    if (result.valueOrNull case final notices?) emit(notices);
  }

  /// "Got it": the notice goes away here at once. If the call fails it comes back on the next start.
  Future<void> acknowledge(String noticeId) async {
    emit([for (final notice in state) if (notice.id != noticeId) notice]);
    await _acknowledge(noticeId);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
