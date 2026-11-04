import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'unread_badge_cubit.dart';

enum NotificationsStatus { loading, ready, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.failure,
    this.loadMoreFailure,
    this.hasNew = false,
  });

  final NotificationsStatus status;

  /// Newest activity first.
  final List<AppNotification> items;
  final String? nextCursor;
  final bool loadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;

  /// Something arrived since the list loaded (the bell's count is above 0 again): the page offers to show it, as the web
  /// does.
  final bool hasNew;

  bool get hasMore => nextCursor != null;

  bool get hasUnread => items.any((notification) => !notification.isRead);

  NotificationsState copyWith({
    List<AppNotification>? items,
    String? Function()? nextCursor,
    bool? loadingMore,
    Failure? Function()? loadMoreFailure,
    bool? hasNew,
  }) =>
      NotificationsState(
        status: status,
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        loadingMore: loadingMore ?? this.loadingMore,
        failure: failure,
        loadMoreFailure: loadMoreFailure != null ? loadMoreFailure() : this.loadMoreFailure,
        hasNew: hasNew ?? this.hasNew,
      );

  @override
  List<Object?> get props => [status, items, nextCursor, loadingMore, failure, loadMoreFailure, hasNew];
}

/// The notification center (F17): pages of notifications (cursor, newest activity first). Opening it and pulling to
/// refresh mark everything seen (`POST /me/notifications/seen`, the badge goes to 0); an item stays unread until it is
/// opened ([markRead]) or "Mark all read" ([markAllRead]), both shown here at once. While it is open, new activity (the
/// bell's count going above 0) sets [NotificationsState.hasNew]; [refresh] shows it.
@injectable
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._list, this._seen, this._read, this._readAll, this._badge)
      : super(const NotificationsState()) {
    _badgeSubscription = _badge.stream.listen(_onBadge);
  }

  final GetNotifications _list;
  final MarkNotificationsSeen _seen;
  final MarkNotificationRead _read;
  final MarkAllNotificationsRead _readAll;
  final UnreadBadgeCubit _badge;
  late final StreamSubscription<int> _badgeSubscription;

  /// The bell's count as last heard. Opening the center clears it, so it starts at 0.
  int _badgeCount = 0;

  /// Incremented on every first-page load, so a page answered for an older one is dropped.
  int _generation = 0;

  /// The center was opened: everything is seen, and the first page loads.
  Future<void> open() async {
    unawaited(_markSeen());
    await _loadFirst();
  }

  /// Pull to refresh: the list stays while the first page reloads, and what arrived since is seen too. Returns the
  /// failure of a refresh that kept the old list, for a short message; a first load shows its error in place.
  Future<Failure?> refresh() async {
    unawaited(_markSeen());
    return _loadFirst();
  }

  Future<void> _markSeen() async {
    _badge.clear();
    await _seen();
  }

  Future<Failure?> _loadFirst() async {
    final generation = ++_generation;
    final keep = state.status == NotificationsStatus.ready;
    if (!keep) emit(const NotificationsState());
    final result = await _list();
    if (generation != _generation || isClosed) return null;
    switch (result) {
      case Err(:final failure) when keep:
        return failure;
      case Err(:final failure):
        emit(NotificationsState(status: NotificationsStatus.failure, failure: failure));
        return null;
      case Ok(value: final page):
        emit(NotificationsState(
          status: NotificationsStatus.ready,
          items: page.items,
          nextCursor: page.nextCursor,
          hasNew: _badgeCount > 0,
        ));
        return null;
    }
  }

  Future<void> loadMore() async {
    if (state.status != NotificationsStatus.ready || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreFailure: () => null));
    final result = await _list(cursor: state.nextCursor);
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(loadingMore: false, loadMoreFailure: () => failure)),
      (page) {
        // A row that moved since (new activity) is never listed twice.
        final known = {for (final item in state.items) item.id};
        emit(state.copyWith(
          loadingMore: false,
          items: [...state.items, ...page.items.where((item) => !known.contains(item.id))],
          nextCursor: () => page.nextCursor,
        ));
      },
    );
  }

  /// [notification] was opened: read here at once. It turns unread again if the request fails (offline), except when
  /// the notification is gone (`404 notification.not_found`).
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    _setRead({notification.id}, read: true);
    final failure = (await _read(notification.id)).failureOrNull;
    if (failure != null && failure.code != FailureCodes.notificationNotFound) _setRead({notification.id}, read: false);
  }

  /// "Mark all read": every row reads as read at once; they come back unread with the failure if the request fails.
  Future<Failure?> markAllRead() async {
    final unread = {for (final item in state.items) if (!item.isRead) item.id};
    if (unread.isEmpty) return null;
    _setRead(unread, read: true);
    final failure = (await _readAll()).failureOrNull;
    if (failure != null) _setRead(unread, read: false);
    return failure;
  }

  void _onBadge(int count) {
    _badgeCount = count;
    if (isClosed || state.status != NotificationsStatus.ready || state.hasNew == count > 0) return;
    emit(state.copyWith(hasNew: count > 0));
  }

  @override
  Future<void> close() async {
    await _badgeSubscription.cancel();
    return super.close();
  }

  void _setRead(Set<String> ids, {required bool read}) {
    if (isClosed) return;
    emit(state.copyWith(items: [
      for (final item in state.items) ids.contains(item.id) ? item.copyWith(isRead: read) : item,
    ]));
  }
}
