import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';

/// `GET /admin/summary` (F23): the badge on the console entry, open reports + open tickets + pending verification
/// requests. A part is null when the caller lacks its permission; [total] adds the others.
class AdminSummary extends Equatable {
  const AdminSummary({this.openReports, this.openTickets, this.pendingVerifications, this.total = 0});

  final int? openReports;
  final int? openTickets;
  final int? pendingVerifications;
  final int total;

  @override
  List<Object?> get props => [openReports, openTickets, pendingVerifications, total];
}

/// The dashboard's period: today (the default), yesterday, the last 7 or 30 days, in `Admin:TimeZone` days.
enum AdminPeriod {
  today('today'),
  yesterday('yesterday'),
  days7('7d'),
  days30('30d');

  const AdminPeriod(this.wire);

  final String wire;

  static AdminPeriod fromWire(String? wire) => values.where((period) => period.wire == wire).firstOrNull ?? today;
}

/// A number of the period and of the previous period of the same length.
class DashboardValue extends Equatable {
  const DashboardValue({this.value = 0, this.previous = 0});

  final int value;
  final int previous;

  /// Up (> 0), down (< 0) or the same as the previous period.
  int get change => value - previous;

  @override
  List<Object?> get props => [value, previous];
}

/// New users, split by how they signed up.
class NewUsersValue extends DashboardValue {
  const NewUsersValue({super.value, super.previous, this.phone = 0, this.google = 0, this.apple = 0});

  final int phone;
  final int google;
  final int apple;

  @override
  List<Object?> get props => [...super.props, phone, google, apple];
}

/// `DashboardCardsDto`. The four state cards are the numbers now; a queue's number is null without its permission.
class DashboardCards extends Equatable {
  const DashboardCards({
    this.articlesPublished = const DashboardValue(),
    this.newUsers = const NewUsersValue(),
    this.activeReaders = const DashboardValue(),
    this.reads = const DashboardValue(),
    this.comments = const DashboardValue(),
    this.reactions = const DashboardValue(),
    this.reposts = const DashboardValue(),
    this.openReports,
    this.openTickets,
    this.pendingVerifications,
    this.suspendedNow = 0,
  });

  final DashboardValue articlesPublished;
  final NewUsersValue newUsers;
  final DashboardValue activeReaders;
  final DashboardValue reads;
  final DashboardValue comments;
  final DashboardValue reactions;
  final DashboardValue reposts;
  final int? openReports;
  final int? openTickets;
  final int? pendingVerifications;
  final int suspendedNow;

  @override
  List<Object?> get props => [
        articlesPublished,
        newUsers,
        activeReaders,
        reads,
        comments,
        reactions,
        reposts,
        openReports,
        openTickets,
        pendingVerifications,
        suspendedNow,
      ];
}

/// One day of the 30-day charts.
class DashboardDay extends Equatable {
  const DashboardDay({required this.date, this.newUsers = 0, this.activeReaders = 0, this.articlesPublished = 0});

  /// `YYYY-MM-DD` in `Admin:TimeZone`.
  final String date;
  final int newUsers;
  final int activeReaders;
  final int articlesPublished;

  @override
  List<Object?> get props => [date, newUsers, activeReaders, articlesPublished];
}

/// One of the top 10 articles by reads in the period.
class DashboardArticle extends Equatable {
  const DashboardArticle({
    required this.id,
    required this.slug,
    required this.title,
    required this.language,
    required this.field,
    required this.publishedAt,
    this.author,
    this.reads = 0,
  });

  final String id;
  final String slug;
  final String title;

  /// `ar-EG` | `en`: the title's own direction.
  final String language;
  final Author? author;
  final FieldRef field;
  final DateTime publishedAt;
  final int reads;

  @override
  List<Object?> get props => [id, slug, title, language, author, field, publishedAt, reads];
}

/// One of the top 10 writers by reads of their articles in the period.
class DashboardWriter extends Equatable {
  const DashboardWriter({required this.writer, this.reads = 0, this.articles = 0});

  final Author writer;
  final int reads;

  /// How many of their articles were read.
  final int articles;

  @override
  List<Object?> get props => [writer, reads, articles];
}

/// A search that found nothing (§22), without who searched.
class MissedSearch extends Equatable {
  const MissedSearch({required this.query, this.language = 'en', this.count = 0});

  final String query;

  /// `ar` | `en`.
  final String language;
  final int count;

  @override
  List<Object?> get props => [query, language, count];
}

/// Last week's active readers ([cohort]) and those of them who kept a streak of 3 days or more ([kept]).
class StreakRetention extends Equatable {
  const StreakRetention({this.cohort = 0, this.kept = 0, this.rate});

  final int cohort;
  final int kept;

  /// 0–1; null for an empty cohort.
  final double? rate;

  @override
  List<Object?> get props => [cohort, kept, rate];
}

/// The seed content: article folders in `content/`, @readin articles in the database, those readers can open, and the
/// last seed run.
class ContentPipeline extends Equatable {
  const ContentPipeline({this.folders = 0, this.seeded = 0, this.published = 0, this.lastSeedRunAt});

  final int folders;
  final int seeded;
  final int published;
  final DateTime? lastSeedRunAt;

  @override
  List<Object?> get props => [folders, seeded, published, lastSeedRunAt];
}

/// `GET /admin/dashboard?period=` (`AdminDashboardDto`).
class AdminDashboard extends Equatable {
  const AdminDashboard({
    required this.period,
    required this.fromDate,
    required this.toDate,
    required this.generatedAt,
    this.timeZone = 'Africa/Cairo',
    this.cards = const DashboardCards(),
    this.charts = const [],
    this.topArticles = const [],
    this.topWriters = const [],
    this.missedSearches = const [],
    this.streakRetention = const StreakRetention(),
    this.contentPipeline = const ContentPipeline(),
  });

  final AdminPeriod period;
  final String timeZone;

  /// The period as local dates (`YYYY-MM-DD`, both included): Content's `from` / `to`.
  final String fromDate;
  final String toDate;
  final DateTime generatedAt;
  final DashboardCards cards;

  /// The last 30 days up to today, oldest first, whatever the period.
  final List<DashboardDay> charts;
  final List<DashboardArticle> topArticles;
  final List<DashboardWriter> topWriters;
  final List<MissedSearch> missedSearches;
  final StreakRetention streakRetention;
  final ContentPipeline contentPipeline;

  @override
  List<Object?> get props => [
        period,
        timeZone,
        fromDate,
        toDate,
        generatedAt,
        cards,
        charts,
        topArticles,
        topWriters,
        missedSearches,
        streakRetention,
        contentPipeline,
      ];
}
