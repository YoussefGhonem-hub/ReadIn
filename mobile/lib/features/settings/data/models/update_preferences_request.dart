import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_preferences_request.freezed.dart';
part 'update_preferences_request.g.dart';

/// `UpdatePreferencesRequest` (docs/api/contract-v1.md).
@freezed
abstract class UpdatePreferencesRequest with _$UpdatePreferencesRequest {
  const factory UpdatePreferencesRequest({
    required String uiLanguage,
    required String articleLanguage,
    required String theme,
    required String timeZone,
    required String reminderTime,
    // F30 "Hide highlights": left out (null) keeps the account's setting.
    bool? showHighlights,
  }) = _UpdatePreferencesRequest;

  factory UpdatePreferencesRequest.fromJson(Map<String, dynamic> json) => _$UpdatePreferencesRequestFromJson(json);
}
