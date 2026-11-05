import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../entities/article_pdf.dart';
import '../repositories/article_pdf_repository.dart';

@injectable
class DownloadArticlePdf {
  const DownloadArticlePdf(this._repository);

  final ArticlePdfRepository _repository;

  Future<Result<ArticlePdf>> call(String articleId, {required String language}) =>
      _repository.download(articleId, language: language);
}
