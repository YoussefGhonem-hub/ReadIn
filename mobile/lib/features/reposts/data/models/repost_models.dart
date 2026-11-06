import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/repost_state.dart';

part 'repost_models.freezed.dart';
part 'repost_models.g.dart';

/// `RepostRequest`, the optional body of `PUT /articles/{id}/repost`: a missing or null `caption` keeps the caption (none
/// on a new repost), a string sets it and "" clears it. A quick repost sends no body at all.
@freezed
abstract class RepostRequest with _$RepostRequest {
  const factory RepostRequest({@JsonKey(includeIfNull: false) String? caption}) = _RepostRequest;

  factory RepostRequest.fromJson(Map<String, dynamic> json) => _$RepostRequestFromJson(json);
}

/// `RepostStateDto`: `{ repostCount, isReposted, caption }`.
@freezed
abstract class RepostStateModel with _$RepostStateModel {
  const RepostStateModel._();

  const factory RepostStateModel({@Default(0) int repostCount, @Default(false) bool isReposted, String? caption}) =
      _RepostStateModel;

  factory RepostStateModel.fromJson(Map<String, dynamic> json) => _$RepostStateModelFromJson(json);

  RepostState toEntity() => RepostState(
        repostCount: math.max(0, repostCount),
        isReposted: isReposted,
        // The caption goes with the repost; a blank one is none.
        caption: isReposted ? repostCaptionOrNull(caption) : null,
      );
}

/// A repost's caption as shown: null when missing or blank, otherwise as sent (line breaks kept).
String? repostCaptionOrNull(String? caption) => caption == null || caption.trim().isEmpty ? null : caption;
