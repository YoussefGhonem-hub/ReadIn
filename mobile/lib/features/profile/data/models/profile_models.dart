import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/domain/entities/me.dart';
import '../../domain/entities/profile.dart';

part 'profile_models.freezed.dart';
part 'profile_models.g.dart';

/// `ProfileLinkDto` `{ platform, url, label }` (F14).
@freezed
abstract class ProfileLinkModel with _$ProfileLinkModel {
  const ProfileLinkModel._();

  const factory ProfileLinkModel({required String platform, @Default('') String url, String? label}) = _ProfileLinkModel;

  factory ProfileLinkModel.fromJson(Map<String, dynamic> json) => _$ProfileLinkModelFromJson(json);

  /// Null for a platform this app version doesn't know, or an empty link.
  ProfileLink? toEntity() {
    final kind = LinkPlatform.fromWire(platform);
    final address = url.trim();
    if (kind == null || address.isEmpty) return null;
    final name = label?.trim() ?? '';
    return ProfileLink(platform: kind, url: address, label: kind == LinkPlatform.other && name.isNotEmpty ? name : null);
  }

  /// The links in their order, skipping the ones [toEntity] can't show.
  static List<ProfileLink> entities(List<ProfileLinkModel> links) => [
        for (final link in links) ?link.toEntity(),
      ];

  /// `PATCH /me` `links[]`: the URL as typed (the server adds `https://`), a label for Other only.
  static Map<String, dynamic> request(ProfileLink link) => {
        'platform': link.platform.wire,
        'url': link.url.trim(),
        if (link.platform == LinkPlatform.other) 'label': link.label?.trim(),
      };
}

/// `links` in `ProfileDto` and `MeDto`: an array of [ProfileLinkModel]. An API from before the pre-production step sent
/// `{ github, linkedin, website }`; those read as `github`, `linkedin`, `website` links, so an older server still
/// shows them.
class ProfileLinksJson implements JsonConverter<List<ProfileLinkModel>, Object?> {
  const ProfileLinksJson();

  static const _legacy = {'github': 'github', 'linkedin': 'linkedin', 'website': 'website'};

  @override
  List<ProfileLinkModel> fromJson(Object? json) => switch (json) {
        final List<dynamic> list => [
            for (final item in list)
              if (item is Map<String, dynamic> && item['platform'] is String) ProfileLinkModel.fromJson(item),
          ],
        final Map<String, dynamic> map => [
            for (final MapEntry(:key, :value) in map.entries)
              if ((_legacy[key.toLowerCase()], value) case (final platform?, final String url) when url.trim().isNotEmpty)
                ProfileLinkModel(platform: platform, url: url),
          ],
        _ => const [],
      };

  @override
  Object? toJson(List<ProfileLinkModel> links) => [for (final link in links) link.toJson()];
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
    // F14 title, shown in full on the profile; older APIs leave it out.
    String? headline,
    String? bio,
    @ProfileLinksJson() @Default(<ProfileLinkModel>[]) List<ProfileLinkModel> links,
    @Default(<ExpertiseFieldModel>[]) List<ExpertiseFieldModel> expertise,
    DateTime? joinedAt,
    @Default(ProfileStatsModel()) ProfileStatsModel stats,
    @Default(false) bool isMe,
    @Default(false) bool isFollowing,
    @Default(false) bool followsYou,
    @Default(false) bool readingStatsVisible,
    // F28: the viewer muted this user.
    @Default(false) bool isMuted,
    // F28: the official @readin account, which can't be muted.
    @Default(false) bool isSystemAccount,
    // F23: the account's state, for holders of `users.read` only (null for everyone else).
    ProfileAdminModel? admin,
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
        headline: HeadlineRules.normalize(headline),
        bio: bio == null || bio!.trim().isEmpty ? null : bio,
        links: ProfileLinkModel.entities(links),
        expertise: [for (final field in expertise) field.toEntity()],
        joinedAt: joinedAt,
        stats: stats.toEntity(),
        isMe: isMe,
        isFollowing: isFollowing,
        followsYou: followsYou,
        readingStatsVisible: readingStatsVisible,
        isMuted: isMuted,
        isSystemAccount: isSystemAccount,
        admin: admin?.toEntity(),
      );
}

/// `ProfileDto.admin` (F23): `{ isSuspended, suspendedUntil, isStaff }`, for holders of `users.read`.
@freezed
abstract class ProfileAdminModel with _$ProfileAdminModel {
  const ProfileAdminModel._();

  const factory ProfileAdminModel({
    @Default(false) bool isSuspended,
    DateTime? suspendedUntil,
    @Default(false) bool isStaff,
  }) = _ProfileAdminModel;

  factory ProfileAdminModel.fromJson(Map<String, dynamic> json) => _$ProfileAdminModelFromJson(json);

  ProfileAdmin toEntity() => ProfileAdmin(isSuspended: isSuspended, suspendedUntil: suspendedUntil, isStaff: isStaff);
}

/// `PATCH /me` body, built by hand because a missing key and `null` mean different things:
/// - `avatarAssetId`: missing = keep the current avatar, `null` = remove it, an id = the new one (`GET /me` has no
///   asset id, so an untouched avatar must leave the key out);
/// - `expertiseFieldIds`: missing = unchanged, `[]` = none;
/// - `links` (F14): missing = unchanged, an array replaces the whole list in its order (`[]` removes them all);
/// - `headline` (F14): missing = unchanged, `null` clears it. The form always sends it.
///
/// The old `avatarUrl` is never sent.
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
      'headline': HeadlineRules.normalize(update.headline),
      if (links != null) 'links': [for (final link in links) ProfileLinkModel.request(link)],
      ...switch (update.avatar) {
        NewAvatar(:final assetId) => {'avatarAssetId': assetId},
        RemoveAvatar() => {'avatarAssetId': null},
        KeepAvatar() => const <String, dynamic>{},
      },
      'expertiseFieldIds': ?update.expertiseFieldIds,
    };
  }
}

/// `PUT /me/privacy` body: the whole privacy object every time, as the web sends it (the API takes each field as
/// optional).
class PrivacyRequest {
  const PrivacyRequest(this.privacy);

  final PrivacySettings privacy;

  Map<String, dynamic> toJson() => {
        'publicReadingStats': privacy.publicReadingStats,
        'whoCanMention': privacy.whoCanMention.wire,
      };
}
