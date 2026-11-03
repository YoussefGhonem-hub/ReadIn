import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/reading.dart';

part 'reading_models.freezed.dart';
part 'reading_models.g.dart';

/// `ReadingProgressRequest` (docs/api/contract-v1.md).
@freezed
abstract class ReadingProgressRequestModel with _$ReadingProgressRequestModel {
  const factory ReadingProgressRequestModel({
    required String language,
    required int percent,
    String? lastPosition,
    required int activeSecondsDelta,
  }) = _ReadingProgressRequestModel;

  factory ReadingProgressRequestModel.fromJson(Map<String, dynamic> json) => _$ReadingProgressRequestModelFromJson(json);

  factory ReadingProgressRequestModel.fromReport(ReadingProgressReport report) => ReadingProgressRequestModel(
        language: report.language,
        percent: report.percent,
        lastPosition: report.lastPosition,
        activeSecondsDelta: report.activeSecondsDelta,
      );
}

/// `StreakDto`.
@freezed
abstract class StreakModel with _$StreakModel {
  const StreakModel._();

  const factory StreakModel({
    @Default(0) int current,
    @Default(0) int longest,
    @Default(false) bool readToday,
    @Default(false) bool freezeAvailable,
    @Default(false) bool freezePending,
    required String today,
  }) = _StreakModel;

  factory StreakModel.fromJson(Map<String, dynamic> json) => _$StreakModelFromJson(json);

  Streak toEntity() => Streak(
        current: current,
        longest: longest,
        readToday: readToday,
        freezeAvailable: freezeAvailable,
        freezePending: freezePending,
        today: parseReadingDate(today),
      );
}

/// `ReadingProgressResultDto`.
@freezed
abstract class ReadingProgressResultModel with _$ReadingProgressResultModel {
  const ReadingProgressResultModel._();

  const factory ReadingProgressResultModel({
    @Default(0) int percent,
    @Default(false) bool completed,
    @Default(false) bool completedNow,
    StreakModel? streak,
    int? milestone,
  }) = _ReadingProgressResultModel;

  factory ReadingProgressResultModel.fromJson(Map<String, dynamic> json) => _$ReadingProgressResultModelFromJson(json);

  ReadingProgressResult toEntity() => ReadingProgressResult(
        percent: percent,
        completed: completed,
        completedNow: completedNow,
        streak: streak?.toEntity(),
        milestone: milestone,
      );
}

/// `ReadingStatsDto.topFields[]`.
@freezed
abstract class TopFieldModel with _$TopFieldModel {
  const TopFieldModel._();

  const factory TopFieldModel({
    required String id,
    required String slug,
    required String name,
    @Default('book-open') String icon,
    @Default('primary') String color,
    @Default(0) int articles,
  }) = _TopFieldModel;

  factory TopFieldModel.fromJson(Map<String, dynamic> json) => _$TopFieldModelFromJson(json);

  TopField toEntity() => TopField(id: id, slug: slug, name: name, icon: icon, color: color, articles: articles);
}

/// `ReadingStatsDto`.
@freezed
abstract class ReadingStatsModel with _$ReadingStatsModel {
  const ReadingStatsModel._();

  const factory ReadingStatsModel({
    required StreakModel streak,
    @Default(0) int totalArticles,
    @Default(0) int minutesRead,
    @Default(0) int articlesThisWeek,
    @Default(0) int minutesThisWeek,
    @Default(0) int articlesThisMonth,
    @Default(<TopFieldModel>[]) List<TopFieldModel> topFields,
  }) = _ReadingStatsModel;

  factory ReadingStatsModel.fromJson(Map<String, dynamic> json) => _$ReadingStatsModelFromJson(json);

  ReadingStats toEntity() => ReadingStats(
        streak: streak.toEntity(),
        totalArticles: totalArticles,
        minutesRead: minutesRead,
        articlesThisWeek: articlesThisWeek,
        minutesThisWeek: minutesThisWeek,
        articlesThisMonth: articlesThisMonth,
        topFields: [for (final f in topFields) f.toEntity()],
      );
}

/// `ReadingHeatmapDto.days[]`.
@freezed
abstract class HeatmapDayModel with _$HeatmapDayModel {
  const HeatmapDayModel._();

  const factory HeatmapDayModel({
    required String date,
    @Default(0) int articles,
    @Default(0) int minutes,
    @Default(false) bool frozen,
  }) = _HeatmapDayModel;

  factory HeatmapDayModel.fromJson(Map<String, dynamic> json) => _$HeatmapDayModelFromJson(json);

  HeatmapDay toEntity() => HeatmapDay(date: parseReadingDate(date), articles: articles, minutes: minutes, frozen: frozen);
}

/// `ReadingHeatmapDto`.
@freezed
abstract class ReadingHeatmapModel with _$ReadingHeatmapModel {
  const ReadingHeatmapModel._();

  const factory ReadingHeatmapModel({
    required String from,
    required String to,
    @Default(<HeatmapDayModel>[]) List<HeatmapDayModel> days,
  }) = _ReadingHeatmapModel;

  factory ReadingHeatmapModel.fromJson(Map<String, dynamic> json) => _$ReadingHeatmapModelFromJson(json);

  ReadingHeatmapData toEntity() => ReadingHeatmapData(
        from: parseReadingDate(from),
        to: parseReadingDate(to),
        days: [for (final d in days) d.toEntity()],
      );
}
