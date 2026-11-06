import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/quote_card.dart';
import '../../domain/repositories/quote_card_repository.dart';
import '../datasources/quote_card_data_source.dart';

@LazySingleton(as: QuoteCardRepository)
class QuoteCardRepositoryImpl implements QuoteCardRepository {
  QuoteCardRepositoryImpl(this._source);

  final QuoteCardDataSource _source;

  @override
  Future<Result<QuoteCardImage>> make(QuoteCardRequest request) => guardApi(() => _source.make(request));

  @override
  Future<Result<String>> temporaryFile(QuoteCardImage image) async {
    try {
      return Ok(await _source.temporaryFile(image));
    } on FileSystemException catch (e) {
      // A full disk: the sheet says the card couldn't be shared.
      return Err(Failure(FailureCodes.quoteFailed, message: e.message));
    }
  }
}
