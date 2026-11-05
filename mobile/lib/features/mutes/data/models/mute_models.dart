import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../follow/data/models/follow_models.dart';
import '../../domain/entities/mutes.dart';

part 'mute_models.freezed.dart';
part 'mute_models.g.dart';

/// `UserMuteStateDto` (F28).
@freezed
abstract class UserMuteStateModel with _$UserMuteStateModel {
  const UserMuteStateModel._();

  const factory UserMuteStateModel({
    required bool isMuted,
    @Default(false) bool isFollowing,
    @Default(0) int followerCount,
    @Default(false) bool followRemoved,
  }) = _UserMuteStateModel;

  factory UserMuteStateModel.fromJson(Map<String, dynamic> json) => _$UserMuteStateModelFromJson(json);

  UserMuteState toEntity() =>
      UserMuteState(isMuted: isMuted, isFollowing: isFollowing, followerCount: followerCount, followRemoved: followRemoved);
}

/// `ContentMutesDto` (F28).
@freezed
abstract class ContentMutesModel with _$ContentMutesModel {
  const ContentMutesModel._();

  const factory ContentMutesModel({
    @Default(<String>[]) List<String> fieldIds,
    @Default(<String>[]) List<String> topicIds,
  }) = _ContentMutesModel;

  factory ContentMutesModel.fromJson(Map<String, dynamic> json) => _$ContentMutesModelFromJson(json);

  ContentMutes toEntity() => ContentMutes(fieldIds: fieldIds, topicIds: topicIds);
}

/// `MutedFieldDto` (F28). `name` (in the request's language) isn't needed: the app picks [nameAr] or [nameEn].
@freezed
abstract class MutedFieldModel with _$MutedFieldModel {
  const MutedFieldModel._();

  const factory MutedFieldModel({
    required String id,
    required String slug,
    String? name,
    required String nameAr,
    required String nameEn,
    @Default('book-open') String icon,
    @Default('primary') String color,
  }) = _MutedFieldModel;

  factory MutedFieldModel.fromJson(Map<String, dynamic> json) => _$MutedFieldModelFromJson(json);

  MutedField toEntity() => MutedField(id: id, slug: slug, nameAr: nameAr, nameEn: nameEn, icon: icon, color: color);
}

/// `MutedTopicDto` (F28).
@freezed
abstract class MutedTopicModel with _$MutedTopicModel {
  const MutedTopicModel._();

  const factory MutedTopicModel({
    required String id,
    required String slug,
    String? name,
    required String nameAr,
    required String nameEn,
    required MutedFieldModel field,
  }) = _MutedTopicModel;

  factory MutedTopicModel.fromJson(Map<String, dynamic> json) => _$MutedTopicModelFromJson(json);

  MutedTopic toEntity() => MutedTopic(id: id, slug: slug, nameAr: nameAr, nameEn: nameEn, field: field.toEntity());
}

/// `MutesDto` (`GET /me/mutes`, F28).
@freezed
abstract class MutesModel with _$MutesModel {
  const MutesModel._();

  const factory MutesModel({
    @Default(<UserSummaryModel>[]) List<UserSummaryModel> users,
    @Default(<MutedFieldModel>[]) List<MutedFieldModel> fields,
    @Default(<MutedTopicModel>[]) List<MutedTopicModel> topics,
  }) = _MutesModel;

  factory MutesModel.fromJson(Map<String, dynamic> json) => _$MutesModelFromJson(json);

  Mutes toEntity() => Mutes(
        users: [for (final u in users) u.toEntity()],
        fields: [for (final f in fields) f.toEntity()],
        topics: [for (final t in topics) t.toEntity()],
      );
}
