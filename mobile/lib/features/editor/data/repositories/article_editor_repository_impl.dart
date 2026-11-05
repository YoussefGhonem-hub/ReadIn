import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../tags/domain/services/tag_names.dart';
import '../../domain/entities/editor_entities.dart';
import '../../domain/repositories/article_editor_repository.dart';
import '../../domain/services/draft_checker.dart';
import '../datasources/article_editor_api.dart';
import '../models/article_editor_models.dart';

@LazySingleton(as: ArticleEditorRepository)
class ArticleEditorRepositoryImpl implements ArticleEditorRepository {
  ArticleEditorRepositoryImpl(this._api);

  final ArticleEditorApi _api;

  static ArticleDraftDocumentModel _body(ArticleDraftDocument document) =>
      ArticleDraftDocumentModel.fromEntity(document.forSave());

  @override
  Future<Result<CursorPage<MyArticle>>> myArticles(ArticleLifecycle status, {String? cursor, int limit = 20}) =>
      guardApi(() async {
        final page = await _api.myArticles(status.name, cursor: cursor, limit: limit);
        return CursorPage(items: [for (final a in page.items) a.toEntity()], nextCursor: page.nextCursor);
      });

  @override
  Future<Result<ArticleEdit>> create(ArticleDraftDocument document) =>
      guardApi(() async => (await _api.create(_body(document))).toEntity());

  @override
  Future<Result<ArticleEdit>> getForEdit(String id) => guardApi(() async => (await _api.getForEdit(id)).toEntity());

  @override
  Future<Result<ArticleEdit>> saveDraft(String id, {required int baseVersion, required ArticleDraftDocument document}) =>
      guardApi(() async =>
          (await _api.saveDraft(id, SaveDraftRequestModel(baseVersion: baseVersion, document: _body(document)))).toEntity());

  @override
  Future<Result<ArticleEdit>> discardChanges(String id) =>
      guardApi(() async => (await _api.discardChanges(id)).toEntity());

  @override
  Future<Result<PublishedArticle>> publish(String id, {required int baseVersion}) async {
    DraftProblemsFailure? problems;
    final result = await guardApi(() async {
      try {
        return (await _api.publish(id, BaseVersionRequestModel(baseVersion: baseVersion))).toEntity();
      } on DioException catch (e) {
        problems = problemsFailure(e.response?.statusCode, e.response?.data);
        rethrow;
      }
    });
    final refused = problems;
    return refused != null ? Err(refused) : result;
  }

  /// The publish `400`: a ProblemDetails whose `code` is the first problem's, with every problem in `problems`.
  static DraftProblemsFailure? problemsFailure(int? status, Object? body) {
    if (status != 400 || body is! Map || body['problems'] is! List) return null;
    final problems = [
      for (final p in body['problems'] as List)
        if (p is Map<String, dynamic> && p['code'] is String) DraftProblemModel.fromJson(p).toEntity(),
    ];
    final code = body['code'] as String? ?? problems.firstOrNull?.code ?? FailureCodes.validationFailed;
    return DraftProblemsFailure(code, problems: problems, statusCode: status, message: body['title'] as String?);
  }

  @override
  Future<Result<List<ArticleRevision>>> revisions(String id) =>
      guardApi(() async => [for (final r in await _api.revisions(id)) r.toEntity()]);

  @override
  Future<Result<ArticleRevisionDetails>> revision(String id, int number) =>
      guardApi(() async => (await _api.revision(id, number)).toEntity());

  @override
  Future<Result<ArticleEdit>> restoreRevision(String id, int number, {required int baseVersion}) => guardApi(
      () async => (await _api.restoreRevision(id, number, BaseVersionRequestModel(baseVersion: baseVersion))).toEntity());

  @override
  Future<Result<void>> delete(String id) => guardApi(() => _api.deleteArticle(id));

  @override
  Future<Result<List<ArticleTag>>> suggestTags(String query) =>
      guardApi(() async => [for (final t in await _api.tags(TagNames.clean(query))) t.toEntity()]);
}
