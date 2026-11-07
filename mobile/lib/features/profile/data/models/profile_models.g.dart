// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileLinkModel _$ProfileLinkModelFromJson(Map<String, dynamic> json) =>
    _ProfileLinkModel(
      platform: json['platform'] as String,
      url: json['url'] as String? ?? '',
      label: json['label'] as String?,
    );

Map<String, dynamic> _$ProfileLinkModelToJson(_ProfileLinkModel instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'url': instance.url,
      'label': ?instance.label,
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
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      links: json['links'] == null
          ? const <ProfileLinkModel>[]
          : const ProfileLinksJson().fromJson(json['links']),
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
      admin: json['admin'] == null
          ? null
          : ProfileAdminModel.fromJson(json['admin'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProfileModelToJson(_ProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'username': instance.username,
      'avatarUrl': ?instance.avatarUrl,
      'avatarVariants': ?instance.avatarVariants,
      'isVerified': instance.isVerified,
      'headline': ?instance.headline,
      'bio': ?instance.bio,
      'links': ?const ProfileLinksJson().toJson(instance.links),
      'expertise': instance.expertise.map((e) => e.toJson()).toList(),
      'joinedAt': ?instance.joinedAt?.toIso8601String(),
      'stats': instance.stats.toJson(),
      'isMe': instance.isMe,
      'isFollowing': instance.isFollowing,
      'followsYou': instance.followsYou,
      'readingStatsVisible': instance.readingStatsVisible,
      'isMuted': instance.isMuted,
      'isSystemAccount': instance.isSystemAccount,
      'admin': ?instance.admin?.toJson(),
    };

_ProfileAdminModel _$ProfileAdminModelFromJson(Map<String, dynamic> json) =>
    _ProfileAdminModel(
      isSuspended: json['isSuspended'] as bool? ?? false,
      suspendedUntil: json['suspendedUntil'] == null
          ? null
          : DateTime.parse(json['suspendedUntil'] as String),
      isStaff: json['isStaff'] as bool? ?? false,
    );

Map<String, dynamic> _$ProfileAdminModelToJson(_ProfileAdminModel instance) =>
    <String, dynamic>{
      'isSuspended': instance.isSuspended,
      'suspendedUntil': ?instance.suspendedUntil?.toIso8601String(),
      'isStaff': instance.isStaff,
    };
