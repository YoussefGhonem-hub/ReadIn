import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../media/data/models/media_models.dart';
import '../../../media/domain/entities/media.dart';
import '../../domain/entities/article_draft.dart';
import '../../domain/repositories/editor_repository.dart';
import '../datasources/editor_api.dart';
import '../models/editor_models.dart';

@LazySingleton(as: EditorRepository)
class EditorRepositoryImpl implements EditorRepository {
  EditorRepositoryImpl(this._api);

  final EditorApi _api;

  @override
  Future<Result<CreatedArticle>> createArticle(ArticleDraft draft) =>
      guardApi(() async => (await _api.createArticle(CreateArticleRequestModel.fromDraft(draft))).toEntity());

  @override
  Future<Result<void>> setAttachments(String articleId, List<AttachmentItem> items) =>
      guardApi(() => _api.setAttachments(articleId, SetAttachmentsRequestModel.fromEntities(items)));

  @override
  Future<Result<void>> publish(String articleId) => guardApi(() => _api.publish(articleId));
}
