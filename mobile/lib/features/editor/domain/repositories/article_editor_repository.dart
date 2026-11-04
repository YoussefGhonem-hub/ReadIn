import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../entities/editor_backup.dart';
import '../entities/editor_entities.dart';

abstract interface class ArticleEditorRepository {
  /// `GET /me/articles?status=`.
  Future<Result<CursorPage<MyArticle>>> myArticles(ArticleLifecycle status, {String? cursor, int limit = 20});

  /// `POST /articles`: creates a never-published draft.
  Future<Result<ArticleEdit>> create(ArticleDraftDocument document);

  /// `GET /articles/{id}/edit`.
  Future<Result<ArticleEdit>> getForEdit(String id);

  /// `PUT /articles/{id}/draft`; `409 article.draft_conflict` when [baseVersion] is stale.
  Future<Result<ArticleEdit>> saveDraft(String id, {required int baseVersion, required ArticleDraftDocument document});

  /// `DELETE /articles/{id}/draft`: back to the live version.
  Future<Result<ArticleEdit>> discardChanges(String id);

  /// `POST /articles/{id}/publish`. A refusal for open problems is a [DraftProblemsFailure].
  Future<Result<PublishedArticle>> publish(String id, {required int baseVersion});

  Future<Result<List<ArticleRevision>>> revisions(String id);

  Future<Result<ArticleRevisionDetails>> revision(String id, int number);

  /// Copies a revision into the working copy.
  Future<Result<ArticleEdit>> restoreRevision(String id, int number, {required int baseVersion});

  /// `DELETE /articles/{id}`.
  Future<Result<void>> delete(String id);

  /// `GET /tags?q=`.
  Future<Result<List<ArticleTag>>> suggestTags(String query);
}

/// Unsaved changes on this device, one copy per article (or [EditorBackup.newArticleKey] before it exists).
abstract interface class EditorBackupStore {
  Future<EditorBackup?> read(String key);

  Future<void> write(EditorBackup backup);

  Future<void> delete(String key);
}
