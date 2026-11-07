import '../../../../core/errors/result.dart';
import '../entities/update_policy.dart';

/// The forced update check: `GET /app/update-policy` (anonymous) and the last policy this device received.
abstract interface class AppUpdateRepository {
  /// This install; null where there's no store to update from (tests, desktop).
  Future<InstalledApp?> installedApp();

  /// The last policy [fetchPolicy] received, kept on the device so an app told to update stays blocked offline.
  UpdatePolicy? cachedPolicy();

  /// The server's policy, saved for [cachedPolicy]. Err when offline or the answer is unreadable.
  Future<Result<UpdatePolicy>> fetchPolicy();
}
