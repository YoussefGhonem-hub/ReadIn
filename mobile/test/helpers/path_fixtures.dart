import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/home/domain/entities/continue_reading.dart';
import 'package:readin/features/paths/domain/entities/learning_path.dart';

import 'fixtures.dart';
import 'social_fakes.dart';

// ── JSON as the API sends it (docs/api/contract-v1.md "Learning paths (F09)", "Continue reading (F03)") ──────────

Map<String, dynamic> fieldRefJson(FieldRef field, {String language = 'en'}) => {
      'id': field.id,
      'slug': field.slug,
      'name': language == 'en' ? field.nameEn : field.nameAr,
      'nameAr': field.nameAr,
      'nameEn': field.nameEn,
    };

/// `ArticleCardDto` of [sampleCard] `i` (the details JSON carries every card field).
Map<String, dynamic> cardJson(int i, {String language = 'ar-EG'}) => detailsJson(i, language: language);

Map<String, dynamic> pathRefJson(int i, {int position = 2, String language = 'ar-EG'}) => {
      'id': 'art-$i',
      'slug': 'article-$i',
      'title': sampleTitles[i % sampleTitles.length],
      'language': language,
      'position': position,
      'readingTimeMinutes': 4 + i,
    };

Map<String, dynamic> progressJson({int readCount = 1, int total = 4, Map<String, dynamic>? next}) => {
      'readCount': readCount,
      'total': total,
      'percent': total == 0 ? 0 : readCount * 100 ~/ total,
      'next': next,
    };

Map<String, dynamic> enrollmentJson({bool completed = false}) => {
      'enrolledAt': '2026-10-20T08:00:00Z',
      'completedAt': completed ? '2026-11-01T18:30:00Z' : null,
    };

/// `PathCardDto`. A guest's has `progress` and `enrollment` null.
Map<String, dynamic> pathCardJson({
  String id = 'p-1',
  String slug = 'aspnet-core-basics',
  String title = 'أساسيات ASP.NET Core',
  String? description = 'من أول Dependency Injection لحد ما تنشر API كامل.',
  FieldRef field = dotnetField,
  int articleCount = 4,
  int readingTimeMinutes = 26,
  String? coverUrl,
  Map<String, dynamic>? progress,
  Map<String, dynamic>? enrollment,
}) =>
    {
      'id': id,
      'slug': slug,
      'title': title,
      'description': description,
      'field': fieldRefJson(field),
      'articleCount': articleCount,
      'readingTimeMinutes': readingTimeMinutes,
      'coverUrl': coverUrl,
      'progress': progress,
      'enrollment': enrollment,
    };

/// `PathDetailsDto`: the card fields plus `items`.
Map<String, dynamic> pathDetailsJson({Map<String, dynamic>? progress, Map<String, dynamic>? enrollment, Set<int> read = const {}}) => {
      ...pathCardJson(progress: progress, enrollment: enrollment),
      'items': [
        for (var position = 1; position <= 4; position++)
          {'position': position, 'article': cardJson(position), 'isRead': read.contains(position)},
      ],
    };

/// `ArticlePathDto`.
Map<String, dynamic> articlePathJson({int position = 2, int? next = 3, Map<String, dynamic>? path}) => {
      'path': path ?? pathCardJson(),
      'position': position,
      'total': 4,
      'previous': position > 1 ? pathRefJson(position - 1, position: position - 1) : null,
      'next': next == null ? null : cardJson(next),
    };

/// `ContinueReadingDto`.
Map<String, dynamic> continueReadingJson(int i, {int percent = 42, String language = 'en'}) => {
      'article': cardJson(i, language: language),
      'percent': percent,
      'language': language,
      'updatedAt': '2026-11-03T21:15:00Z',
    };

// ── Entities ──────────────────────────────────────────────────────────────────────────────────────────────────

PathArticleRef pathRef(int i, {int position = 2}) => PathArticleRef(
      id: 'art-$i',
      slug: 'article-$i',
      title: sampleTitles[i % sampleTitles.length],
      language: 'ar-EG',
      position: position,
      readingTimeMinutes: 4 + i,
    );

final enrolledAt = DateTime.utc(2026, 10, 20, 8);

/// A path; [readCount] null = a guest's (no progress). [next] defaults to the first unread one.
LearningPath samplePath({
  String id = 'p-1',
  String slug = 'aspnet-core-basics',
  String title = 'أساسيات ASP.NET Core',
  String? description = 'من أول Dependency Injection لحد ما تنشر API كامل.',
  FieldRef field = dotnetField,
  int total = 4,
  int? readCount,
  bool enrolled = false,
  bool completed = false,
}) =>
    LearningPath(
      id: id,
      slug: slug,
      title: title,
      description: description,
      field: field,
      articleCount: total,
      readingTimeMinutes: 26,
      progress: readCount == null
          ? null
          : PathProgress(
              readCount: readCount,
              total: total,
              percent: readCount * 100 ~/ total,
              next: readCount >= total ? null : pathRef(readCount + 1, position: readCount + 1),
            ),
      enrollment: enrolled || completed ? PathEnrollment(enrolledAt: enrolledAt, completedAt: completed ? DateTime.utc(2026, 11, 1) : null) : null,
    );

/// A path with 4 articles; the first [readCount] are read.
PathDetails samplePathDetails({int? readCount, bool enrolled = false, bool completed = false, String language = 'ar-EG'}) => PathDetails(
      path: samplePath(readCount: readCount, enrolled: enrolled, completed: completed),
      items: [
        for (var position = 1; position <= 4; position++)
          PathItem(position: position, article: sampleCard(position, language: language), isRead: position <= (readCount ?? 0)),
      ],
    );

/// Paths in two fields, for the lists and their chips.
List<LearningPath> samplePaths({bool signedIn = true}) => [
      samplePath(readCount: signedIn ? 2 : null, enrolled: signedIn),
      samplePath(
        id: 'p-2',
        slug: 'ai-agents-101',
        title: 'AI Agents من الصفر',
        description: 'إزاي تبني agent بيستخدم tools ويفتكر السياق.',
        field: aiField,
        total: 5,
        readCount: signedIn ? 5 : null,
        completed: signedIn,
      ),
      samplePath(
        id: 'p-3',
        slug: 'ef-core-performance',
        title: 'EF Core بسرعة',
        description: null,
        total: 3,
        readCount: signedIn ? 0 : null,
      ),
    ];

ArticlePath sampleArticlePath({int position = 2, bool last = false, int? readCount, bool enrolled = false, bool completed = false}) =>
    ArticlePath(
      path: samplePath(readCount: readCount, enrolled: enrolled, completed: completed),
      position: last ? 4 : position,
      total: 4,
      previous: pathRef(1, position: 1),
      next: last ? null : sampleCard(position + 1),
    );

ContinueReading sampleContinueReading(int i, {int percent = 42, String language = 'ar-EG'}) => ContinueReading(
      article: sampleCard(i, language: language),
      percent: percent,
      language: language,
      updatedAt: DateTime.utc(2026, 11, 3, 21, 15),
    );
