import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/moderation.dart';

/// What the viewer reported in this app session (F22 store additions): the article, comment or repost collapses for
/// them at once, as `reportedByMe` makes it collapse on the next load («أبلغت عن هذا المحتوى، ولن يظهر لك بعد الآن»
/// with «عرض»). A reported user stays visible. Signing out or switching accounts clears it.
@lazySingleton
class ReportedContentCubit extends Cubit<Set<String>> {
  ReportedContentCubit(SessionCubit session) : super(const {}) {
    _userId = session.state.me?.id;
    _session = session.stream.listen((next) {
      final userId = next.isAuthenticated ? next.me?.id : null;
      if (next.status == SessionStatus.unknown || userId == _userId) return;
      _userId = userId;
      emit(const {});
    });
  }

  StreamSubscription<SessionState>? _session;
  String? _userId;

  static String keyOf(ModerationTargetType type, String id) => '${type.name}:$id';

  /// A report was sent: users are left out (they stay visible).
  void markReported(ModerationTargetRef target) {
    if (target.type == ModerationTargetType.user) return;
    emit({...state, keyOf(target.type, target.id)});
  }

  /// Whether to collapse it: reported in this session, or [fallback] (`reportedByMe` as loaded).
  bool isReported(ModerationTargetType type, String id, {bool fallback = false}) =>
      fallback || state.contains(keyOf(type, id));

  @override
  Future<void> close() async {
    await _session?.cancel();
    return super.close();
  }
}
