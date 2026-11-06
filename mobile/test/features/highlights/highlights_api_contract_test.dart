import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/failure_messages.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/auth/data/models/auth_models.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/highlights/data/datasources/highlights_api.dart';
import 'package:readin/features/highlights/data/repositories/highlights_repository_impl.dart';
import 'package:readin/features/settings/data/models/update_preferences_request.dart';
import 'package:readin/shared/rdoc/highlights/rdoc_highlight_text.dart';

import '../../helpers/fake_auth.dart';

/// Every F30 endpoint against docs/api/contract-v1.md "Highlights (F30)": method, path, query, body and how the answer
/// parses; `showHighlights` in `MeDto` and `PUT /me/preferences`; the error codes in both languages.
void main() {
  late List<RequestOptions> requests;
  late Object? Function(RequestOptions) respond;
  late HighlightsRepositoryImpl repository;

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
    repository = HighlightsRepositoryImpl(HighlightsApi(dio));
  });

  String call(int i) => '${requests[i].method} ${requests[i].uri.path.replaceFirst('/api/v1', '')}';

  Map<String, dynamic> highlight(String id, {String block = 'p1', int start = 15, int end = 27, String text = 'ASP.NET Core'}) => {
        'id': id,
        'blockId': block,
        'startOffset': start,
        'endOffset': end,
        'text': text,
        'createdAt': '2026-11-05T10:00:00Z',
      };

  test('GET /articles/{id}/highlights?lang= parses yours and the popular ranges; the answer names the version', () async {
    respond = (_) => {
          'articleId': 'a-1',
          'language': 'ar-EG',
          'mine': [highlight('h-1')],
          'popular': [
            {'blockId': 'q1', 'startOffset': 24, 'endOffset': 37, 'text': 'ده احترام للي', 'count': 7},
          ],
        };
    final result = (await repository.forArticle('a-1', language: 'en')).valueOrNull!;
    expect(call(0), 'GET /articles/a-1/highlights');
    expect(requests[0].uri.queryParameters, {'lang': 'en'});
    expect(result.language, 'ar-EG');
    expect(result.mine.single.range, const HighlightRange(blockId: 'p1', startOffset: 15, endOffset: 27, text: 'ASP.NET Core'));
    expect(result.mine.single.createdAt, DateTime.utc(2026, 11, 5, 10));
    expect(result.popular.single.count, 7);
  });

  test('POST /articles/{id}/highlights sends the version and the exact range; 201 and 200 parse the same', () async {
    respond = (options) => (options.method == 'POST' ? 201 : 200, {
          'highlight': highlight('h-9', start: 10, end: 27, text: 'بـ ASP.NET Core'),
          'replacedIds': ['h-1', 'h-2'],
        });
    const range = HighlightRange(blockId: 'p1', startOffset: 15, endOffset: 27, text: 'ASP.NET Core');
    final created = (await repository.create('a-1', language: 'ar-EG', range: range)).valueOrNull!;
    expect(call(0), 'POST /articles/a-1/highlights');
    expect(jsonDecode(jsonEncode(requests[0].data)), {
      'language': 'ar-EG',
      'blockId': 'p1',
      'startOffset': 15,
      'endOffset': 27,
      'text': 'ASP.NET Core',
    });
    expect(created.highlight.id, 'h-9');
    expect(created.replacedIds, ['h-1', 'h-2']);
  });

  test('DELETE /highlights/{id}; a refusal comes back with its code', () async {
    respond = (_) => (204, null);
    expect((await repository.remove('h-1')).isOk, isTrue);
    expect(call(0), 'DELETE /highlights/h-1');

    respond = (_) => (404, {'status': 404, 'code': 'highlight.not_found', 'title': 'x'});
    expect((await repository.remove('h-1')).failureOrNull?.code, FailureCodes.highlightNotFound);

    respond = (_) => (400, {'status': 400, 'code': 'highlight.text_mismatch', 'title': 'x'});
    const range = HighlightRange(blockId: 'p1', startOffset: 0, endOffset: 3, text: 'abc');
    expect((await repository.create('a-1', language: 'en', range: range)).failureOrNull?.code, FailureCodes.highlightTextMismatch);
  });

  test('GET /me/highlights?cursor=&limit= parses groups; a deleted author is null', () async {
    respond = (_) => {
          'items': [
            {
              'article': {
                'id': 'a-1',
                'slug': 'di-in-dotnet',
                'language': 'ar-EG',
                'title': 'إزاي تستخدم DI',
                'author': {'id': 'u-2', 'displayName': 'Sara', 'username': 'sara'},
              },
              'highlights': [highlight('h-2'), highlight('h-1')],
              'latestAt': '2026-11-05T10:00:00Z',
            },
            {
              'article': {'id': 'a-2', 'slug': 'old', 'language': 'en', 'title': 'Old', 'author': null},
              'highlights': [highlight('h-3')],
              'latestAt': '2026-11-01T10:00:00Z',
            },
          ],
          'nextCursor': 'c2',
        };
    final page = (await repository.mine(cursor: 'c1', limit: 20)).valueOrNull!;
    expect(call(0), 'GET /me/highlights');
    expect(requests[0].uri.queryParameters, {'cursor': 'c1', 'limit': '20'});
    expect(page.nextCursor, 'c2');
    expect(page.items.first.article.author?.displayName, 'Sara');
    expect(page.items.first.highlights.map((h) => h.id), ['h-2', 'h-1']);
    expect(page.items.last.article.author, isNull);
    expect(page.items.first.key, isNot(page.items.last.key));

    await repository.mine();
    expect(requests[1].uri.queryParameters, {'limit': '20'});
  });

  test('MeDto.showHighlights (default true) and highlights.create; PUT /me/preferences carries showHighlights', () {
    final me = MeModel.fromJson({
      ...meModel().toJson(),
      'showHighlights': false,
      'permissions': ['highlights.create'],
    }).toEntity();
    expect(me.showHighlights, isFalse);
    expect(me.canHighlight, isTrue);
    expect(MeModel.fromJson({...meModel().toJson()}..remove('showHighlights')).toEntity().showHighlights, isTrue);
    expect(Permissions.highlightsCreate, 'highlights.create');

    const request = UpdatePreferencesRequest(
      uiLanguage: 'ar',
      articleLanguage: 'ar-EG',
      theme: 'system',
      timeZone: 'Africa/Cairo',
      reminderTime: '08:00',
      showHighlights: false,
    );
    expect(request.toJson()['showHighlights'], false);
    // Left out when unknown, so the account keeps its setting.
    expect(
      const UpdatePreferencesRequest(uiLanguage: 'ar', articleLanguage: 'ar-EG', theme: 'system', timeZone: 'UTC', reminderTime: '08:00')
          .toJson()
          .containsKey('showHighlights'),
      isFalse,
    );
  });

  test('the highlight error codes read as in the contract, in both languages', () async {
    final ar = await AppLocalizations.delegate.load(AppLocales.ar);
    final en = await AppLocalizations.delegate.load(AppLocales.en);
    const expected = {
      FailureCodes.highlightTextMismatch: (
        'تغيّر هذا النص في المقال. حدّث الصفحة وحاول مرة أخرى.',
        'This text has changed in the article. Reload and try again.',
      ),
      FailureCodes.highlightBlockNotAllowed: ('لا يمكن تمييز هذا الجزء.', "This part can't be highlighted."),
      FailureCodes.highlightTooShort: ('حدّد 3 أحرف على الأقل.', 'Select at least 3 characters.'),
      FailureCodes.highlightTooLong: ('يجب ألا يتجاوز التمييز 1000 حرف.', 'A highlight can be at most 1,000 characters.'),
      FailureCodes.highlightLimit: ('وصلت إلى الحد الأقصى للتمييزات في هذا المقال (100).', 'You can have at most 100 highlights in one article.'),
      FailureCodes.highlightNotFound: ('هذا التمييز غير موجود.', 'Highlight not found.'),
    };
    for (final MapEntry(key: code, value: (arabic, english)) in expected.entries) {
      expect(localizeErrorCode(ar, code), arabic, reason: code);
      expect(localizeErrorCode(en, code), english, reason: code);
    }
  });
}
