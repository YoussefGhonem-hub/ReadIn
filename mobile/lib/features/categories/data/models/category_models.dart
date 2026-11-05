import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../article/data/models/article_models.dart';
import '../../domain/entities/writer_category.dart';

part 'category_models.freezed.dart';
part 'category_models.g.dart';

/// `WriterCategoryDto` (F31).
@freezed
abstract class WriterCategoryModel with _$WriterCategoryModel {
  const WriterCategoryModel._();

  const factory WriterCategoryModel({
    required String id,
    required String slug,
    required String name,
    @Default(0) int articleCount,
    @Default(0) int sortOrder,
  }) = _WriterCategoryModel;

  factory WriterCategoryModel.fromJson(Map<String, dynamic> json) => _$WriterCategoryModelFromJson(json);

  WriterCategory toEntity() => WriterCategory(id: id, slug: slug, name: name, articleCount: articleCount, sortOrder: sortOrder);
}

/// `WriterCategoryListDto`: `{ items, uncategorizedCount }`.
@freezed
abstract class WriterCategoryListModel with _$WriterCategoryListModel {
  const WriterCategoryListModel._();

  const factory WriterCategoryListModel({
    @Default(<WriterCategoryModel>[]) List<WriterCategoryModel> items,
    @Default(0) int uncategorizedCount,
  }) = _WriterCategoryListModel;

  factory WriterCategoryListModel.fromJson(Map<String, dynamic> json) => _$WriterCategoryListModelFromJson(json);

  WriterCategoryList toEntity() =>
      WriterCategoryList(items: [for (final c in items) c.toEntity()], uncategorizedCount: uncategorizedCount);
}

/// `WriterCategoryPageDto`: the category page's header (`id` and `name` null for `_other`).
@freezed
abstract class WriterCategoryPageModel with _$WriterCategoryPageModel {
  const WriterCategoryPageModel._();

  const factory WriterCategoryPageModel({
    String? id,
    required String slug,
    String? name,
    @Default(0) int articleCount,
    required AuthorModel author,
  }) = _WriterCategoryPageModel;

  factory WriterCategoryPageModel.fromJson(Map<String, dynamic> json) => _$WriterCategoryPageModelFromJson(json);

  WriterCategoryPage toEntity() =>
      WriterCategoryPage(id: id, slug: slug, name: name, articleCount: articleCount, author: author.toEntity());
}

/// `WriterCategoryRefDto`: `ArticleDetailsDto.category`.
@freezed
abstract class WriterCategoryRefModel with _$WriterCategoryRefModel {
  const WriterCategoryRefModel._();

  const factory WriterCategoryRefModel({required String slug, required String name}) = _WriterCategoryRefModel;

  factory WriterCategoryRefModel.fromJson(Map<String, dynamic> json) => _$WriterCategoryRefModelFromJson(json);

  WriterCategoryRef toEntity() => WriterCategoryRef(slug: slug, name: name);
}

/// `POST /me/categories` and `PATCH /me/categories/{id}` body: `{ name }`.
@freezed
abstract class CategoryNameRequest with _$CategoryNameRequest {
  const factory CategoryNameRequest({required String name}) = _CategoryNameRequest;

  factory CategoryNameRequest.fromJson(Map<String, dynamic> json) => _$CategoryNameRequestFromJson(json);
}

/// `PUT /me/categories/order` body: `{ categoryIds }`, the writer's categories in the new order.
@freezed
abstract class CategoryOrderRequest with _$CategoryOrderRequest {
  const factory CategoryOrderRequest({required List<String> categoryIds}) = _CategoryOrderRequest;

  factory CategoryOrderRequest.fromJson(Map<String, dynamic> json) => _$CategoryOrderRequestFromJson(json);
}
