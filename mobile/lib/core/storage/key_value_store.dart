import 'package:hive_ce/hive.dart';

/// Small persistent key/value store (settings, flags, small caches).
/// Abstracted so blocs/repositories can be unit-tested with [InMemoryKeyValueStore].
abstract interface class KeyValueStore {
  T? read<T>(String key);
  Future<void> write<T>(String key, T value);
  Future<void> delete(String key);
}

class HiveKeyValueStore implements KeyValueStore {
  HiveKeyValueStore(this._box);

  static const boxName = 'readin.kv';

  final Box<dynamic> _box;

  static Future<HiveKeyValueStore> open() async => HiveKeyValueStore(await Hive.openBox<dynamic>(boxName));

  @override
  T? read<T>(String key) {
    final value = _box.get(key);
    return value is T ? value : null;
  }

  @override
  Future<void> write<T>(String key, T value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);
}

class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, Object?>? seed]) : _values = {...?seed};

  final Map<String, Object?> _values;

  @override
  T? read<T>(String key) {
    final value = _values[key];
    return value is T ? value : null;
  }

  @override
  Future<void> write<T>(String key, T value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}
