import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/update_policy.dart';
import '../repositories/app_update_repository.dart';

/// Whether this version must be updated before the app can be used. Null: it needn't.
@injectable
class CheckAppUpdate {
  const CheckAppUpdate(this._repository);

  final AppUpdateRepository _repository;

  /// From the last policy saved on this device: works offline.
  Future<UpdateRequirement?> cached() async {
    final app = await _repository.installedApp();
    final policy = _repository.cachedPolicy();
    return app == null || policy == null ? null : UpdateRequirement.of(policy, app);
  }

  /// From the server's policy (saved for [cached]). Err when it couldn't be read: keep what [cached] said.
  Future<Result<UpdateRequirement?>> fetch() async {
    final app = await _repository.installedApp();
    if (app == null) return const Ok(null);
    return switch (await _repository.fetchPolicy()) {
      Ok(:final value) => Ok(UpdateRequirement.of(value, app)),
      Err(:final failure) => Err(failure),
    };
  }
}
