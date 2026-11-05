import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/storage/key_value_store.dart';
import '../../domain/services/search_query.dart';

/// The last searches on this device (F16), newest first, guests included. They stay on the device: nothing is sent to
/// the API.
@lazySingleton
class RecentSearchesStore {
  RecentSearchesStore(this._store);

  static const key = 'search.recent';

  /// How many are kept.
  static const max = 10;

  final KeyValueStore _store;

  /// Newest first. Unreadable data counts as none.
  List<String> read() {
    final raw = _store.read<String>(key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [for (final item in list) if (item is String && item.trim().isNotEmpty) item].take(max).toList();
    } on FormatException {
      return const [];
    }
  }

  /// Puts [query] first. An older search for the same thing ([SearchQuery.key]: case, Arabic letter forms, `#` or
  /// `@`) is dropped, and only the newest [max] stay.
  Future<List<String>> add(String query) async {
    final text = SearchQuery.clean(query);
    if (text.isEmpty) return read();
    final key = SearchQuery.key(text);
    return _write([text, ...read().where((q) => SearchQuery.key(q) != key)].take(max).toList());
  }

  /// Removes [query] (and anything that is the same search).
  Future<List<String>> remove(String query) async {
    final key = SearchQuery.key(query);
    return _write(read().where((q) => SearchQuery.key(q) != key).toList());
  }

  Future<void> clear() => _store.delete(key);

  Future<List<String>> _write(List<String> list) async {
    if (list.isEmpty) {
      await _store.delete(key);
    } else {
      await _store.write(key, jsonEncode(list));
    }
    return list;
  }
}
