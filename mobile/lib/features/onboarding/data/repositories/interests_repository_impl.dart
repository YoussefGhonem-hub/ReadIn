import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/repositories/interests_repository.dart';
import '../datasources/interests_api.dart';

@LazySingleton(as: InterestsRepository)
class InterestsRepositoryImpl implements InterestsRepository {
  InterestsRepositoryImpl(this._api);

  final InterestsApi _api;

  @override
  Future<Result<void>> saveInterests({required List<String> fieldIds, required List<String> topicIds}) =>
      guardApi(() => _api.update(UpdateInterestsRequest(fieldIds: fieldIds, topicIds: topicIds)));

  @override
  Future<Result<void>> setInterest(InterestKind kind, String id, {required bool followed}) =>
      guardApi(() => followed ? _api.follow(kind.path, id) : _api.unfollow(kind.path, id));
}
