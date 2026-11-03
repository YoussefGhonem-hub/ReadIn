import 'package:equatable/equatable.dart';

/// Cursor-paginated slice of a feed (SPEC §17.1): `{ items, nextCursor }`.
class CursorPage<T> extends Equatable {
  const CursorPage({required this.items, this.nextCursor});

  final List<T> items;

  /// Opaque cursor for the next page; null when the feed is exhausted.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [items, nextCursor];
}
