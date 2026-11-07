import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';

/// A published or archived article in the console's Content (`AdminArticleRowDto`). The title is the caller's UI
/// language version, else the source.
class AdminArticleRow extends Equatable {
  const AdminArticleRow({
    required this.id,
    required this.slug,
    required this.title,
    required this.language,
    required this.field,
    this.publishedAt,
    this.archived = false,
    this.author,
    this.topic,
    this.readCount = 0,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.hiddenAt,
    this.featuredAt,
    this.openReports = 0,
    this.reportCount = 0,
  });

  final String id;
  final String slug;
  final bool archived;
  final String title;

  /// `ar-EG` | `en`.
  final String language;
  final Author? author;
  final FieldRef field;
  final FieldRef? topic;
  /// The first publish; null for an archived article that was never published.
  final DateTime? publishedAt;
  final int readCount;
  final int reactionCount;
  final int commentCount;

  /// Hidden by a moderator.
  final DateTime? hiddenAt;

  /// Featured on Explore.
  final DateTime? featuredAt;
  final int openReports;

  /// Any status: more than 0 → its F22 case exists.
  final int reportCount;

  bool get isHidden => hiddenAt != null;
  bool get isFeatured => featuredAt != null;

  AdminArticleRow copyWith({DateTime? Function()? hiddenAt, DateTime? Function()? featuredAt}) => AdminArticleRow(
        id: id,
        slug: slug,
        archived: archived,
        title: title,
        language: language,
        author: author,
        field: field,
        topic: topic,
        publishedAt: publishedAt,
        readCount: readCount,
        reactionCount: reactionCount,
        commentCount: commentCount,
        hiddenAt: hiddenAt != null ? hiddenAt() : this.hiddenAt,
        featuredAt: featuredAt != null ? featuredAt() : this.featuredAt,
        openReports: openReports,
        reportCount: reportCount,
      );

  @override
  List<Object?> get props => [
        id,
        slug,
        archived,
        title,
        language,
        author,
        field,
        topic,
        publishedAt,
        readCount,
        reactionCount,
        commentCount,
        hiddenAt,
        featuredAt,
        openReports,
        reportCount,
      ];
}

/// The article a comment is on.
class AdminCommentArticle extends Equatable {
  const AdminCommentArticle({required this.id, required this.slug, required this.title, this.language = 'ar-EG'});

  final String id;
  final String slug;
  final String title;
  final String language;

  @override
  List<Object?> get props => [id, slug, title, language];
}

/// A comment of "Latest comments" (`AdminCommentRowDto`), replies included.
class AdminCommentRow extends Equatable {
  const AdminCommentRow({
    required this.id,
    required this.body,
    required this.article,
    required this.createdAt,
    this.author,
    this.parentId,
    this.editedAt,
    this.hiddenAt,
    this.likeCount = 0,
    this.replyCount = 0,
    this.openReports = 0,
    this.reportCount = 0,
  });

  final String id;
  final String body;
  final Author? author;
  final AdminCommentArticle article;

  /// A reply: its top-level comment.
  final String? parentId;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? hiddenAt;
  final int likeCount;
  final int replyCount;
  final int openReports;
  final int reportCount;

  bool get isHidden => hiddenAt != null;

  AdminCommentRow copyWith({DateTime? Function()? hiddenAt}) => AdminCommentRow(
        id: id,
        body: body,
        author: author,
        article: article,
        parentId: parentId,
        createdAt: createdAt,
        editedAt: editedAt,
        hiddenAt: hiddenAt != null ? hiddenAt() : this.hiddenAt,
        likeCount: likeCount,
        replyCount: replyCount,
        openReports: openReports,
        reportCount: reportCount,
      );

  @override
  List<Object?> get props =>
      [id, body, author, article, parentId, createdAt, editedAt, hiddenAt, likeCount, replyCount, openReports, reportCount];
}

/// Content's article filters: published in a period (local dates, both included), a field, a topic, a writer, hidden,
/// featured, reported, a title search; newest first, or the featured list (most recently featured first).
///
/// [fieldLabel], [topicLabel] and [writerLabel] are what the filter chips show; they are never sent.
class AdminArticleQuery extends Equatable {
  const AdminArticleQuery({
    this.from,
    this.to,
    this.field,
    this.topic,
    this.writer,
    this.fieldLabel,
    this.topicLabel,
    this.writerLabel,
    this.q = '',
    this.hidden,
    this.featured,
    this.reported = false,
    this.featuredOrder = false,
  });

  /// `YYYY-MM-DD` in `Admin:TimeZone`.
  final String? from;
  final String? to;

  /// Ids: a field, one of its topics, a writer (an account).
  final String? field;
  final String? topic;
  final String? writer;

  final String? fieldLabel;
  final String? topicLabel;
  final String? writerLabel;
  final String q;
  final bool? hidden;
  final bool? featured;
  final bool reported;

  /// `sort=featured`: most recently featured first.
  final bool featuredOrder;

  bool get hasPeriod => from != null || to != null;

  Map<String, dynamic> toQuery() => {
        'from': ?from,
        'to': ?to,
        'field': ?field,
        'topic': ?topic,
        'writer': ?writer,
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (hidden case final hidden?) 'hidden': '$hidden',
        if (featured case final featured?) 'featured': '$featured',
        if (reported) 'reported': 'true',
        'sort': featuredOrder ? 'featured' : 'published',
      };

  AdminArticleQuery copyWith({
    String? Function()? from,
    String? Function()? to,
    String? q,
    bool? Function()? hidden,
    bool? Function()? featured,
    bool? reported,
    bool? featuredOrder,
  }) =>
      AdminArticleQuery(
        from: from != null ? from() : this.from,
        to: to != null ? to() : this.to,
        field: field,
        topic: topic,
        writer: writer,
        fieldLabel: fieldLabel,
        topicLabel: topicLabel,
        writerLabel: writerLabel,
        q: q ?? this.q,
        hidden: hidden != null ? hidden() : this.hidden,
        featured: featured != null ? featured() : this.featured,
        reported: reported ?? this.reported,
        featuredOrder: featuredOrder ?? this.featuredOrder,
      );

  /// A field (with its label), or none: the topic goes with it, since a topic belongs to one field.
  AdminArticleQuery withField(String? id, {String? label}) => AdminArticleQuery(
        from: from,
        to: to,
        field: id,
        fieldLabel: id == null ? null : label,
        writer: writer,
        writerLabel: writerLabel,
        q: q,
        hidden: hidden,
        featured: featured,
        reported: reported,
        featuredOrder: featuredOrder,
      );

  /// A topic of the chosen field (with its label), or none.
  AdminArticleQuery withTopic(String? id, {String? label}) => AdminArticleQuery(
        from: from,
        to: to,
        field: field,
        fieldLabel: fieldLabel,
        topic: id,
        topicLabel: id == null ? null : label,
        writer: writer,
        writerLabel: writerLabel,
        q: q,
        hidden: hidden,
        featured: featured,
        reported: reported,
        featuredOrder: featuredOrder,
      );

  /// A writer (with its label, e.g. `@mona_dev`), or none.
  AdminArticleQuery withWriter(String? id, {String? label}) => AdminArticleQuery(
        from: from,
        to: to,
        field: field,
        fieldLabel: fieldLabel,
        topic: topic,
        topicLabel: topicLabel,
        writer: id,
        writerLabel: id == null ? null : label,
        q: q,
        hidden: hidden,
        featured: featured,
        reported: reported,
        featuredOrder: featuredOrder,
      );

  /// Content from a dashboard period ("Articles published" card).
  static AdminArticleQuery period(String from, String to) => AdminArticleQuery(from: from, to: to);

  /// From the router's query (`/admin/content?from=&to=&writer=&writerName=`): only well-formed dates and ids.
  static AdminArticleQuery fromUri(Uri uri) {
    String? date(String key) {
      final value = uri.queryParameters[key];
      return value != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ? value : null;
    }

    final writer = uri.queryParameters['writer'];
    final validWriter = writer != null && RegExp(r'^[A-Za-z0-9-]{1,64}$').hasMatch(writer) ? writer : null;
    final name = uri.queryParameters['writerName']?.trim();
    return AdminArticleQuery(
      from: date('from'),
      to: date('to'),
      writer: validWriter,
      writerLabel: validWriter == null || name == null || name.isEmpty ? null : name,
    );
  }

  @override
  List<Object?> get props =>
      [from, to, field, topic, writer, fieldLabel, topicLabel, writerLabel, q, hidden, featured, reported, featuredOrder];
}

/// "Latest comments": all, or only hidden / visible ones.
class AdminCommentQuery extends Equatable {
  const AdminCommentQuery({this.hidden});

  final bool? hidden;

  @override
  List<Object?> get props => [hidden];
}
