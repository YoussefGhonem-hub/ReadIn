import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/follow.dart';

part 'follow_models.freezed.dart';
part 'follow_models.g.dart';

/// `FollowStateDto`.
@freezed
abstract class FollowStateModel with _$FollowStateModel {
  const FollowStateModel._();

  const factory FollowStateModel({required bool isFollowing, @Default(0) int followerCount}) = _FollowStateModel;

  factory FollowStateModel.fromJson(Map<String, dynamic> json) => _$FollowStateModelFromJson(json);

  FollowState toEntity() => FollowState(isFollowing: isFollowing, followerCount: followerCount);
}

/// `UserSummaryDto`.
@freezed
abstract class UserSummaryModel with _$UserSummaryModel {
  const UserSummaryModel._();

  const factory UserSummaryModel({
    required String id,
    required String displayName,
    required String username,
    String? avatarUrl,
    @Default(false) bool isVerified,
    String? bio,
    @Default(false) bool isFollowing,
    @Default(false) bool followsYou,
  }) = _UserSummaryModel;

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) => _$UserSummaryModelFromJson(json);

  UserSummary toEntity() => UserSummary(
        id: id,
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        isVerified: isVerified,
        bio: bio,
        isFollowing: isFollowing,
        followsYou: followsYou,
      );
}

/// `CursorPage<UserSummaryDto>`.
@freezed
abstract class UserSummaryPageModel with _$UserSummaryPageModel {
  const factory UserSummaryPageModel({@Default(<UserSummaryModel>[]) List<UserSummaryModel> items, String? nextCursor}) =
      _UserSummaryPageModel;

  factory UserSummaryPageModel.fromJson(Map<String, dynamic> json) => _$UserSummaryPageModelFromJson(json);
}

/// `InterestsDto`: not spelled out in the contract; this is the `interests` shape of `MeDto`.
@freezed
abstract class InterestsModel with _$InterestsModel {
  const InterestsModel._();

  const factory InterestsModel({
    @Default(<String>[]) List<String> fieldIds,
    @Default(<String>[]) List<String> topicIds,
  }) = _InterestsModel;

  factory InterestsModel.fromJson(Map<String, dynamic> json) => _$InterestsModelFromJson(json);

  Interests toEntity() => Interests(fieldIds: fieldIds, topicIds: topicIds);
}
