import 'package:equatable/equatable.dart';

import '../../../follow/domain/entities/follow.dart';

export '../../../follow/domain/entities/follow.dart' show UserSummary;

/// `UserBlockStateDto` (F36): the block after `PUT` / `DELETE /users/{id}/block`.
class UserBlockState extends Equatable {
  const UserBlockState({required this.userId, required this.isBlocked, this.followRemoved = false});

  final String userId;
  final bool isBlocked;

  /// The block ended the viewer's follow of them: its Undo follows them again (`restoreFollow=true`). Never true after
  /// an unblock.
  final bool followRemoved;

  @override
  List<Object?> get props => [userId, isBlocked, followRemoved];
}

/// `BlockedUserDto`: a row of Settings → Blocked accounts.
class BlockedUser extends Equatable {
  const BlockedUser({required this.user, required this.blockedAt});

  final UserSummary user;
  final DateTime blockedAt;

  @override
  List<Object?> get props => [user, blockedAt];
}

/// The person a `403 block.blocked` names (`blockedUser`): the viewer blocked them, so their content and profile show
/// "isn't available" with «إلغاء الحظر» / "Unblock".
class BlockedPerson extends Equatable {
  const BlockedPerson({required this.id, required this.username, required this.displayName});

  final String id;
  final String username;
  final String displayName;

  @override
  List<Object?> get props => [id, username, displayName];
}
