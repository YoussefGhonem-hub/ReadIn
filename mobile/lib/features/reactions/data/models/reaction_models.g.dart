// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SetReactionRequest _$SetReactionRequestFromJson(Map<String, dynamic> json) =>
    _SetReactionRequest(type: json['type'] as String);

Map<String, dynamic> _$SetReactionRequestToJson(_SetReactionRequest instance) =>
    <String, dynamic>{'type': instance.type};

_ArticleReactionsModel _$ArticleReactionsModelFromJson(
  Map<String, dynamic> json,
) => _ArticleReactionsModel(
  reactions: json['reactions'] == null
      ? const ReactionCountsModel()
      : ReactionCountsModel.fromJson(json['reactions'] as Map<String, dynamic>),
  total: (json['total'] as num?)?.toInt(),
  myReaction: json['myReaction'] as String?,
);

Map<String, dynamic> _$ArticleReactionsModelToJson(
  _ArticleReactionsModel instance,
) => <String, dynamic>{
  'reactions': instance.reactions.toJson(),
  'total': ?instance.total,
  'myReaction': ?instance.myReaction,
};

_ReactorModel _$ReactorModelFromJson(Map<String, dynamic> json) =>
    _ReactorModel(
      user: AuthorModel.fromJson(json['user'] as Map<String, dynamic>),
      type: json['type'] as String,
      reactedAt: DateTime.parse(json['reactedAt'] as String),
    );

Map<String, dynamic> _$ReactorModelToJson(_ReactorModel instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'type': instance.type,
      'reactedAt': instance.reactedAt.toIso8601String(),
    };

_ReactorPageModel _$ReactorPageModelFromJson(Map<String, dynamic> json) =>
    _ReactorPageModel(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ReactorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ReactorModel>[],
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$ReactorPageModelToJson(_ReactorPageModel instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };
