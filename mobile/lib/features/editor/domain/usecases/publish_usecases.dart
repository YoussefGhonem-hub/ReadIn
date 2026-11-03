import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../media/domain/entities/media.dart';
import '../entities/article_draft.dart';
import '../repositories/editor_repository.dart';

@injectable
class CreateArticleDraft {
  const CreateArticleDraft(this._repository);

  final EditorRepository _repository;

  Future<Result<CreatedArticle>> call(ArticleDraft draft) => _repository.createArticle(draft);
}

@injectable
class SetArticleAttachments {
  const SetArticleAttachments(this._repository);

  final EditorRepository _repository;

  Future<Result<void>> call(String articleId, List<AttachmentItem> items) => _repository.setAttachments(articleId, items);
}

@injectable
class PublishArticle {
  const PublishArticle(this._repository);

  final EditorRepository _repository;

  Future<Result<void>> call(String articleId) => _repository.publish(articleId);
}
