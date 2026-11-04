import 'package:equatable/equatable.dart';

import 'editor_entities.dart';

/// The device copy of unsaved changes (SPEC F05 "local backup, offline-safe"), kept until the API has them.
class EditorBackup extends Equatable {
  const EditorBackup({
    required this.key,
    required this.document,
    required this.editedAt,
    this.articleId,
    this.baseVersion,
    this.status = ArticleLifecycle.draft,
    this.slug,
  });

  /// [newArticleKey] before the first autosave creates the article, then its id.
  static const newArticleKey = 'new';

  final String key;

  /// Null until the article exists on the server.
  final String? articleId;

  /// The working-copy version the changes were made on.
  final int? baseVersion;
  final ArticleLifecycle status;
  final String? slug;
  final ArticleDraftDocument document;

  /// The last edit kept in this copy.
  final DateTime editedAt;

  static String keyFor(String? articleId) => articleId ?? newArticleKey;

  @override
  List<Object?> get props => [key, articleId, baseVersion, status, slug, document, editedAt];
}
