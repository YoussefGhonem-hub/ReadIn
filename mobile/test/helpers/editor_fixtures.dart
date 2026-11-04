import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/core/models/transfer.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/editor/domain/repositories/article_editor_repository.dart';
import 'package:readin/features/editor/presentation/cubit/article_editor_cubit.dart';
import 'package:readin/features/editor/presentation/cubit/my_articles_cubit.dart';
import 'package:readin/features/editor/presentation/cubit/revisions_cubit.dart';
import 'package:readin/features/editor/presentation/cubit/tag_suggestions_cubit.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/media/domain/repositories/media_repository.dart';
import 'package:readin/features/media/presentation/cubit/attachments_cubit.dart';
import 'package:readin/features/taxonomy/domain/entities/field.dart';
import 'package:readin/features/taxonomy/domain/repositories/taxonomy_repository.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import 'fixtures.dart';
import 'media_fixtures.dart';

class MockArticleEditorCubit extends MockCubit<ArticleEditorState> implements ArticleEditorCubit {}

class MockMyArticlesCubit extends MockCubit<MyArticlesState> implements MyArticlesCubit {}

class MockRevisionsCubit extends MockCubit<RevisionsState> implements RevisionsCubit {}

class MockTagSuggestionsCubit extends MockCubit<List<ArticleTag>> implements TagSuggestionsCubit {}

class MockAttachmentsCubit extends MockCubit<AttachmentsState> implements AttachmentsCubit {}

const editorFields = [
  Field(id: 'f-dotnet', slug: 'dotnet', nameAr: '.NET', nameEn: '.NET', requiresSources: true),
  Field(id: 'f-ai', slug: 'ai', nameAr: 'الذكاء الاصطناعي', nameEn: 'AI'),
];

const editorTopics = [
  Topic(id: 't-di', fieldId: 'f-dotnet', slug: 'di', nameAr: 'Dependency Injection', nameEn: 'Dependency Injection'),
  Topic(id: 't-ef', fieldId: 'f-dotnet', slug: 'ef-core', nameAr: 'EF Core', nameEn: 'EF Core'),
];

/// A mixed Arabic/English article body: paragraph, heading, callout, code, table, list and quote.
RDocDocument mixedContent(String language) => RDocDocument.fromJson({
      'version': 1,
      'language': language,
      'blocks': [
        {
          'id': 'p1',
          'type': 'paragraph',
          'content': [
            {'type': 'text', 'text': 'لو انت شغال بـ '},
            {'type': 'text', 'text': 'ASP.NET Core', 'marks': [{'type': 'bold'}]},
            {'type': 'text', 'text': '، أكيد شفت الـ '},
            {'type': 'term', 'termId': 'dependency-injection', 'text': 'Dependency Injection'},
            {'type': 'text', 'text': ' في كل حتة. شكراً لـ '},
            {'type': 'mention', 'userId': '0195f3a0-0000-7000-8000-000000000001', 'text': '@editorial'},
            {'type': 'text', 'text': '.'},
          ],
        },
        {
          'id': 'h1',
          'type': 'heading',
          'level': 2,
          'content': [
            {'type': 'text', 'text': 'الفرق بين '},
            {'type': 'text', 'text': 'Scoped', 'marks': [{'type': 'code'}]},
            {'type': 'text', 'text': ' و Transient'},
          ],
        },
        {
          'id': 'c1',
          'type': 'callout',
          'variant': 'tip',
          'title': 'نصيحة',
          'content': [
            {'type': 'text', 'text': 'استخدم '},
            {'type': 'text', 'text': 'AddScoped', 'marks': [{'type': 'code'}]},
            {'type': 'text', 'text': ' لأي service بتتعامل مع DbContext.'},
          ],
        },
        {
          'id': 'code1',
          'type': 'code',
          'lang': 'csharp',
          'filename': 'Program.cs',
          'code': 'builder.Services.AddScoped<IOrderService, OrderService>();',
        },
        {
          'id': 'tbl',
          'type': 'table',
          'header': [
            [{'type': 'text', 'text': 'الـ Lifetime'}],
            [{'type': 'text', 'text': 'بيتعمل امتى؟'}],
          ],
          'rows': [
            [
              [{'type': 'text', 'text': 'Scoped', 'marks': [{'type': 'code'}]}],
              [{'type': 'text', 'text': 'مرة لكل request.'}],
            ],
            [
              [{'type': 'text', 'text': 'Transient', 'marks': [{'type': 'code'}]}],
              [{'type': 'text', 'text': 'كل مرة تطلبه.'}],
            ],
          ],
        },
        {
          'id': 'ul',
          'type': 'bulletList',
          'items': [
            [{'type': 'text', 'text': 'Use DI everywhere (حتى في الـ tests).'}],
            [{'type': 'text', 'text': 'الـ lifetime بيتدار في مكان واحد.'}],
          ],
        },
        {
          'id': 'q1',
          'type': 'quote',
          'cite': 'Martin Fowler',
          'content': [{'type': 'text', 'text': 'Inversion of Control is a common phenomenon.'}],
        },
      ],
    });

ArticleDraftDocument mixedDocument({bool withTranslation = false, bool complete = true}) => ArticleDraftDocument(
      sourceLanguage: ArticleLanguages.ar,
      translations: [
        DraftTranslation(
          language: ArticleLanguages.ar,
          title: complete ? 'إزاي تختار بين Scoped و Transient في ASP.NET Core؟' : 'DI',
          subtitle: 'مقارنة عملية بأمثلة من مشروع حقيقي',
          content: mixedContent(ArticleLanguages.ar),
        ),
        if (withTranslation)
          DraftTranslation(
            language: ArticleLanguages.en,
            title: 'Scoped or Transient in ASP.NET Core?',
            content: RDocDocument.fromJson({
              'version': 1,
              'language': 'en',
              'blocks': [
                {
                  'id': 'e1',
                  'type': 'paragraph',
                  'content': [{'type': 'text', 'text': 'Pick the lifetime that matches the DbContext.'}],
                },
              ],
            }),
          ),
      ],
      fieldId: complete ? 'f-dotnet' : null,
      topicId: complete ? 't-di' : null,
      tags: const ['aspnetcore', 'di'],
      sources: complete ? const [ArticleSource(title: 'ASP.NET Core docs', url: 'https://learn.microsoft.com/aspnet/core')] : const [],
      versionBadge: '.NET 10',
      isAiAssisted: true,
    );

ArticleEdit sampleEdit({
  String id = 'art-1',
  ArticleLifecycle status = ArticleLifecycle.draft,
  int version = 3,
  ArticleDraftDocument? document,
  DraftChecks checks = const DraftChecks(readingTime: [ReadingTime(language: 'ar-EG', minutes: 6, words: 1080)]),
  bool hasUnpublishedChanges = false,
  DateTime? savedAt,
  List<MediaAsset> media = const [],
}) =>
    ArticleEdit(
      id: id,
      status: status,
      slug: status == ArticleLifecycle.published ? 'scoped-vs-transient' : null,
      publishedAt: status == ArticleLifecycle.published ? DateTime.utc(2026, 10, 20, 9) : null,
      version: version,
      savedAt: savedAt ?? DateTime.utc(2026, 11, 2, 10),
      hasUnpublishedChanges: hasUnpublishedChanges,
      document: document ?? mixedDocument(),
      media: media,
      checks: checks,
    );

List<MyArticle> sampleMyArticles(ArticleLifecycle status) => status == ArticleLifecycle.draft
    ? [
        MyArticle(
          id: 'd1',
          status: ArticleLifecycle.draft,
          language: 'ar-EG',
          title: 'إزاي تختار بين Scoped و Transient في ASP.NET Core؟',
          field: dotnetField,
          readingTimeMinutes: 6,
          savedAt: DateTime.utc(2026, 11, 2, 10),
        ),
        MyArticle(id: 'd2', status: ArticleLifecycle.draft, language: 'en', title: '', savedAt: DateTime.utc(2026, 11, 1, 18)),
        MyArticle(
          id: 'd3',
          status: ArticleLifecycle.draft,
          language: 'en',
          title: 'Prompt caching with Claude: a practical guide',
          field: aiField,
          readingTimeMinutes: 4,
          savedAt: DateTime.utc(2026, 10, 30, 8),
        ),
      ]
    : [
        MyArticle(
          id: 'p1',
          status: ArticleLifecycle.published,
          slug: 'di-in-dotnet',
          language: 'ar-EG',
          title: 'يعني إيه Dependency Injection في .NET؟',
          field: dotnetField,
          readingTimeMinutes: 7,
          savedAt: DateTime.utc(2026, 11, 2, 12),
          publishedAt: DateTime.utc(2026, 10, 20, 9),
          hasUnpublishedChanges: true,
          reactionCount: 42,
          commentCount: 7,
          readCount: 1200,
        ),
        MyArticle(
          id: 'p2',
          status: ArticleLifecycle.published,
          slug: 'ai-agents',
          language: 'ar-EG',
          title: 'الـ AI Agents هتغيّر طريقة شغلك إزاي؟',
          field: aiField,
          readingTimeMinutes: 5,
          savedAt: DateTime.utc(2026, 10, 12, 9),
          publishedAt: DateTime.utc(2026, 10, 12, 9),
        ),
      ];

final sampleRevisions = [
  ArticleRevision(number: 3, createdAt: DateTime.utc(2026, 11, 1, 9), title: 'يعني إيه Dependency Injection في .NET؟', languages: const ['ar-EG', 'en']),
  ArticleRevision(number: 2, createdAt: DateTime.utc(2026, 10, 25, 9), title: 'يعني إيه Dependency Injection في .NET؟', languages: const ['ar-EG']),
  ArticleRevision(number: 1, createdAt: DateTime.utc(2026, 10, 20, 9), title: 'يعني إيه DI؟', languages: const ['ar-EG']),
];

/// Scriptable [ArticleEditorRepository]: every call is recorded; set the `on…` handlers per test.
class FakeArticleEditorRepository implements ArticleEditorRepository {
  final calls = <String>[];
  final saved = <({String id, int baseVersion, ArticleDraftDocument document})>[];

  FutureOr<Result<CursorPage<MyArticle>>> Function(ArticleLifecycle status, String? cursor)? onList;
  FutureOr<Result<ArticleEdit>> Function(ArticleDraftDocument document)? onCreate;
  FutureOr<Result<ArticleEdit>> Function(String id)? onGet;
  FutureOr<Result<ArticleEdit>> Function(String id, int baseVersion, ArticleDraftDocument document)? onSave;
  FutureOr<Result<ArticleEdit>> Function(String id)? onDiscard;
  FutureOr<Result<PublishedArticle>> Function(String id, int baseVersion)? onPublish;
  FutureOr<Result<ArticleEdit>> Function(String id, int number, int baseVersion)? onRestore;
  FutureOr<Result<void>> Function(String id)? onDelete;

  @override
  Future<Result<CursorPage<MyArticle>>> myArticles(ArticleLifecycle status, {String? cursor, int limit = 20}) async {
    calls.add('list ${status.name}${cursor == null ? '' : ' $cursor'}');
    return onList!(status, cursor);
  }

  @override
  Future<Result<ArticleEdit>> create(ArticleDraftDocument document) async {
    calls.add('create');
    return onCreate!(document);
  }

  @override
  Future<Result<ArticleEdit>> getForEdit(String id) async {
    calls.add('get $id');
    return onGet!(id);
  }

  @override
  Future<Result<ArticleEdit>> saveDraft(String id, {required int baseVersion, required ArticleDraftDocument document}) async {
    calls.add('save $id v$baseVersion');
    saved.add((id: id, baseVersion: baseVersion, document: document));
    return onSave!(id, baseVersion, document);
  }

  @override
  Future<Result<ArticleEdit>> discardChanges(String id) async {
    calls.add('discard $id');
    return onDiscard!(id);
  }

  @override
  Future<Result<PublishedArticle>> publish(String id, {required int baseVersion}) async {
    calls.add('publish $id v$baseVersion');
    return onPublish!(id, baseVersion);
  }

  @override
  Future<Result<List<ArticleRevision>>> revisions(String id) async => Ok(sampleRevisions);

  @override
  Future<Result<ArticleRevisionDetails>> revision(String id, int number) async =>
      Ok(ArticleRevisionDetails(revision: sampleRevisions.firstWhere((r) => r.number == number), document: mixedDocument()));

  @override
  Future<Result<ArticleEdit>> restoreRevision(String id, int number, {required int baseVersion}) async {
    calls.add('restore $id #$number v$baseVersion');
    return onRestore!(id, number, baseVersion);
  }

  @override
  Future<Result<void>> delete(String id) async {
    calls.add('delete $id');
    return onDelete!(id);
  }

  @override
  Future<Result<List<ArticleTag>>> suggestTags(String query) async => const Ok([]);
}

class FakeTaxonomyRepository implements TaxonomyRepository {
  @override
  Future<Result<List<Field>>> getFields({bool refresh = false}) async => const Ok(editorFields);

  @override
  Future<Result<List<Topic>>> getTopics(String fieldSlug) async =>
      Ok([for (final t in editorTopics) if (editorFields.firstWhere((f) => f.id == t.fieldId).slug == fieldSlug) t]);
}

class FakeMediaRepository implements MediaRepository {
  Result<MediaAsset> Function(PickedMediaFile file, String purpose)? onUpload;
  final purposes = <String>[];

  @override
  Future<Result<MediaAsset>> uploadImage(PickedMediaFile file, {String purpose = 'image', TransferToken? token, TransferProgress? onProgress}) async {
    purposes.add(purpose);
    return onUpload?.call(file, purpose) ?? Ok(imageAsset('up-${purposes.length}'));
  }

  @override
  Future<Result<MediaAsset>> uploadDocument(PickedMediaFile file,
          {required String title, required bool allowDownload, TransferToken? token, TransferProgress? onProgress}) async =>
      const Err(Failure(FailureCodes.serverError));

  @override
  Future<Result<MediaAsset>> getUpload(String id) async => Ok(imageAsset(id));

  @override
  Future<Result<void>> deleteUpload(String id) async => const Ok(null);

  @override
  Future<Result<String>> downloadDocument(String url, {required String fileName, TransferToken? token, TransferProgress? onProgress}) async =>
      const Err(Failure(FailureCodes.serverError));
}
