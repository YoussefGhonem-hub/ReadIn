import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/devotions.dart';
import '../../domain/repositories/devotions_repository.dart';
import '../datasources/devotions_assets.dart';
import '../datasources/duas_api.dart';
import '../models/devotion_models.dart';

@LazySingleton(as: DevotionsRepository)
class DevotionsRepositoryImpl implements DevotionsRepository {
  DevotionsRepositoryImpl(this._api, this._assets);

  final DuasApi _api;
  final DevotionsAssets _assets;

  @override
  Future<Result<Surah>> surah(int number) => _asset(() => _assets.surah(number));

  @override
  Future<Result<AdhkarBook>> adhkar() => _asset(_assets.adhkar);

  @override
  Future<Result<List<PersonalDua>>> duas() =>
      guardApi(() async => [for (final dua in await _api.list()) dua.toEntity()]);

  @override
  Future<Result<PersonalDua>> createDua(DuaDraft draft) =>
      guardApi(() async => (await _api.create(DuaBody.of(draft))).toEntity());

  @override
  Future<Result<PersonalDua>> updateDua(String id, DuaDraft draft) =>
      guardApi(() async => (await _api.update(id, DuaBody.of(draft))).toEntity());

  @override
  Future<Result<void>> deleteDua(String id) => guardApi(() => _api.delete(id));

  /// A bundled text that can't be read is a bug in the build, not something to retry: one generic failure.
  static Future<Result<T>> _asset<T>(Future<T> Function() load) async {
    try {
      return Ok(await load());
    } on Object catch (e) {
      return Err(Failure(FailureCodes.serverError, message: '$e'));
    }
  }
}
