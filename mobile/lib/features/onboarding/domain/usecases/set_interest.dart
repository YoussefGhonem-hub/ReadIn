import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../repositories/interests_repository.dart';

/// Follows or unfollows one field or topic after onboarding (Settings → Your interests; F02, F12). Once the API has
/// it, `/me` is read again, so the session's interests follow: Home's For you and suggestions use them.
@injectable
class SetInterest {
  const SetInterest(this._repository, this._accounts);

  final InterestsRepository _repository;
  final AccountRepository _accounts;

  Future<Result<void>> call(InterestKind kind, String id, {required bool followed}) async {
    final result = await _repository.setInterest(kind, id, followed: followed);
    if (result.isOk) await _accounts.getMe();
    return result;
  }
}
