import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/profile.dart';

part 'profile_models.freezed.dart';
part 'profile_models.g.dart';

/// `ProfileDto.links`: the keys are `github`, `linkedin`, `website`; unset links are null.
@freezed
abstract class ProfileLinksModel with _$ProfileLinksModel {
  const ProfileLinksModel._();

  const factory ProfileLinksModel({String? github, String? linkedin, String? website}) = _ProfileLinksModel;

  factory ProfileLinksModel.fromJson(Map<String, dynamic> json) => _$ProfileLinksModelFromJson(json);

  static String? _blankToNull(String? value) => value == null || value.trim().isEmpty ? null : value.trim();

  ProfileLinks toEntity() =>
      ProfileLinks(github: _blankToNull(github), linkedin: _blankToNull(linkedin), website: _blankToNull(website));
}

/// `ProfileDto.expertise[]`.
@freezed
abstract class ExpertiseFieldModel with _$ExpertiseFieldModel {
  const ExpertiseFieldModel._();

  const factory ExpertiseFieldModel({
    required String id,
    required String slug,
    required String name,
    @Default('book-open') String icon,
    @Default('primary') String color,
  }) = _ExpertiseFieldModel;

  factory ExpertiseFieldModel.fromJson(Map<String, dynamic> json) => _$ExpertiseFieldModelFromJson(json);

  ExpertiseField toEntity() => ExpertiseField(id: id, slug: slug, name: name, icon: icon, color: color);
}

/// `ProfileDto.stats`.
@freezed
abstract class ProfileStatsModel with _$ProfileStatsModel {
  const ProfileStatsModel._();

  const factory ProfileStatsModel({
    @Default(0) int articles,
    @Default(0) int followers,
    @Default(0) int following,
    @Default(0) int totalReads,
  }) = _ProfileStatsModel;

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) => _$ProfileStatsModelFromJson(json);

  ProfileStats toEntity() => ProfileStats(articles: articles, followers: followers, following: following, totalReads: totalReads);
}

/// `ProfileDto` (`GET /users/{username}`, F14).
@freezed
abstract class ProfileModel with _$ProfileModel {
  const ProfileModel._();

  const factory ProfileModel({
    required String id,
    required String displayName,
    required String username,
    String? avatarUrl,
    // `{ "64": url, "128": url, "256": url, "512": url }`, or null.
    Map<String, String>? avatarVariants,
    @Default(false) bool isVerified,
    String? bio,
    @Default(ProfileLinksModel()) ProfileLinksModel links,
    @Default(<ExpertiseFieldModel>[]) List<ExpertiseFieldModel> expertise,
    DateTime? joinedAt,
    @Default(ProfileStatsModel()) ProfileStatsModel stats,
    @Default(false) bool isMe,
    @Default(false) bool isFollowing,
    @Default(false) bool followsYou,
    @Default(false) bool readingStatsVisible,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);

  UserProfile toEntity() => UserProfile(
        id: id,
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        avatarVariants: {
          for (final MapEntry(:key, :value) in (avatarVariants ?? const <String, String>{}).entries)
            if (int.tryParse(key) case final width? when value.isNotEmpty) width: value,
        },
        isVerified: isVerified,
        bio: bio == null || bio!.trim().isEmpty ? null : bio,
        links: links.toEntity(),
        expertise: [for (final field in expertise) field.toEntity()],
        joinedAt: joinedAt,
        stats: stats.toEntity(),
        isMe: isMe,
        isFollowing: isFollowing,
        followsYou: followsYou,
        readingStatsVisible: readingStatsVisible,
      );
}

/// `PATCH /me` body, built by hand because a missing key and `null` mean different things:
/// - `avatarAssetId`: missing = keep the current avatar, `null` = remove it, an id = the new one (`GET /me` has no
///   asset id, so an untouched avatar must leave the key out);
/// - `expertiseFieldIds`: missing = unchanged, `[]` = none.
///
/// The links are always sent, with nulls, as the server replaces all three. The old `avatarUrl` is never sent.
class UpdateProfileRequest {
  const UpdateProfileRequest(this.update);

  final ProfileUpdate update;

  static String? _blankToNull(String? value) => value == null || value.trim().isEmpty ? null : value.trim();

  Map<String, dynamic> toJson() {
    final update = this.update;
    final links = update.links;
    return {
      'displayName': update.displayName,
      'username': update.username,
      'bio': _blankToNull(update.bio),
      'links': {
        'github': _blankToNull(links.github),
        'linkedin': _blankToNull(links.linkedin),
        'website': _blankToNull(links.website),
      },
      ...switch (update.avatar) {
        NewAvatar(:final assetId) => {'avatarAssetId': assetId},
        RemoveAvatar() => {'avatarAssetId': null},
        KeepAvatar() => const <String, dynamic>{},
      },
      'expertiseFieldIds': ?update.expertiseFieldIds,
    };
  }
}

/// `PUT /me/privacy` body.
class PrivacyRequest {
  const PrivacyRequest({required this.publicReadingStats});

  final bool publicReadingStats;

  Map<String, dynamic> toJson() => {'publicReadingStats': publicReadingStats};
}
