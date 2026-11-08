import '../../../../core/errors/result.dart';
import '../entities/blocks.dart';

/// Block (F36). Bearer on every route; writes need `users.block` and use the `writes` rate limit.
abstract interface class BlocksRepository {
  /// `PUT /users/{id}/block` (idempotent): ends the follows both ways. `400 block.self`, `400 block.limit`,
  /// `404 user.not_found`.
  Future<Result<UserBlockState>> block(String userId);

  /// `DELETE /users/{id}/block?restoreFollow=`: [restoreFollow] follows them again (the block's Undo).
  Future<Result<UserBlockState>> unblock(String userId, {bool restoreFollow = false});

  /// `GET /me/blocked`: Settings → Blocked accounts, newest first.
  Future<Result<List<BlockedUser>>> blocked();
}
