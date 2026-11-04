import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/home/data/models/continue_reading_models.dart';
import 'package:readin/features/paths/data/models/path_models.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/path_fixtures.dart';

/// The F09 / F03 DTOs parse the way the contract shapes them (docs/api/contract-v1.md).
void main() {
  group('PathCardDto', () {
    test("a guest's card: no progress, no enrollment", () {
      final path = PathCardModel.fromJson(pathCardJson(coverUrl: 'https://api.test/uploads/c.webp')).toEntity();

      expect(path.id, 'p-1');
      expect(path.slug, 'aspnet-core-basics');
      expect(path.title, 'أساسيات ASP.NET Core');
      expect(path.description, 'من أول Dependency Injection لحد ما تنشر API كامل.');
      expect(path.field, dotnetField);
      expect((path.articleCount, path.readingTimeMinutes), (4, 26));
      expect(path.coverUrl, 'https://api.test/uploads/c.webp');
      expect(path.progress, isNull);
      expect(path.enrollment, isNull);
      expect((path.isEnrolled, path.isCompleted), (false, false));
    });

    test('signed in: progress with the next article, and the enrollment', () {
      final path = PathCardModel.fromJson(pathCardJson(
        progress: progressJson(readCount: 1, next: pathRefJson(2, language: 'en')),
        enrollment: enrollmentJson(),
      )).toEntity();

      final progress = path.progress!;
      expect((progress.readCount, progress.total, progress.percent), (1, 4, 25));
      expect(progress.fraction, 0.25);
      expect(progress.allRead, isFalse);
      expect(progress.next!.id, 'art-2');
      expect(progress.next!.slug, 'article-2');
      expect(progress.next!.language, 'en');
      expect((progress.next!.position, progress.next!.readingTimeMinutes), (2, 6));
      expect(path.enrollment!.enrolledAt, DateTime.utc(2026, 10, 20, 8));
      expect(path.isEnrolled, isTrue);
      expect(path.isCompleted, isFalse);
    });

    test('completed: completedAt is the badge, even after the path grew (next set again)', () {
      final path = PathCardModel.fromJson(pathCardJson(
        articleCount: 5,
        progress: progressJson(readCount: 4, total: 5, next: pathRefJson(3, position: 5)),
        enrollment: enrollmentJson(completed: true),
      )).toEntity();

      expect(path.isCompleted, isTrue);
      expect(path.enrollment!.completedAt, DateTime.utc(2026, 11, 1, 18, 30));
      expect(path.progress!.allRead, isFalse);
      expect(path.progress!.percent, 80);
    });

    test('blank description and empty cover read as none', () {
      final path = PathCardModel.fromJson(pathCardJson(description: '  ', coverUrl: '')).toEntity();
      expect(path.description, isNull);
      expect(path.coverUrl, isNull);
    });

    test('leaving keeps the progress and drops the enrollment', () {
      final path = PathCardModel.fromJson(pathCardJson(progress: progressJson(readCount: 2), enrollment: enrollmentJson())).toEntity();
      final left = path.withoutEnrollment();
      expect(left.enrollment, isNull);
      expect(left.progress, path.progress);
      expect(left.id, path.id);
    });
  });

  test('PathDetailsDto: the flat card fields plus items, in position order', () {
    final json = pathDetailsJson(progress: progressJson(readCount: 1, next: pathRefJson(2)), enrollment: enrollmentJson(), read: {1});
    // The API sends path order; shuffle to prove the client keeps positions.
    json['items'] = [...(json['items'] as List)].reversed.toList();

    final details = PathDetailsModel.fromJson(json).toEntity();

    expect(details.path.slug, 'aspnet-core-basics');
    expect(details.path.isEnrolled, isTrue);
    expect(details.items.map((i) => i.position), [1, 2, 3, 4]);
    expect(details.items.map((i) => i.article.id), ['art-1', 'art-2', 'art-3', 'art-4']);
    expect(details.items.map((i) => i.isRead), [true, false, false, false]);
    // The usual card: counters and the viewer's state.
    expect(details.items.first.article.saveCount, 7);
    expect(details.items.first.article.reactionCount, 16);
  });

  group('ArticlePathDto', () {
    test('in the middle: previous ref and the next card', () {
      final articlePath = ArticlePathModel.fromJson(articlePathJson()).toEntity();

      expect((articlePath.position, articlePath.total), (2, 4));
      expect(articlePath.previous!.id, 'art-1');
      expect(articlePath.next!.id, 'art-3');
      expect(articlePath.next!.title, sampleTitles[3]);
      expect(articlePath.isLast, isFalse);
      expect(articlePath.pathCompleted, isFalse);
    });

    test('the last article: no next; every article read counts as completed', () {
      final articlePath = ArticlePathModel.fromJson(articlePathJson(
        position: 4,
        next: null,
        path: pathCardJson(progress: progressJson(readCount: 4)),
      )).toEntity();

      expect(articlePath.isLast, isTrue);
      expect(articlePath.next, isNull);
      expect(articlePath.path.isEnrolled, isFalse);
      expect(articlePath.pathCompleted, isTrue);
    });
  });

  test('ContinueReadingDto: the card in the version being read, how far, and when', () {
    final item = ContinueReadingModel.fromJson(continueReadingJson(2, percent: 63)).toEntity();

    expect(item.article.id, 'art-2');
    expect(item.article.language, 'en');
    expect(item.language, 'en');
    expect(item.percent, 63);
    expect(item.fraction, 0.63);
    expect(item.updatedAt, DateTime.utc(2026, 11, 3, 21, 15));
  });
}
