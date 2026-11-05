// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileLinksModel _$ProfileLinksModelFromJson(Map<String, dynamic> json) =>
    _ProfileLinksModel(
      github: json['github'] as String?,
      linkedin: json['linkedin'] as String?,
      website: json['website'] as String?,
    );

Map<String, dynamic> _$ProfileLinksModelToJson(_ProfileLinksModel instance) =>
    <String, dynamic>{
      'github': ?instance.github,
      'linkedin': ?instance.linkedin,
      'website': ?instance.website,
    };

_ExpertiseFieldModel _$ExpertiseFieldModelFromJson(Map<String, dynamic> json) =>
    _ExpertiseFieldModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'book-open',
      color: json['color'] as String? ?? 'primary',
    );

Map<String, dynamic> _$ExpertiseFieldModelToJson(
  _ExpertiseFieldModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'name': instance.name,
  'icon': instance.icon,
  'color': instance.color,
};

_ProfileStatsModel _$ProfileStatsModelFromJson(Map<String, dynamic> json) =>
    _ProfileStatsModel(
      articles: (json['articles'] as num?)?.toInt() ?? 0,
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      totalReads: (json['totalReads'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ProfileStatsModelToJson(_ProfileStatsModel instance) =>
    <String, dynamic>{
      'articles': instance.articles,
      'followers': instance.followers,
      'following': instance.following,
      'totalReads': instance.totalReads,
    };

_ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) =>
    _ProfileModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      avatarVariants: (json['avatarVariants'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      isVerified: json['isVerified'] as bool? ?? false,
      bio: json['bio'] as String?,
      links: json['links'] == null
          ? const ProfileLinksModel()
          : ProfileLinksModel.fromJson(json['links'] as Map<String, dynamic>),
      expertise:
          (json['expertise'] as List<dynamic>?)
              ?.map(
                (e) => ExpertiseFieldModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ExpertiseFieldModel>[],
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
      stats: json['stats'] == null
          ? const ProfileStatsModel()
          : ProfileStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
      isMe: json['isMe'] as bool? ?? false,
      isFollowing: json['isFollowing'] as bool? ?? false,
      followsYou: json['followsYou'] as bool? ?? false,
      readingStatsVisible: json['readingStatsVisible'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      isSystemAccount: json['isSystemAccount'] as bool? ?? false,
    );

Map<String, dynamic> _$ProfileModelToJson(_ProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'username': instance.username,
      'avatarUrl': ?instance.avatarUrl,
      'avatarVariants': ?instance.avatarVariants,
      'isVerified': instance.isVerified,
      'bio': ?instance.bio,
      'links': instance.links.toJson(),
      'expertise': instance.expertise.map((e) => e.toJson()).toList(),
      'joinedAt': ?instance.joinedAt?.toIso8601String(),
      'stats': instance.stats.toJson(),
      'isMe': instance.isMe,
      'isFollowing': instance.isFollowing,
      'followsYou': instance.followsYou,
      'readingStatsVisible': instance.readingStatsVisible,
      'isMuted': instance.isMuted,
      'isSystemAccount': instance.isSystemAccount,
    };
