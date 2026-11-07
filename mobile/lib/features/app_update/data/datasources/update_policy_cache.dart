import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/storage/key_value_store.dart';
import '../models/update_policy_models.dart';

/// The last update policy the server sent, as JSON in the key/value store: an app told to update stays blocked when it
/// starts offline.
@lazySingleton
class UpdatePolicyCache {
  UpdatePolicyCache(this._store);

  static const key = 'appUpdate.policy';

  final KeyValueStore _store;

  /// Null when none was saved, or it can't be read.
  UpdatePolicyModel? read() {
    final raw = _store.read<String>(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      return json is Map<String, dynamic> ? UpdatePolicyModel.fromJson(json) : null;
    } on Object {
      return null; // not JSON, or not a policy
    }
  }

  Future<void> write(UpdatePolicyModel policy) => _store.write(key, jsonEncode(policy.toJson()));
}
