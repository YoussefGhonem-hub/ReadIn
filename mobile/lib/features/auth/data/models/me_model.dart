import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/me.dart';

part 'me_model.freezed.dart';
part 'me_model.g.dart';

/// `MeDto` (docs/api/contract-v1.md).
@freezed
abstract class MeModel with _$MeModel {
  const MeModel._();

  const factory MeModel({
    required String id,
    required String email,
    required String displayName,
    required String username,
    String? avatarUrl,
    String? bio,
    @Default(<String, String>{}) Map<String, String> links,
    @Default('ar') String uiLanguage,
    @Default('ar-EG') String articleLanguage,
    @Default('system') String theme,
    @Default('UTC') String timeZone,
    @Default('08:00') String reminderTime,
    @Default(false) bool isVerified,
    @Default(false) bool onboardingCompleted,
    @Default(<String>[]) List<String> roles,
    @Default(<String>[]) List<String> permissions,
    @Default(InterestsModel()) InterestsModel interests,
  }) = _MeModel;

  factory MeModel.fromJson(Map<String, dynamic> json) => _$MeModelFromJson(json);

  Me toEntity() => Me(
        id: id,
        email: email,
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        bio: bio,
        links: links,
        uiLanguage: uiLanguage,
        articleLanguage: articleLanguage,
        theme: theme,
        timeZone: timeZone,
        reminderTime: reminderTime,
        isVerified: isVerified,
        onboardingCompleted: onboardingCompleted,
        roles: roles,
        permissions: permissions,
        interestFieldIds: interests.fieldIds,
        interestTopicIds: interests.topicIds,
      );
}

@freezed
abstract class InterestsModel with _$InterestsModel {
  const factory InterestsModel({
    @Default(<String>[]) List<String> fieldIds,
    @Default(<String>[]) List<String> topicIds,
  }) = _InterestsModel;

  factory InterestsModel.fromJson(Map<String, dynamic> json) => _$InterestsModelFromJson(json);
}

/// `SyncUserRequest`.
@freezed
abstract class SyncUserRequest with _$SyncUserRequest {
  const factory SyncUserRequest({String? uiLanguage, String? timeZone}) = _SyncUserRequest;

  factory SyncUserRequest.fromJson(Map<String, dynamic> json) => _$SyncUserRequestFromJson(json);
}
