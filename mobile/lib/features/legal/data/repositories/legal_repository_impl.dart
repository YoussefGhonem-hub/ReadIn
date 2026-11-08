import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/legal.dart';
import '../../domain/repositories/legal_repository.dart';
import '../datasources/legal_api.dart';

@LazySingleton(as: LegalRepository)
class LegalRepositoryImpl implements LegalRepository {
  LegalRepositoryImpl(this._api);

  final LegalApi _api;

  @override
  Future<Result<LegalInfo>> getLegal() => guardApi(() async => (await _api.getLegal()).toEntity());
}
