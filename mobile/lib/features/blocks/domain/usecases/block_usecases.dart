import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/blocks.dart';
import '../repositories/blocks_repository.dart';

/// Blocks or unblocks someone (F36). [restoreFollow] (unblock only) follows them again: the Undo of a block that ended
/// a follow.
@injectable
class SetUserBlocked {
  const SetUserBlocked(this._repository);

  final BlocksRepository _repository;

  Future<Result<UserBlockState>> call(String userId, {required bool blocked, bool restoreFollow = false}) =>
      blocked ? _repository.block(userId) : _repository.unblock(userId, restoreFollow: restoreFollow);
}

/// Settings → Blocked accounts.
@injectable
class GetBlockedUsers {
  const GetBlockedUsers(this._repository);

  final BlocksRepository _repository;

  Future<Result<List<BlockedUser>>> call() => _repository.blocked();
}
