import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';

/// An article of a path, by reference (`PathArticleRefDto`): what "next" and "previous" point at.
class PathArticleRef extends Equatable {
  const PathArticleRef({
    required this.id,
    required this.slug,
    required this.title,
    required this.language,
    required this.position,
    required this.readingTimeMinutes,
  });

  final String id;
  final String slug;

  /// In the viewer's article language preference, else the source language.
  final String title;

  /// The version [title] is in: `ar-EG` or `en`.
  final String language;

  /// 1-based place in the path.
  final int position;
  final int readingTimeMinutes;

  @override
  List<Object?> get props => [id, slug, title, language, position, readingTimeMinutes];
}

/// The viewer's progress on a path (`PathProgressDto`): filled for signed-in callers, enrolled or not.
class PathProgress extends Equatable {
  const PathProgress({required this.readCount, required this.total, required this.percent, this.next});

  /// Articles of the path the viewer has read (F04 "read").
  final int readCount;
  final int total;

  /// `floor(readCount * 100 / total)`, 0–100.
  final int percent;

  /// The first unread article in path order; null once every article is read.
  final PathArticleRef? next;

  bool get allRead => next == null;

  /// 0–1 for a progress bar.
  double get fraction => (percent / 100).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [readCount, total, percent, next];
}

/// The viewer's enrollment (`PathEnrollmentDto`).
class PathEnrollment extends Equatable {
  const PathEnrollment({required this.enrolledAt, this.completedAt});

  final DateTime enrolledAt;

  /// Set once every article was read while enrolled: the completion badge. It stays when the path later grows.
  final DateTime? completedAt;

  @override
  List<Object?> get props => [enrolledAt, completedAt];
}

/// A learning path (F09) as cards show it (`PathCardDto`). Titles are in the UI language.
class LearningPath extends Equatable {
  const LearningPath({
    required this.id,
    required this.slug,
    required this.title,
    required this.field,
    required this.articleCount,
    required this.readingTimeMinutes,
    this.description,
    this.coverUrl,
    this.progress,
    this.enrollment,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final FieldRef field;

  /// Articles a reader can open, in path order.
  final int articleCount;

  /// The sum of their reading times.
  final int readingTimeMinutes;

  /// The first article's cover; null when it has none.
  final String? coverUrl;

  /// Null for guests.
  final PathProgress? progress;

  /// Null when not enrolled, and for guests.
  final PathEnrollment? enrollment;

  bool get isEnrolled => enrollment != null;

  /// The completion badge.
  bool get isCompleted => enrollment?.completedAt != null;

  /// The same path after leaving it: the progress stays (it's the reading history), the enrollment goes.
  LearningPath withoutEnrollment() => LearningPath(
        id: id,
        slug: slug,
        title: title,
        description: description,
        field: field,
        articleCount: articleCount,
        readingTimeMinutes: readingTimeMinutes,
        coverUrl: coverUrl,
        progress: progress,
      );

  @override
  List<Object?> get props => [id, slug, title, description, field, articleCount, readingTimeMinutes, coverUrl, progress, enrollment];
}

/// One article of a path (`PathItemDto`).
class PathItem extends Equatable {
  const PathItem({required this.position, required this.article, this.isRead = false});

  /// 1-based, dense.
  final int position;
  final ArticleCard article;

  /// False for guests.
  final bool isRead;

  @override
  List<Object?> get props => [position, article, isRead];
}

/// A path with its articles (`PathDetailsDto`).
class PathDetails extends Equatable {
  const PathDetails({required this.path, required this.items});

  final LearningPath path;

  /// Path order.
  final List<PathItem> items;

  PathDetails withPath(LearningPath path) => PathDetails(path: path, items: items);

  @override
  List<Object?> get props => [path, items];
}

/// Where an article sits in a path (`ArticlePathDto`): the reader's "Next in path" block.
class ArticlePath extends Equatable {
  const ArticlePath({required this.path, required this.position, required this.total, this.previous, this.next});

  /// When the article is in several paths: the enrolled one with the latest activity, else the first in editorial
  /// order.
  final LearningPath path;

  /// This article's place, 1-based.
  final int position;
  final int total;
  final PathArticleRef? previous;

  /// The following article in path order (read or not); null on the last one.
  final ArticleCard? next;

  bool get isLast => next == null;

  ArticlePath withPath(LearningPath path) =>
      ArticlePath(path: path, position: position, total: total, previous: previous, next: next);

  /// The path is done: the completion badge, or every article read.
  bool get pathCompleted {
    final progress = path.progress;
    return path.isCompleted || (progress != null && progress.total > 0 && progress.readCount >= progress.total);
  }

  @override
  List<Object?> get props => [path, position, total, previous, next];
}
