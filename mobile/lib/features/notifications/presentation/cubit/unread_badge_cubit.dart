import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/realtime/realtime_service.dart';

/// Live unread-notification count for the bell (F27, `/live/users/{id}`).
@injectable
class UnreadBadgeCubit extends Cubit<int> {
  UnreadBadgeCubit(this._realtime) : super(_realtime.unreadNotifications.value) {
    _realtime.unreadNotifications.addListener(_onChange);
  }

  final RealtimeService _realtime;

  void _onChange() => emit(_realtime.unreadNotifications.value);

  @override
  Future<void> close() {
    _realtime.unreadNotifications.removeListener(_onChange);
    return super.close();
  }
}
