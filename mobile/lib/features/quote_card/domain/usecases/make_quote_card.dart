import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/quote_card.dart';
import '../repositories/quote_card_repository.dart';

/// Draws one quote card (F24) on the server.
@injectable
class MakeQuoteCard {
  const MakeQuoteCard(this._repository);

  final QuoteCardRepository _repository;

  Future<Result<QuoteCardImage>> call(QuoteCardRequest request) => _repository.make(request);
}

/// Puts a drawn card in a temporary file, for the system share sheet.
@injectable
class PrepareQuoteCardFile {
  const PrepareQuoteCardFile(this._repository);

  final QuoteCardRepository _repository;

  Future<Result<String>> call(QuoteCardImage image) => _repository.temporaryFile(image);
}
