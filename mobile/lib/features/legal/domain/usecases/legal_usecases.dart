import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/legal.dart';
import '../repositories/legal_repository.dart';

/// The Terms version in effect and what changed (F37), for the blocking terms screen.
@injectable
class GetLegal {
  const GetLegal(this._repository);

  final LegalRepository _repository;

  Future<Result<LegalInfo>> call() => _repository.getLegal();
}
