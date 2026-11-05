import '../domain/entities/search.dart';

/// Where search lives (F16): a full-screen page above the tabs, opened from Explore's search bar.
abstract final class SearchRoutes {
  static const path = '/search';

  /// `/search`, or `/search?q=&type=` to open on a query (searched at once) and a tab.
  static String of({String? query, SearchType? type}) {
    final params = {
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (type != null) 'type': type.name,
    };
    return params.isEmpty ? path : Uri(path: path, queryParameters: params).toString();
  }
}
