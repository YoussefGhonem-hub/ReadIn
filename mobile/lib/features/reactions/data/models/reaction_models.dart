import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/reactions.dart';

part 'reaction_models.freezed.dart';
part 'reaction_models.g.dart';

/// `PUT /articles/{id}/reaction` body.
@freezed
abstract class SetReactionRequest with _$SetReactionRequest {
  const factory SetReactionRequest({required String type}) = _SetReactionRequest;

  factory SetReactionRequest.fromJson(Map<String, dynamic> json) => _$SetReactionRequestFromJson(json);
}

/// `ArticleReactionsDto`.
@freezed
abstract class ArticleReactionsModel with _$ArticleReactionsModel {
  const ArticleReactionsModel._();

  const factory ArticleReactionsModel({
    @Default(ReactionCountsModel()) ReactionCountsModel reactions,
    int? total,
    String? myReaction,
  }) = _ArticleReactionsModel;

  factory ArticleReactionsModel.fromJson(Map<String, dynamic> json) => _$ArticleReactionsModelFromJson(json);

  ArticleReactions toEntity() {
    final counts = reactions.toEntity();
    return ArticleReactions(reactions: counts, total: total ?? counts.total, myReaction: reactionTypeFromWire(myReaction));
  }
}

/// `ReactorDto`. A type this app doesn't know yet is dropped by [toEntity].
@freezed
abstract class ReactorModel with _$ReactorModel {
  const ReactorModel._();

  const factory ReactorModel({required AuthorModel user, required String type, required DateTime reactedAt}) =
      _ReactorModel;

  factory ReactorModel.fromJson(Map<String, dynamic> json) => _$ReactorModelFromJson(json);

  Reactor? toEntity() {
    final reaction = reactionTypeFromWire(type);
    return reaction == null ? null : Reactor(user: user.toEntity(), type: reaction, reactedAt: reactedAt);
  }
}

/// `CursorPage<ReactorDto>`.
@freezed
abstract class ReactorPageModel with _$ReactorPageModel {
  const factory ReactorPageModel({@Default(<ReactorModel>[]) List<ReactorModel> items, String? nextCursor}) =
      _ReactorPageModel;

  factory ReactorPageModel.fromJson(Map<String, dynamic> json) => _$ReactorPageModelFromJson(json);
}
