import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/article_pdf.dart';
import '../../domain/repositories/article_pdf_repository.dart';
import '../datasources/article_pdf_data_source.dart';

@LazySingleton(as: ArticlePdfRepository)
class ArticlePdfRepositoryImpl implements ArticlePdfRepository {
  ArticlePdfRepositoryImpl(this._source);

  final ArticlePdfDataSource _source;

  @override
  Future<Result<ArticlePdf>> download(String articleId, {required String language}) async {
    try {
      return await guardApi(() => _source.download(articleId, language: language));
    } on FileSystemException catch (e) {
      // The file couldn't be written (a full disk): the same "couldn't prepare the PDF", with "Try again".
      return Err(Failure(FailureCodes.articlePdfFailed, message: e.message));
    }
  }
}
