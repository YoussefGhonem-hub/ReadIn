import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../follow/data/models/follow_models.dart';
import '../../domain/entities/blocks.dart';

part 'block_models.freezed.dart';
part 'block_models.g.dart';

/// `UserBlockStateDto` (F36).
@freezed
abstract class UserBlockStateModel with _$UserBlockStateModel {
  const UserBlockStateModel._();

  const factory UserBlockStateModel({
    required String userId,
    required bool isBlocked,
    @Default(false) bool followRemoved,
  }) = _UserBlockStateModel;

  factory UserBlockStateModel.fromJson(Map<String, dynamic> json) => _$UserBlockStateModelFromJson(json);

  UserBlockState toEntity() => UserBlockState(userId: userId, isBlocked: isBlocked, followRemoved: followRemoved);
}

/// `BlockedUserDto`.
@freezed
abstract class BlockedUserModel with _$BlockedUserModel {
  const BlockedUserModel._();

  const factory BlockedUserModel({required UserSummaryModel user, required DateTime blockedAt}) = _BlockedUserModel;

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) => _$BlockedUserModelFromJson(json);

  BlockedUser toEntity() => BlockedUser(user: user.toEntity(), blockedAt: blockedAt);
}

/// `GET /me/blocked` → `{ items }`.
@freezed
abstract class BlockedUsersModel with _$BlockedUsersModel {
  const factory BlockedUsersModel({@Default(<BlockedUserModel>[]) List<BlockedUserModel> items}) = _BlockedUsersModel;

  factory BlockedUsersModel.fromJson(Map<String, dynamic> json) => _$BlockedUsersModelFromJson(json);
}
