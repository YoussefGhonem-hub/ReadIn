import '../../../../core/errors/result.dart';
import '../entities/article_pdf.dart';

abstract interface class ArticlePdfRepository {
  /// `GET /articles/{id}/pdf?lang=` (SPEC F33): the published version in [language] (`ar-EG` | `en`) of any article the
  /// member can open (and the writer's own archived one), saved to a temporary file. Built on request, so it can take
  /// up to about 90 seconds.
  Future<Result<ArticlePdf>> download(String articleId, {required String language});
}
