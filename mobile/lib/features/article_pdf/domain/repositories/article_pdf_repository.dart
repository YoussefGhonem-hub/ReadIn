import '../../../../core/errors/result.dart';
import '../entities/article_pdf.dart';

abstract interface class ArticlePdfRepository {
  /// `GET /articles/{id}/pdf?lang=` (SPEC F33): the published version of the writer's own article in [language]
  /// (`ar-EG` | `en`), saved to a temporary file. Built on request, so it can take up to about 90 seconds.
  Future<Result<ArticlePdf>> download(String articleId, {required String language});
}
