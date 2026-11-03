import 'package:equatable/equatable.dart';

/// Parses an API date (`yyyy-MM-dd`, the user's local date) into a date-only UTC [DateTime], so day arithmetic never
/// crosses a daylight-saving change.
DateTime parseReadingDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) throw FormatException('Not a yyyy-MM-dd date', value);
  return DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// The streak as the user sees it on [today], their local date (SPEC F08, ADR 0013).
class Streak extends Equatable {
  const Streak({
    required this.current,
    required this.longest,
    required this.readToday,
    required this.freezeAvailable,
    required this.freezePending,
    required this.today,
  });

  /// 0 once broken.
  final int current;
  final int longest;
  final bool readToday;

  /// A freeze is ready for the next missed day (one per rolling 7 days).
  final bool freezeAvailable;

  /// Yesterday was missed; reading today uses a freeze and keeps the streak.
  final bool freezePending;

  /// Date only (UTC midnight).
  final DateTime today;

  /// A live streak that today's reading hasn't extended yet.
  bool get notReadToday => current > 0 && !readToday;

  @override
  List<Object?> get props => [current, longest, readToday, freezeAvailable, freezePending, today];
}

/// One `PUT /articles/{id}/progress` report.
class ReadingProgressReport extends Equatable {
  const ReadingProgressReport({
    required this.language,
    required this.percent,
    required this.lastPosition,
    required this.activeSecondsDelta,
  });

  /// `ar-EG` or `en`: the version being read.
  final String language;

  /// 0–100, the highest scroll position reached.
  final int percent;

  /// Restores the scroll position (≤ 100 chars).
  final String? lastPosition;

  /// 0–3600, active seconds since the previous report.
  final int activeSecondsDelta;

  @override
  List<Object?> get props => [language, percent, lastPosition, activeSecondsDelta];
}

/// Answer to a progress report.
class ReadingProgressResult extends Equatable {
  const ReadingProgressResult({
    required this.percent,
    required this.completed,
    required this.completedNow,
    this.streak,
    this.milestone,
  });

  final int percent;
  final bool completed;

  /// This report made the article "read" (≥ 70% and ≥ 30 s, SPEC F04).
  final bool completedNow;

  /// Set when [completedNow].
  final Streak? streak;

  /// 7, 30, 100 or 365 when this read extended the streak to that length.
  final int? milestone;

  @override
  List<Object?> get props => [percent, completed, completedNow, streak, milestone];
}

/// A field the user reads most. [name] is localized, [icon] a Lucide name and [color] a design token name.
class TopField extends Equatable {
  const TopField({
    required this.id,
    required this.slug,
    required this.name,
    required this.icon,
    required this.color,
    required this.articles,
  });

  final String id;
  final String slug;
  final String name;
  final String icon;
  final String color;
  final int articles;

  @override
  List<Object?> get props => [id, slug, name, icon, color, articles];
}

/// `GET /me/stats` (owner only). "This week" is the last 7 local days and "this month" the last 30.
class ReadingStats extends Equatable {
  const ReadingStats({
    required this.streak,
    required this.totalArticles,
    required this.minutesRead,
    required this.articlesThisWeek,
    required this.minutesThisWeek,
    required this.articlesThisMonth,
    this.topFields = const [],
  });

  final Streak streak;
  final int totalArticles;
  final int minutesRead;
  final int articlesThisWeek;
  final int minutesThisWeek;
  final int articlesThisMonth;

  /// At most 3, most read first.
  final List<TopField> topFields;

  @override
  List<Object?> get props =>
      [streak, totalArticles, minutesRead, articlesThisWeek, minutesThisWeek, articlesThisMonth, topFields];
}

/// A day with a completed article or a streak freeze.
class HeatmapDay extends Equatable {
  const HeatmapDay({required this.date, required this.articles, required this.minutes, this.frozen = false});

  /// Date only (UTC midnight).
  final DateTime date;
  final int articles;
  final int minutes;

  /// A missed day covered by a streak freeze (no articles).
  final bool frozen;

  @override
  List<Object?> get props => [date, articles, minutes, frozen];
}

/// `GET /me/stats/heatmap`: [days] holds only days with a read or a freeze, oldest first.
class ReadingHeatmapData extends Equatable {
  const ReadingHeatmapData({required this.from, required this.to, this.days = const []});

  /// Date only (UTC midnight).
  final DateTime from;

  /// The user's local today, date only (UTC midnight).
  final DateTime to;
  final List<HeatmapDay> days;

  @override
  List<Object?> get props => [from, to, days];
}
