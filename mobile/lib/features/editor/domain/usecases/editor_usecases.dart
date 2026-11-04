import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../entities/editor_entities.dart';
import '../repositories/article_editor_repository.dart';

@injectable
class GetMyArticles {
  const GetMyArticles(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<CursorPage<MyArticle>>> call(ArticleLifecycle status, {String? cursor}) =>
      _repository.myArticles(status, cursor: cursor);
}

@injectable
class CreateArticle {
  const CreateArticle(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<ArticleEdit>> call(ArticleDraftDocument document) => _repository.create(document);
}

@injectable
class GetArticleForEdit {
  const GetArticleForEdit(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<ArticleEdit>> call(String id) => _repository.getForEdit(id);
}

@injectable
class SaveDraft {
  const SaveDraft(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<ArticleEdit>> call(String id, {required int baseVersion, required ArticleDraftDocument document}) =>
      _repository.saveDraft(id, baseVersion: baseVersion, document: document);
}

@injectable
class DiscardChanges {
  const DiscardChanges(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<ArticleEdit>> call(String id) => _repository.discardChanges(id);
}

@injectable
class PublishArticle {
  const PublishArticle(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<PublishedArticle>> call(String id, {required int baseVersion}) =>
      _repository.publish(id, baseVersion: baseVersion);
}

@injectable
class GetRevisions {
  const GetRevisions(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<List<ArticleRevision>>> call(String id) => _repository.revisions(id);
}

@injectable
class GetRevision {
  const GetRevision(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<ArticleRevisionDetails>> call(String id, int number) => _repository.revision(id, number);
}

@injectable
class RestoreRevision {
  const RestoreRevision(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<ArticleEdit>> call(String id, int number, {required int baseVersion}) =>
      _repository.restoreRevision(id, number, baseVersion: baseVersion);
}

@injectable
class DeleteArticle {
  const DeleteArticle(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}

@injectable
class SuggestTags {
  const SuggestTags(this._repository);

  final ArticleEditorRepository _repository;

  Future<Result<List<ArticleTag>>> call(String query) => _repository.suggestTags(query);
}
