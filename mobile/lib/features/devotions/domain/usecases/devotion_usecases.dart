import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/devotions.dart';
import '../repositories/devotions_repository.dart';

/// A surah of the private corner (F38), from the app's assets.
@injectable
class GetSurah {
  const GetSurah(this._repository);

  final DevotionsRepository _repository;

  Future<Result<Surah>> call(int number) => _repository.surah(number);
}

/// The morning and evening adhkar (F38), from the app's assets.
@injectable
class GetAdhkar {
  const GetAdhkar(this._repository);

  final DevotionsRepository _repository;

  Future<Result<AdhkarBook>> call() => _repository.adhkar();
}

/// The account's own du'as (F38), oldest first.
@injectable
class GetDuas {
  const GetDuas(this._repository);

  final DevotionsRepository _repository;

  Future<Result<List<PersonalDua>>> call() => _repository.duas();
}

/// Adds a du'a ([id] null) or replaces one.
@injectable
class SaveDua {
  const SaveDua(this._repository);

  final DevotionsRepository _repository;

  Future<Result<PersonalDua>> call(DuaDraft draft, {String? id}) =>
      id == null ? _repository.createDua(draft) : _repository.updateDua(id, draft);
}

@injectable
class DeleteDua {
  const DeleteDua(this._repository);

  final DevotionsRepository _repository;

  Future<Result<void>> call(String id) => _repository.deleteDua(id);
}
