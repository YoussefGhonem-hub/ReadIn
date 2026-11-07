import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/update_policy.dart';

part 'update_policy_models.freezed.dart';
part 'update_policy_models.g.dart';

/// `PlatformUpdatePolicyDto`.
@freezed
abstract class PlatformUpdatePolicyModel with _$PlatformUpdatePolicyModel {
  const PlatformUpdatePolicyModel._();

  const factory PlatformUpdatePolicyModel({String? minimumVersion, String? storeUrl}) = _PlatformUpdatePolicyModel;

  factory PlatformUpdatePolicyModel.fromJson(Map<String, dynamic> json) => _$PlatformUpdatePolicyModelFromJson(json);

  PlatformUpdatePolicy toEntity() => PlatformUpdatePolicy(minimumVersion: minimumVersion, storeUrl: storeUrl);
}

/// `UpdatePolicyDto`: `GET /app/update-policy`. A platform left out has no minimum.
@freezed
abstract class UpdatePolicyModel with _$UpdatePolicyModel {
  const UpdatePolicyModel._();

  const factory UpdatePolicyModel({
    PlatformUpdatePolicyModel? ios,
    PlatformUpdatePolicyModel? android,
  }) = _UpdatePolicyModel;

  factory UpdatePolicyModel.fromJson(Map<String, dynamic> json) => _$UpdatePolicyModelFromJson(json);

  UpdatePolicy toEntity() => UpdatePolicy(
        ios: ios?.toEntity() ?? const PlatformUpdatePolicy(),
        android: android?.toEntity() ?? const PlatformUpdatePolicy(),
      );
}
