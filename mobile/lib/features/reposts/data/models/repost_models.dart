import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/repost_state.dart';

part 'repost_models.freezed.dart';
part 'repost_models.g.dart';

/// `RepostStateDto`.
@freezed
abstract class RepostStateModel with _$RepostStateModel {
  const RepostStateModel._();

  const factory RepostStateModel({@Default(0) int repostCount, @Default(false) bool isReposted}) = _RepostStateModel;

  factory RepostStateModel.fromJson(Map<String, dynamic> json) => _$RepostStateModelFromJson(json);

  RepostState toEntity() => RepostState(repostCount: math.max(0, repostCount), isReposted: isReposted);
}
