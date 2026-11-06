import '../../../../core/errors/result.dart';
import '../entities/quote_card.dart';

abstract interface class QuoteCardRepository {
  /// `POST /articles/{id}/quote-card` (SPEC F24): the PNG the API draws for [request]. Guests too. Usually under a
  /// second; the API may wait 10 s for a build slot and then draw for up to 20 s. Errors: `quote.*` (contract table),
  /// `article.not_found`, `network.offline`, `network.timeout`.
  Future<Result<QuoteCardImage>> make(QuoteCardRequest request);

  /// Writes [image] to a temporary file for the share sheet and returns its path.
  Future<Result<String>> temporaryFile(QuoteCardImage image);
}
