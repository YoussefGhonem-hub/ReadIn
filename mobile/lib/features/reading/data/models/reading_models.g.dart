// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReadingProgressRequestModel _$ReadingProgressRequestModelFromJson(
  Map<String, dynamic> json,
) => _ReadingProgressRequestModel(
  language: json['language'] as String,
  percent: (json['percent'] as num).toInt(),
  lastPosition: json['lastPosition'] as String?,
  activeSecondsDelta: (json['activeSecondsDelta'] as num).toInt(),
);

Map<String, dynamic> _$ReadingProgressRequestModelToJson(
  _ReadingProgressRequestModel instance,
) => <String, dynamic>{
  'language': instance.language,
  'percent': instance.percent,
  'lastPosition': ?instance.lastPosition,
  'activeSecondsDelta': instance.activeSecondsDelta,
};

_StreakModel _$StreakModelFromJson(Map<String, dynamic> json) => _StreakModel(
  current: (json['current'] as num?)?.toInt() ?? 0,
  longest: (json['longest'] as num?)?.toInt() ?? 0,
  readToday: json['readToday'] as bool? ?? false,
  freezeAvailable: json['freezeAvailable'] as bool? ?? false,
  freezePending: json['freezePending'] as bool? ?? false,
  today: json['today'] as String,
);

Map<String, dynamic> _$StreakModelToJson(_StreakModel instance) =>
    <String, dynamic>{
      'current': instance.current,
      'longest': instance.longest,
      'readToday': instance.readToday,
      'freezeAvailable': instance.freezeAvailable,
      'freezePending': instance.freezePending,
      'today': instance.today,
    };

_ReadingProgressResultModel _$ReadingProgressResultModelFromJson(
  Map<String, dynamic> json,
) => _ReadingProgressResultModel(
  percent: (json['percent'] as num?)?.toInt() ?? 0,
  completed: json['completed'] as bool? ?? false,
  completedNow: json['completedNow'] as bool? ?? false,
  streak: json['streak'] == null
      ? null
      : StreakModel.fromJson(json['streak'] as Map<String, dynamic>),
  milestone: (json['milestone'] as num?)?.toInt(),
);

Map<String, dynamic> _$ReadingProgressResultModelToJson(
  _ReadingProgressResultModel instance,
) => <String, dynamic>{
  'percent': instance.percent,
  'completed': instance.completed,
  'completedNow': instance.completedNow,
  'streak': ?instance.streak?.toJson(),
  'milestone': ?instance.milestone,
};

_TopFieldModel _$TopFieldModelFromJson(Map<String, dynamic> json) =>
    _TopFieldModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'book-open',
      color: json['color'] as String? ?? 'primary',
      articles: (json['articles'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TopFieldModelToJson(_TopFieldModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'articles': instance.articles,
    };

_ReadingStatsModel _$ReadingStatsModelFromJson(Map<String, dynamic> json) =>
    _ReadingStatsModel(
      streak: StreakModel.fromJson(json['streak'] as Map<String, dynamic>),
      totalArticles: (json['totalArticles'] as num?)?.toInt() ?? 0,
      minutesRead: (json['minutesRead'] as num?)?.toInt() ?? 0,
      articlesThisWeek: (json['articlesThisWeek'] as num?)?.toInt() ?? 0,
      minutesThisWeek: (json['minutesThisWeek'] as num?)?.toInt() ?? 0,
      articlesThisMonth: (json['articlesThisMonth'] as num?)?.toInt() ?? 0,
      topFields:
          (json['topFields'] as List<dynamic>?)
              ?.map((e) => TopFieldModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TopFieldModel>[],
    );

Map<String, dynamic> _$ReadingStatsModelToJson(_ReadingStatsModel instance) =>
    <String, dynamic>{
      'streak': instance.streak.toJson(),
      'totalArticles': instance.totalArticles,
      'minutesRead': instance.minutesRead,
      'articlesThisWeek': instance.articlesThisWeek,
      'minutesThisWeek': instance.minutesThisWeek,
      'articlesThisMonth': instance.articlesThisMonth,
      'topFields': instance.topFields.map((e) => e.toJson()).toList(),
    };

_HeatmapDayModel _$HeatmapDayModelFromJson(Map<String, dynamic> json) =>
    _HeatmapDayModel(
      date: json['date'] as String,
      articles: (json['articles'] as num?)?.toInt() ?? 0,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      frozen: json['frozen'] as bool? ?? false,
    );

Map<String, dynamic> _$HeatmapDayModelToJson(_HeatmapDayModel instance) =>
    <String, dynamic>{
      'date': instance.date,
      'articles': instance.articles,
      'minutes': instance.minutes,
      'frozen': instance.frozen,
    };

_ReadingHeatmapModel _$ReadingHeatmapModelFromJson(Map<String, dynamic> json) =>
    _ReadingHeatmapModel(
      from: json['from'] as String,
      to: json['to'] as String,
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => HeatmapDayModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <HeatmapDayModel>[],
    );

Map<String, dynamic> _$ReadingHeatmapModelToJson(
  _ReadingHeatmapModel instance,
) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'days': instance.days.map((e) => e.toJson()).toList(),
};
