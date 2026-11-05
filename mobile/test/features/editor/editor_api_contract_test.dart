import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/editor/data/datasources/article_editor_api.dart';
import 'package:readin/features/editor/data/datasources/editor_backup_store.dart';
import 'package:readin/features/editor/data/repositories/article_editor_repository_impl.dart';
import 'package:readin/features/editor/domain/entities/editor_backup.dart';
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/editor_fixtures.dart';
import '../../helpers/fake_auth.dart';
import '../../helpers/test_app.dart';

/// The F05 editor endpoints against the contract: method, path, query, body, and how the answers parse.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late ArticleEditorRepositoryImpl repository;

  setUp(() {
    requests = [];
    respond = (_) => null;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = ScriptedAdapter((options) {
        requests.add(options);
        final body = respond(options);
        if (body is (int, Object?)) return body;
        return (200, body);
      });
    repository = ArticleEditorRepositoryImpl(ArticleEditorApi(dio));
  });

  String call(int i) => '${requests[i].method} ${requests[i].uri.path.replaceFirst('/api/v1', '')}';

  final kitchenSink = readSharedJson('rdoc/examples/kitchen-sink.ar-EG.json');

  final documentJson = {
    'sourceLanguage': 'ar-EG',
    'translations': [
      {'language': 'ar-EG', 'title': 'يعني إيه Dependency Injection؟', 'subtitle': null, 'content': kitchenSink},
      {
        'language': 'en',
        'title': 'What is DI?',
        'subtitle': 'In short',
        'content': {
          'version': 1,
          'language': 'en',
          'blocks': [
            {'id': 'b1', 'type': 'paragraph', 'content': [{'type': 'text', 'text': 'Hello'}]},
            {'id': 'b2', 'type': 'image', 'src': 'https://api.test/uploads/i/1600.webp', 'alt': ''},
          ],
        },
      },
    ],
    'fieldId': 'f-dotnet',
    'topicId': null,
    'tags': ['dotnet', 'di'],
    'sources': [{'title': 'Docs', 'url': 'https://learn.microsoft.com'}],
    'coverUrl': 'https://api.test/uploads/c/1200.webp',
    'versionBadge': '.NET 10',
    'isAiAssisted': true,
    'attachments': [
      {'mediaAssetId': 'a1', 'order': 0, 'caption': 'Program.cs', 'altText': 'Program.cs'},
    ],
  };

  final editJson = {
    'id': 'art-1',
    'status': 'published',
    'slug': 'what-is-di',
    'publishedAt': '2026-10-20T09:00:00Z',
    'version': 7,
    'savedAt': '2026-11-02T10:00:00Z',
    'hasUnpublishedChanges': true,
    'document': documentJson,
    'media': [
      {
        'id': 'a1',
        'kind': 'image',
        'purpose': 'image',
        'status': 'ready',
        'failureReason': null,
        'width': 1600,
        'height': 1200,
        'blurHash': null,
        'sizeBytes': 480000,
        'variants': [
          {'width': 320, 'height': 240, 'url': 'https://api.test/uploads/a1/320.webp', 'bytes': 9000},
        ],
        'title': null,
        'pageCount': null,
        'pagesReady': 0,
        'pages': [],
        'allowDownload': false,
        'createdAt': '2026-11-01T09:00:00Z',
      },
    ],
    'checks': {
      'readingTime': [
        {'language': 'ar-EG', 'minutes': 6, 'words': 1080},
        {'language': 'en', 'minutes': 1, 'words': 2},
      ],
      'problems': [
        {'code': 'article.image_alt_required', 'language': 'en', 'blockId': 'b2', 'mediaAssetId': null},
      ],
    },
  };

  test('GET /me/articles pages by status; an empty title stays empty', () async {
    respond = (_) => {
          'items': [
            {
              'id': 'd1',
              'status': 'draft',
              'slug': null,
              'language': 'en',
              'title': '',
              'coverUrl': null,
              'field': null,
              'readingTimeMinutes': 0,
              'savedAt': '2026-11-02T10:00:00Z',
              'publishedAt': null,
              'hasUnpublishedChanges': false,
              'reactionCount': 0,
              'commentCount': 0,
              'readCount': 0,
            },
            {
              'id': 'p1',
              'status': 'published',
              'slug': 'di',
              'language': 'ar-EG',
              'title': 'يعني إيه DI؟',
              'coverUrl': 'https://api.test/uploads/c/400.webp',
              'field': {'id': 'f-dotnet', 'slug': 'dotnet', 'name': '.NET', 'nameAr': '.NET', 'nameEn': '.NET'},
              'readingTimeMinutes': 7,
              'savedAt': '2026-11-02T12:00:00Z',
              'publishedAt': '2026-10-20T09:00:00Z',
              'hasUnpublishedChanges': true,
              'reactionCount': 42,
              'commentCount': 7,
              'readCount': 1200,
            },
          ],
          'nextCursor': 'c2',
        };
    final page = (await repository.myArticles(ArticleLifecycle.draft, cursor: 'c1')).valueOrNull!;
    expect(call(0), 'GET /me/articles');
    expect(requests[0].uri.queryParameters, {'status': 'draft', 'cursor': 'c1', 'limit': '20'});
    expect(page.nextCursor, 'c2');
    expect(page.items.first.title, '');
    expect(page.items.first.field, isNull);
    expect(page.items.last.isPublished, isTrue);
    expect(page.items.last.field?.slug, 'dotnet');
    expect(page.items.last.hasUnpublishedChanges, isTrue);
    expect(page.items.last.publishedAt, DateTime.utc(2026, 10, 20, 9));
  });

  test('GET /articles/{id}/edit parses the working copy, its media and checks', () async {
    respond = (_) => editJson;
    final edit = (await repository.getForEdit('art-1')).valueOrNull!;
    expect(call(0), 'GET /articles/art-1/edit');
    expect(edit.status, ArticleLifecycle.published);
    expect(edit.version, 7);
    expect(edit.hasUnpublishedChanges, isTrue);
    expect(edit.document.languages, ['ar-EG', 'en']);
    expect(edit.document.source.content.blocks, hasLength(19));
    expect(edit.document.translation('en')!.content.language, 'en');
    expect(edit.document.attachments.single, const AttachmentItem(mediaAssetId: 'a1', order: 0, caption: 'Program.cs', altText: 'Program.cs'));
    expect(edit.media.single.variants.single.width, 320);
    expect(edit.checks.readingTimeOf('ar-EG')?.minutes, 6);
    expect(edit.checks.problems.single, const DraftProblem('article.image_alt_required', language: 'en', blockId: 'b2'));
  });

  test('POST /articles sends the whole document, nulls included, with blocks being filled in left out', () async {
    respond = (_) => (201, editJson);
    final document = mixedDocument(complete: false).withTranslation(
      mixedDocument().source.copyWith(
        content: const RDocDocument(version: 1, language: 'ar-EG', blocks: [
          RParagraph('p', dir: 'auto', content: [RText('نص')]),
          RHeading('h', level: 2, dir: 'auto', content: []),
          RImage('i', src: '', alt: ''),
        ]),
      ),
    );
    final created = await repository.create(document);
    expect(created.isOk, isTrue);
    expect(call(0), 'POST /articles');
    final body = requests[0].data as Map<String, dynamic>;
    expect(body['sourceLanguage'], 'ar-EG');
    expect(body.containsKey('fieldId') && body['fieldId'] == null, isTrue);
    expect(body.containsKey('topicId') && body['topicId'] == null, isTrue);
    expect(body.containsKey('coverUrl') && body['coverUrl'] == null, isTrue);
    expect(body['versionBadge'], '.NET 10');
    expect(body['isAiAssisted'], isTrue);
    final ar = (body['translations'] as List).single as Map<String, dynamic>;
    expect(ar['language'], 'ar-EG');
    expect((ar['content'] as Map)['language'], 'ar-EG');
    expect([for (final b in (ar['content'] as Map)['blocks'] as List) (b as Map)['id']], ['p']);
  });

  test('PUT /articles/{id}/draft sends baseVersion and the document; 409 is a draft conflict', () async {
    respond = (_) => editJson;
    await repository.saveDraft('art-1', baseVersion: 7, document: mixedDocument());
    expect(call(0), 'PUT /articles/art-1/draft');
    final body = requests[0].data as Map<String, dynamic>;
    expect(body['baseVersion'], 7);
    expect((body['document'] as Map)['tags'], ['aspnetcore', 'di']);

    respond = (_) => (409, {'code': 'article.draft_conflict', 'status': 409, 'title': 'Conflict'});
    final conflict = await repository.saveDraft('art-1', baseVersion: 6, document: mixedDocument());
    expect(conflict.failureOrNull?.code, FailureCodes.articleDraftConflict);
  });

  test('DELETE /articles/{id}/draft discards the unpublished changes', () async {
    respond = (_) => {...editJson, 'hasUnpublishedChanges': false, 'version': 8};
    final edit = (await repository.discardChanges('art-1')).valueOrNull!;
    expect(call(0), 'DELETE /articles/art-1/draft');
    expect(edit.version, 8);
    expect(edit.hasUnpublishedChanges, isFalse);
  });

  test('POST /articles/{id}/publish: the published article, or every problem in the 400', () async {
    respond = (_) => {'id': 'art-1', 'slug': 'what-is-di', 'publishedAt': '2026-11-03T09:00:00Z', 'revision': 2, 'firstPublish': false};
    final published = (await repository.publish('art-1', baseVersion: 7)).valueOrNull!;
    expect(call(0), 'POST /articles/art-1/publish');
    expect(requests[0].data, {'baseVersion': 7});
    expect(published, PublishedArticle(id: 'art-1', slug: 'what-is-di', publishedAt: DateTime.utc(2026, 11, 3, 9), revision: 2, firstPublish: false));

    respond = (_) => (400, {
          'type': 'https://readin.app/errors/validation',
          'title': 'Fix the problems first',
          'status': 400,
          'code': 'article.title_length',
          'problems': [
            {'code': 'article.title_length', 'language': 'en', 'blockId': null, 'mediaAssetId': null},
            {'code': 'attachments.alt_text_required', 'language': null, 'blockId': null, 'mediaAssetId': 'a1'},
          ],
        });
    final refused = (await repository.publish('art-1', baseVersion: 7)).failureOrNull;
    expect(refused, isA<DraftProblemsFailure>());
    expect(refused!.code, 'article.title_length');
    expect((refused as DraftProblemsFailure).problems, const [
      DraftProblem('article.title_length', language: 'en'),
      DraftProblem('attachments.alt_text_required', mediaAssetId: 'a1'),
    ]);

    // F32: a hidden tag, and new tags past the daily limit, name their tag.
    respond = (_) => (400, {
          'status': 400,
          'code': 'tag.hidden',
          'problems': [
            {'code': 'tag.hidden', 'language': null, 'blockId': null, 'mediaAssetId': null, 'tag': 'Old'},
            {'code': 'tag.limit', 'language': null, 'blockId': null, 'mediaAssetId': null, 'tag': 'الذكاء الاصطناعي'},
          ],
        });
    final tags = (await repository.publish('art-1', baseVersion: 7)).failureOrNull! as DraftProblemsFailure;
    expect(tags.code, FailureCodes.tagHidden);
    expect(tags.problems, const [
      DraftProblem(FailureCodes.tagHidden, tag: 'Old'),
      DraftProblem(FailureCodes.tagLimit, tag: 'الذكاء الاصطناعي'),
    ]);

    respond = (_) => (409, {'code': 'article.draft_conflict', 'status': 409});
    final conflict = (await repository.publish('art-1', baseVersion: 6)).failureOrNull;
    expect(conflict, isNot(isA<DraftProblemsFailure>()));
    expect(conflict?.code, FailureCodes.articleDraftConflict);
  });

  test('revisions: list, details with media, and restore with baseVersion', () async {
    respond = (o) => switch (o.uri.path) {
          '/api/v1/articles/art-1/revisions' => [
              {'number': 2, 'createdAt': '2026-11-01T09:00:00Z', 'title': 'v2', 'languages': ['ar-EG', 'en']},
              {'number': 1, 'createdAt': '2026-10-20T09:00:00Z', 'title': 'v1', 'languages': ['ar-EG']},
            ],
          '/api/v1/articles/art-1/revisions/1' => {
              'number': 1,
              'createdAt': '2026-10-20T09:00:00Z',
              'title': 'v1',
              'languages': ['ar-EG'],
              'document': documentJson,
              'media': editJson['media'],
            },
          _ => editJson,
        };
    final list = (await repository.revisions('art-1')).valueOrNull!;
    final details = (await repository.revision('art-1', 1)).valueOrNull!;
    final restored = await repository.restoreRevision('art-1', 1, baseVersion: 7);
    expect([call(0), call(1), call(2)], ['GET /articles/art-1/revisions', 'GET /articles/art-1/revisions/1', 'POST /articles/art-1/revisions/1/restore']);
    expect(list.map((r) => r.number), [2, 1]);
    expect(list.first.languages, ['ar-EG', 'en']);
    expect(details.revision.number, 1);
    expect(details.document.fieldId, 'f-dotnet');
    expect(details.media.single.id, 'a1');
    expect(requests[2].data, {'baseVersion': 7});
    expect(restored.isOk, isTrue);
  });

  test('DELETE /articles/{id} and GET /tags', () async {
    respond = (o) => o.method == 'DELETE' ? (204, null) : [{'slug': 'dotnet', 'name': 'dotnet', 'articleCount': 12}];
    expect((await repository.delete('art-1')).isOk, isTrue);
    final tags = (await repository.suggestTags(' dot ')).valueOrNull!;
    expect(call(0), 'DELETE /articles/art-1');
    expect(call(1), 'GET /tags');
    expect(requests[1].uri.queryParameters, {'q': 'dot', 'limit': '10'});
    expect(tags.single, const ArticleTag(slug: 'dotnet', name: 'dotnet', articleCount: 12));

    // The query is cleaned like a tag name (F32): no leading "#", one space between words.
    await repository.suggestTags(' #ASP.NET   Core ');
    expect(requests[2].uri.queryParameters, {'q': 'ASP.NET Core', 'limit': '10'});
  });

  test('saving cleans the tags like the API: a leading # and extra spaces go, blank names are dropped', () async {
    respond = (_) => editJson;
    final document = sampleEdit().document.copyWith(tags: const ['#C#', '  ASP.NET   Core ', ' ']);
    await repository.saveDraft('art-1', baseVersion: 7, document: document);
    expect(((requests.single.data as Map)['document'] as Map)['tags'], ['C#', 'ASP.NET Core']);
  });

  test('a 400 on save carries the tag validation codes for the field', () async {
    respond = (_) => (400, {
          'status': 400,
          'code': 'validation.failed',
          'errors': {
            'document.tags': ['article.too_many_tags'],
            'document.tags[1]': ['tag.invalid'],
          },
        });
    final failure = (await repository.saveDraft('art-1', baseVersion: 7, document: sampleEdit().document)).failureOrNull!;
    expect(failure.code, FailureCodes.validationFailed);
    expect(failure.fieldErrors['document.tags'], [FailureCodes.articleTooManyTags]);
    expect(failure.fieldErrors['document.tags[1]'], [FailureCodes.tagInvalid]);
  });

  test('the device backup keeps the whole document as it was typed', () {
    final backup = EditorBackup(
      key: 'art-1',
      articleId: 'art-1',
      baseVersion: 7,
      status: ArticleLifecycle.published,
      slug: 'what-is-di',
      document: mixedDocument(withTranslation: true).copyWith(attachments: const [AttachmentItem(mediaAssetId: 'doc', order: 0, title: 'Notes', allowDownload: true)]),
      editedAt: DateTime.utc(2026, 11, 2, 11, 30),
    );
    expect(HiveEditorBackupStore.decode('art-1', HiveEditorBackupStore.encode(backup)), backup);
  });
}
