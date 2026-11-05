import 'package:equatable/equatable.dart';

import 'profile_link.dart';

export 'profile_link.dart';

/// A field of expertise on a profile (`ProfileDto.expertise`): `name` is in the request's UI language.
class ExpertiseField extends Equatable {
  const ExpertiseField({required this.id, required this.slug, required this.name, this.icon = 'book-open', this.color = 'primary'});

  final String id;
  final String slug;
  final String name;

  /// Lucide icon name and color token, as on fields elsewhere.
  final String icon;
  final String color;

  @override
  List<Object?> get props => [id, slug, name, icon, color];
}

/// `ProfileDto.stats`.
class ProfileStats extends Equatable {
  const ProfileStats({this.articles = 0, this.followers = 0, this.following = 0, this.totalReads = 0});

  /// Published articles.
  final int articles;
  final int followers;
  final int following;

  /// Reads of the user's published articles.
  final int totalReads;

  ProfileStats copyWith({int? followers, int? following}) => ProfileStats(
        articles: articles,
        followers: followers ?? this.followers,
        following: following ?? this.following,
        totalReads: totalReads,
      );

  @override
  List<Object?> get props => [articles, followers, following, totalReads];
}

/// A public profile (`ProfileDto`, F14). Never carries the phone number (SPEC §9.5).
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.avatarVariants = const {},
    this.isVerified = false,
    this.headline,
    this.bio,
    this.links = const [],
    this.expertise = const [],
    this.joinedAt,
    this.stats = const ProfileStats(),
    this.isMe = false,
    this.isFollowing = false,
    this.followsYou = false,
    this.readingStatsVisible = false,
    this.isMuted = false,
    this.isSystemAccount = false,
  });

  final String id;
  final String displayName;

  /// `@handle` without the `@`.
  final String username;

  /// The 256 px variant (the same value as every `AuthorDto`), or null.
  final String? avatarUrl;

  /// Square variants by width (64 / 128 / 256 / 512); empty for no avatar or an old one without variants.
  final Map<int, String> avatarVariants;
  final bool isVerified;

  /// The title under the name (F14), shown in full on the profile; null when there is none.
  final String? headline;
  final String? bio;

  /// Social links (F14), in the member's order, at most 8; empty when there are none.
  final List<ProfileLink> links;

  /// In the user's order, at most 5.
  final List<ExpertiseField> expertise;
  final DateTime? joinedAt;
  final ProfileStats stats;

  /// The viewer's own profile.
  final bool isMe;

  /// False for guests and on the viewer's own profile.
  final bool isFollowing;
  final bool followsYou;

  /// True on the viewer's own profile, or when this user made their reading stats public.
  final bool readingStatsVisible;

  /// The viewer muted this user (F28): "انت كاتم الكاتب ده" with "إلغاء الكتم". False for guests and on the viewer's
  /// own profile.
  final bool isMuted;

  /// The official @readin account (F28): it can't be muted, so its "⋯" has no Mute.
  final bool isSystemAccount;

  /// The smallest variant at least [size] px wide (the header asks for 2× its size), else [avatarUrl].
  String? avatarFor(double size) {
    if (avatarVariants.isEmpty) return avatarUrl;
    final widths = avatarVariants.keys.toList()..sort();
    final width = widths.where((w) => w >= size).firstOrNull ?? widths.last;
    return avatarVariants[width];
  }

  UserProfile copyWith({ProfileStats? stats, bool? isFollowing}) => UserProfile(
        id: id,
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        avatarVariants: avatarVariants,
        isVerified: isVerified,
        headline: headline,
        bio: bio,
        links: links,
        expertise: expertise,
        joinedAt: joinedAt,
        stats: stats ?? this.stats,
        isMe: isMe,
        isFollowing: isFollowing ?? this.isFollowing,
        followsYou: followsYou,
        readingStatsVisible: readingStatsVisible,
        isMuted: isMuted,
        isSystemAccount: isSystemAccount,
      );

  @override
  List<Object?> get props => [
        id,
        displayName,
        username,
        avatarUrl,
        avatarVariants,
        isVerified,
        headline,
        bio,
        links,
        expertise,
        joinedAt,
        stats,
        isMe,
        isFollowing,
        followsYou,
        readingStatsVisible,
        isMuted,
        isSystemAccount,
      ];
}

/// What to do with the avatar on save (`PATCH /me`).
sealed class AvatarChange extends Equatable {
  const AvatarChange();

  @override
  List<Object?> get props => [];
}

/// Leave the current avatar ([url], or none) as it is.
final class KeepAvatar extends AvatarChange {
  const KeepAvatar(this.url);

  final String? url;

  @override
  List<Object?> get props => [url];
}

/// An image uploaded with `purpose=avatar`.
final class NewAvatar extends AvatarChange {
  const NewAvatar(this.assetId);

  final String assetId;

  @override
  List<Object?> get props => [assetId];
}

final class RemoveAvatar extends AvatarChange {
  const RemoveAvatar();
}

/// An edited profile (`PATCH /me`, F14).
class ProfileUpdate extends Equatable {
  const ProfileUpdate({
    required this.displayName,
    required this.username,
    this.bio,
    this.headline,
    this.links,
    this.avatar = const KeepAvatar(null),
    this.expertiseFieldIds,
  });

  final String displayName;
  final String username;
  final String? bio;

  /// The title (F14); null or blank clears it. The form always sends it.
  final String? headline;

  /// The whole list in order (`[]` removes them all); null leaves the links unchanged.
  final List<ProfileLink>? links;
  final AvatarChange avatar;

  /// 0–5 field ids in order; null leaves the expertise unchanged.
  final List<String>? expertiseFieldIds;

  @override
  List<Object?> get props => [displayName, username, bio, headline, links, avatar, expertiseFieldIds];
}

/// Profile limits shared with the API (SPEC F14, contract-v1 `UpdateProfileRequest`).
abstract final class ProfileLimits {
  static const displayNameMin = 2;
  static const displayNameMax = 60;
  static const bioMax = 300;
  static const maxExpertise = 5;
}
