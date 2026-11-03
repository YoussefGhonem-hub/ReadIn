import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/reading/data/datasources/reading_api.dart';
import 'package:readin/features/reading/data/models/reading_models.dart';
import 'package:readin/features/reading/data/repositories/reading_repository_impl.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';

import '../../helpers/reading_fixtures.dart';

class MockReadingApi extends Mock implements ReadingApi {}

Map<String, dynamic> _streakJson({int current = 12, bool readToday = true}) => {
      'current': current,
      'longest': 30,
      'readToday': readToday,
      'freezeAvailable': true,
      'freezePending': false,
      'today': '2026-11-03',
    };

DioException _status(int status, String code) {
  final options = RequestOptions(path: '/articles/art-1/progress');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: {'code': code, 'title': 'x'}),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(const ReadingProgressRequestModel(language: 'en', percent: 0, activeSecondsDelta: 0)));

  late MockReadingApi api;
  late ReadingRepositoryImpl repository;

  setUp(() {
    api = MockReadingApi();
    repository = ReadingRepositoryImpl(api);
  });

  test('a progress report sends the request body and maps a completed read', () async {
    when(() => api.reportProgress(any(), any())).thenAnswer((_) async => ReadingProgressResultModel.fromJson({
          'percent': 72,
          'completed': true,
          'completedNow': true,
          'streak': _streakJson(),
          'milestone': 7,
        }));

    final result = await repository.reportProgress(
      'art-1',
      const ReadingProgressReport(language: 'ar-EG', percent: 72, lastPosition: '0.7200', activeSecondsDelta: 15),
    );

    final body = verify(() => api.reportProgress('art-1', captureAny())).captured.single as ReadingProgressRequestModel;
    expect(body.toJson(), {'language': 'ar-EG', 'percent': 72, 'lastPosition': '0.7200', 'activeSecondsDelta': 15});
    expect(
      result.valueOrNull,
      ReadingProgressResult(percent: 72, completed: true, completedNow: true, streak: sampleStreak(), milestone: 7),
    );
  });

  test('a report that completes nothing has no streak or milestone', () async {
    when(() => api.reportProgress(any(), any())).thenAnswer((_) async =>
        ReadingProgressResultModel.fromJson({'percent': 40, 'completed': false, 'completedNow': false, 'streak': null, 'milestone': null}));

    final result = await repository.reportProgress(
      'art-1',
      const ReadingProgressReport(language: 'en', percent: 40, lastPosition: '0.4000', activeSecondsDelta: 0),
    );

    expect(result.valueOrNull, const ReadingProgressResult(percent: 40, completed: false, completedNow: false));
  });

  test('API errors become typed failures', () async {
    when(() => api.reportProgress(any(), any())).thenThrow(_status(409, 'reading.conflict'));
    final conflict = await repository.reportProgress(
      'art-1',
      const ReadingProgressReport(language: 'en', percent: 0, lastPosition: null, activeSecondsDelta: 0),
    );
    expect(conflict.failureOrNull?.code, FailureCodes.readingConflict);
    expect(conflict.failureOrNull?.statusCode, 409);

    when(() => api.reportProgress(any(), any())).thenThrow(_status(404, 'article.not_found'));
    final missing = await repository.reportProgress(
      'art-1',
      const ReadingProgressReport(language: 'en', percent: 0, lastPosition: null, activeSecondsDelta: 0),
    );
    expect(missing.failureOrNull?.code, FailureCodes.articleNotFound);
  });

  test('stats map the streak, totals and top fields', () async {
    when(() => api.getStats()).thenAnswer((_) async => ReadingStatsModel.fromJson({
          'streak': _streakJson(),
          'totalArticles': 128,
          'minutesRead': 1240,
          'articlesThisWeek': 9,
          'minutesThisWeek': 74,
          'articlesThisMonth': 31,
          'topFields': [
            {'id': 'f-dotnet', 'slug': 'dotnet', 'name': '.NET', 'icon': 'code-xml', 'color': 'callout-info-accent', 'articles': 54},
            {'id': 'f-ai', 'slug': 'ai-fundamentals', 'name': 'AI Fundamentals', 'icon': 'sparkles', 'color': 'primary', 'articles': 31},
            {'id': 'f-db', 'slug': 'databases', 'name': 'Databases', 'icon': 'database', 'color': 'accent', 'articles': 12},
          ],
        }));

    final result = await repository.getStats();

    expect(result.valueOrNull, sampleStats());
  });

  test('the heatmap asks for the days and parses local dates', () async {
    when(() => api.getHeatmap(365)).thenAnswer((_) async => ReadingHeatmapModel.fromJson({
          'from': '2025-11-04',
          'to': '2026-11-03',
          'days': [
            {'date': '2026-10-31', 'articles': 2, 'minutes': 13, 'frozen': false},
            {'date': '2026-11-01', 'articles': 0, 'minutes': 0, 'frozen': true},
          ],
        }));

    final result = await repository.getHeatmap();

    expect(
      result.valueOrNull,
      ReadingHeatmapData(
        from: DateTime.utc(2025, 11, 4),
        to: DateTime.utc(2026, 11, 3),
        days: [
          HeatmapDay(date: DateTime.utc(2026, 10, 31), articles: 2, minutes: 13),
          HeatmapDay(date: DateTime.utc(2026, 11, 1), articles: 0, minutes: 0, frozen: true),
        ],
      ),
    );
  });

  test('a malformed date is a server error, not a crash', () async {
    when(() => api.getHeatmap(365)).thenAnswer((_) async => ReadingHeatmapModel.fromJson({'from': 'soon', 'to': '2026-11-03'}));

    final result = await repository.getHeatmap();

    expect(result.failureOrNull?.code, FailureCodes.serverError);
  });
}
