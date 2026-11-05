import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';

/// A writer's category (F31, "أقسام الكاتب"): their own way to group their articles, apart from fields and topics
/// (platform-wide), collections (private) and learning paths. Shown with its name in its own direction (`dir="auto"`);
/// linked with its [slug], never with a name.
class WriterCategory extends Equatable {
  const WriterCategory({required this.id, required this.slug, required this.name, this.articleCount = 0, this.sortOrder = 0});

  final String id;

  /// Made once from the name (Arabic allowed) and never changed by a rename, so links keep working.
  final String slug;

  /// 1–40 characters, the writer's spelling.
  final String name;

  /// Articles readers can see in it, the same for everyone; 0 only in the writer's own list (`GET /me/categories`).
  final int articleCount;

  /// The writer's order, ascending.
  final int sortOrder;

  bool get isEmpty => articleCount == 0;

  WriterCategory copyWith({String? name, int? articleCount, int? sortOrder}) => WriterCategory(
        id: id,
        slug: slug,
        name: name ?? this.name,
        articleCount: articleCount ?? this.articleCount,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  WriterCategoryRef get ref => WriterCategoryRef(slug: slug, name: name);

  @override
  List<Object?> get props => [id, slug, name, articleCount, sortOrder];
}

/// `WriterCategoryListDto`: a profile's Categories tab (`GET /users/{username}/categories`: the non-empty ones) or the
/// writer's own list (`GET /me/categories`: all of them), in the writer's order, and the count of the last card,
/// "مقالات تانية" (the articles without a category; hidden when 0).
class WriterCategoryList extends Equatable {
  const WriterCategoryList({this.items = const [], this.uncategorizedCount = 0});

  final List<WriterCategory> items;
  final int uncategorizedCount;

  static const empty = WriterCategoryList();

  @override
  List<Object?> get props => [items, uncategorizedCount];
}

/// `WriterCategoryPageDto`: the category page's header. The uncategorized list (the reserved slug `_other`) has no [id]
/// and no [name] ("مقالات تانية" / "Other articles").
class WriterCategoryPage extends Equatable {
  const WriterCategoryPage({required this.slug, required this.author, this.id, this.name, this.articleCount = 0});

  final String? id;
  final String slug;
  final String? name;

  /// Articles readers can see; 0 → the empty state.
  final int articleCount;

  /// The writer: the link back to their profile.
  final Author author;

  /// "مقالات تانية": the writer's articles without a category.
  bool get isOther => id == null || name == null;

  @override
  List<Object?> get props => [id, slug, name, articleCount, author];
}

/// `ArticleDetailsDto.category`: the reader's "في قسم {name}" link to the category page.
class WriterCategoryRef extends Equatable {
  const WriterCategoryRef({required this.slug, required this.name});

  final String slug;
  final String name;

  @override
  List<Object?> get props => [slug, name];
}
