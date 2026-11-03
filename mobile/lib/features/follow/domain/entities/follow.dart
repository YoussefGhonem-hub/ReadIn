import 'package:equatable/equatable.dart';

/// `FollowStateDto` (F12).
class FollowState extends Equatable {
  const FollowState({required this.isFollowing, required this.followerCount});

  final bool isFollowing;
  final int followerCount;

  @override
  List<Object?> get props => [isFollowing, followerCount];
}

/// `UserSummaryDto`: a writer in "suggested writers" and in follower / following lists.
class UserSummary extends Equatable {
  const UserSummary({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.isVerified = false,
    this.bio,
    this.isFollowing = false,
    this.followsYou = false,
  });

  final String id;
  final String displayName;

  /// `@handle` without the `@`.
  final String username;
  final String? avatarUrl;
  final bool isVerified;
  final String? bio;

  /// The viewer follows this user (false for guests).
  final bool isFollowing;

  /// This user follows the viewer (false for guests).
  final bool followsYou;

  @override
  List<Object?> get props => [id, displayName, username, avatarUrl, isVerified, bio, isFollowing, followsYou];
}

/// `InterestsDto`: the fields and topics the user follows (F02, F12).
class Interests extends Equatable {
  const Interests({this.fieldIds = const [], this.topicIds = const []});

  final List<String> fieldIds;
  final List<String> topicIds;

  @override
  List<Object?> get props => [fieldIds, topicIds];
}
