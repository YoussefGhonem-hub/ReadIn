import 'package:equatable/equatable.dart';

/// An offset page of an admin table (`PagedList<T>`, SPEC §17.1): `?page=&pageSize=`, at most 100 rows a page. A page
/// past the end has no items and the real [totalCount].
class PagedList<T> extends Equatable {
  const PagedList({required this.items, this.page = 1, this.pageSize = 50, this.totalCount = 0, this.totalPages = 0});

  final List<T> items;

  /// 1-based, as the API used it.
  final int page;
  final int pageSize;
  final int totalCount;

  /// `ceil(totalCount / pageSize)`; 0 when empty.
  final int totalPages;

  bool get hasNext => page < totalPages;

  @override
  List<Object?> get props => [items, page, pageSize, totalCount, totalPages];
}

/// Reads a wire name; null for a name this app version doesn't know.
T? wireEnum<T extends Enum>(List<T> values, String? wire, String Function(T value) nameOf) =>
    wire == null ? null : values.where((value) => nameOf(value) == wire).firstOrNull;

/// `YYYY-MM-DD` of [date] as written (a calendar date in `Admin:TimeZone`, not a moment).
String adminDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
