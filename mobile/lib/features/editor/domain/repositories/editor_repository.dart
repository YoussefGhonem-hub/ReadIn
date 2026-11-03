import '../../../../core/errors/result.dart';
import '../../../media/domain/entities/media.dart';
import '../entities/article_draft.dart';

abstract interface class EditorRepository {
  /// `POST /articles` → `201 { id, slug }` (draft).
  Future<Result<CreatedArticle>> createArticle(ArticleDraft draft);

  /// `PUT /articles/{id}/attachments` — replaces the whole attachment set.
  Future<Result<void>> setAttachments(String articleId, List<AttachmentItem> items);

  /// `POST /articles/{id}/publish`.
  Future<Result<void>> publish(String articleId);
}
