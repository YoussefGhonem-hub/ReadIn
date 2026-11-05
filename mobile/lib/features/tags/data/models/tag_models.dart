import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/tag.dart';

part 'tag_models.freezed.dart';
part 'tag_models.g.dart';

/// `TagRefDto` (F32): a tag on a card or in the reader.
@freezed
abstract class TagRefModel with _$TagRefModel {
  const TagRefModel._();

  const factory TagRefModel({@Default('') String slug, required String name}) = _TagRefModel;

  factory TagRefModel.fromJson(Map<String, dynamic> json) => _$TagRefModelFromJson(json);

  TagRef toEntity() => TagRef(slug: slug, name: name);
}

/// `tags` of `ArticleCardDto` and `ArticleDetailsDto`. Before F32 they were names (`string[]`), and a saved article's
/// offline copy may still hold them: such a name becomes a tag without a page (no slug).
List<TagRefModel> tagRefsFromJson(Object? json) => [
      if (json is List)
        for (final item in json)
          if (item is Map<String, dynamic> && item['name'] is String)
            TagRefModel.fromJson(item)
          else if (item is String && item.trim().isNotEmpty)
            TagRefModel(name: item),
    ];

List<Map<String, dynamic>> tagRefsToJson(List<TagRefModel> tags) => [for (final t in tags) t.toJson()];

/// `TagDto`: an editor suggestion and the tag page's header.
@freezed
abstract class TagModel with _$TagModel {
  const TagModel._();

  const factory TagModel({required String slug, required String name, @Default(0) int articleCount}) = _TagModel;

  factory TagModel.fromJson(Map<String, dynamic> json) => _$TagModelFromJson(json);

  ArticleTag toEntity() => ArticleTag(slug: slug, name: name, articleCount: articleCount);
}
