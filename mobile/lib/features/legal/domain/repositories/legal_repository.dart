import '../../../../core/errors/result.dart';
import '../entities/legal.dart';

/// Legal (F37).
abstract interface class LegalRepository {
  /// `GET /legal`: the Terms version in effect and what changed.
  Future<Result<LegalInfo>> getLegal();
}
