import 'package:equatable/equatable.dart';

import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';

/// `SaveStateDto`.
class SaveState extends Equatable {
  const SaveState({required this.isSaved, required this.saveCount});

  final bool isSaved;
  final int saveCount;

  @override
  List<Object?> get props => [isSaved, saveCount];
}

/// `SavedArticleDto`: one saved article and the collections it is in (F13).
class SavedArticle extends Equatable {
  const SavedArticle({required this.savedAt, required this.article, this.collectionIds = const []});

  final DateTime savedAt;
  final List<String> collectionIds;
  final ArticleCard article;

  @override
  List<Object?> get props => [savedAt, collectionIds, article];
}

/// `CollectionDto`: a named list of saved articles (e.g. "Interview prep").
class ArticleCollection extends Equatable {
  const ArticleCollection({required this.id, required this.name, required this.articleCount, required this.createdAt});

  final String id;
  final String name;
  final int articleCount;
  final DateTime createdAt;

  ArticleCollection copyWith({String? name, int? articleCount}) =>
      ArticleCollection(id: id, name: name ?? this.name, articleCount: articleCount ?? this.articleCount, createdAt: createdAt);

  @override
  List<Object?> get props => [id, name, articleCount, createdAt];
}

/// Filters of `GET /me/saved`; all null = every saved article.
class SavedFilter extends Equatable {
  const SavedFilter({this.fieldSlug, this.query, this.collectionId});

  final String? fieldSlug;

  /// Title search; blank means none.
  final String? query;
  final String? collectionId;

  bool get isEmpty => fieldSlug == null && (query == null || query!.trim().isEmpty) && collectionId == null;

  @override
  List<Object?> get props => [fieldSlug, query, collectionId];
}

/// A page of saved articles. [offline] = the API was unreachable and these are the copies kept on this device.
class SavedArticlesPage extends CursorPage<SavedArticle> {
  const SavedArticlesPage({required super.items, super.nextCursor, this.offline = false});

  final bool offline;

  @override
  List<Object?> get props => [...super.props, offline];
}
