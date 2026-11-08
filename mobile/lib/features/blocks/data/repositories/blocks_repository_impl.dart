import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/blocks.dart';
import '../../domain/repositories/blocks_repository.dart';
import '../datasources/blocks_api.dart';

@LazySingleton(as: BlocksRepository)
class BlocksRepositoryImpl implements BlocksRepository {
  BlocksRepositoryImpl(this._api);

  final BlocksApi _api;

  @override
  Future<Result<UserBlockState>> block(String userId) => guardApi(() async => (await _api.block(userId)).toEntity());

  @override
  Future<Result<UserBlockState>> unblock(String userId, {bool restoreFollow = false}) =>
      guardApi(() async => (await _api.unblock(userId, restoreFollow ? true : null)).toEntity());

  @override
  Future<Result<List<BlockedUser>>> blocked() =>
      guardApi(() async => [for (final item in (await _api.blocked()).items) item.toEntity()]);
}
