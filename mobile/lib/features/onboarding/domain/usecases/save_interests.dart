import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../repositories/interests_repository.dart';

@injectable
class SaveInterests {
  const SaveInterests(this._repository);

  final InterestsRepository _repository;

  /// Minimum number of interests (fields + topics) — SPEC §11 F02.
  static const minimum = 3;

  Future<Result<void>> call({required List<String> fieldIds, required List<String> topicIds}) async {
    if (fieldIds.length + topicIds.length < minimum) {
      return const Err(Failure(FailureCodes.interestsMinThree));
    }
    return _repository.saveInterests(fieldIds: fieldIds, topicIds: topicIds);
  }
}
