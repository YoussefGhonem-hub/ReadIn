import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/update_policy.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/app_update_api.dart';
import '../datasources/installed_app_source.dart';
import '../datasources/update_policy_cache.dart';

@LazySingleton(as: AppUpdateRepository)
class AppUpdateRepositoryImpl implements AppUpdateRepository {
  AppUpdateRepositoryImpl(this._api, this._cache, this._installed);

  final AppUpdateApi _api;
  final UpdatePolicyCache _cache;
  final InstalledAppSource _installed;

  @override
  Future<InstalledApp?> installedApp() => _installed.read();

  @override
  UpdatePolicy? cachedPolicy() => _cache.read()?.toEntity();

  @override
  Future<Result<UpdatePolicy>> fetchPolicy() => guardApi(() async {
        final policy = await _api.policy();
        try {
          await _cache.write(policy);
        } catch (_) {
          // Not saved: it still applies now, and the next check saves it.
        }
        return policy.toEntity();
      });
}
