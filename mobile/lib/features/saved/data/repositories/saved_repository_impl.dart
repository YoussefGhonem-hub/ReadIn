import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../article/data/datasources/article_api.dart';
import '../../../article/data/datasources/article_offline_store.dart';
import '../../../article/data/repositories/article_repository_impl.dart';
import '../../../article/domain/entities/article.dart';
import '../../domain/entities/saved.dart';
import '../../domain/repositories/saved_repository.dart';
import '../datasources/saved_api.dart';
import '../models/saved_models.dart';

@LazySingleton(as: SavedRepository)
class SavedRepositoryImpl implements SavedRepository {
  SavedRepositoryImpl(this._api, this._articles, this._offline);

  final SavedApi _api;
  final ArticleApi _articles;
  final ArticleOfflineStore _offline;

  /// Device-copy work runs one job at a time, in order, so "save then unsave" never leaves a copy behind.
  Future<void> _offlineQueue = Future.value();

  /// Completes when the device-copy work queued so far is done.
  @visibleForTesting
  Future<void> get offlineWork => _offlineQueue;

  void _enqueue(Future<void> Function() job) => _offlineQueue = _offlineQueue.then((_) => job()).catchError(
        (Object error) => debugPrint('Offline copy of a saved article failed: $error'),
      );

  /// Keeps the details of [article] on this device: the copy the reader just fetched, else a fresh one.
  Future<void> _keepOffline(String id, String slug, String language, {DateTime? savedAt}) async {
    final details = _offline.recent(id) ?? await _articles.getArticle(slug, language);
    await _offline.put(details.copyWith(isSaved: true), savedAt: savedAt);
  }

  @override
  Future<Result<SaveState>> save(ArticleCard article) async {
    final result = await guardApi(() async => (await _api.save(article.id)).toEntity());
    if (result.isOk) _enqueue(() => _keepOffline(article.id, article.slug, article.language, savedAt: DateTime.now()));
    return result;
  }

  @override
  Future<Result<SaveState>> unsave(String articleId) async {
    final result = await guardApi(() async => (await _api.unsave(articleId)).toEntity());
    if (result.isOk) _enqueue(() => _offline.remove(articleId));
    return result;
  }

  @override
  Future<Result<SavedArticlesPage>> getSaved({SavedFilter filter = const SavedFilter(), String? cursor, int limit = 20}) async {
    final query = filter.query?.trim();
    final result = await guardApi(() async {
      final page = await _api.getSaved(filter.fieldSlug, query == null || query.isEmpty ? null : query, filter.collectionId, cursor, limit);
      return (page, SavedArticlesPage(items: [for (final m in page.items) m.toEntity()], nextCursor: page.nextCursor));
    });
    switch (result) {
      case Ok(value: (final models, final page)):
        // Articles saved on another device become readable offline too; the complete list drops stale copies.
        if (filter.isEmpty) _enqueue(() => _syncOffline(models, complete: cursor == null && page.nextCursor == null));
        return Ok(page);
      case Err(:final failure):
        if (!ArticleRepositoryImpl.isUnreachable(failure) || cursor != null || filter.collectionId != null) {
          return Err(failure);
        }
        final copies = await _offline.all().catchError((Object _) => <OfflineArticle>[]);
        if (copies.isEmpty) return Err(failure);
        final needle = normalizeForSearch(query ?? '');
        return Ok(SavedArticlesPage(
          offline: true,
          items: [
            for (final copy in copies)
              if ((filter.fieldSlug == null || copy.article.field.slug == filter.fieldSlug) &&
                  (needle.isEmpty || normalizeForSearch(copy.article.title).contains(needle)))
                SavedArticle(savedAt: copy.savedAt, article: copy.article.toCard().copyWithEngagement(isSaved: true)),
          ],
        ));
    }
  }

  Future<void> _syncOffline(SavedArticlePageModel page, {required bool complete}) async {
    for (final item in page.items) {
      if (await _offline.contains(item.article.id)) continue;
      try {
        await _keepOffline(item.article.id, item.article.slug, item.article.language, savedAt: item.savedAt);
      } catch (error) {
        debugPrint('Could not keep ${item.article.slug} offline: $error');
      }
    }
    if (complete) await _offline.retainOnly({for (final item in page.items) item.article.id});
  }

  @override
  Future<Result<List<ArticleCollection>>> getCollections() =>
      guardApi(() async => [for (final m in await _api.getCollections()) m.toEntity()]);

  @override
  Future<Result<ArticleCollection>> createCollection(String name) =>
      guardApi(() async => (await _api.createCollection(CollectionNameRequest(name: name))).toEntity());

  @override
  Future<Result<ArticleCollection>> renameCollection(String id, String name) =>
      guardApi(() async => (await _api.renameCollection(id, CollectionNameRequest(name: name))).toEntity());

  @override
  Future<Result<void>> deleteCollection(String id) => guardApi(() => _api.deleteCollection(id));

  @override
  Future<Result<void>> addToCollection(String collectionId, String articleId) =>
      guardApi(() => _api.addToCollection(collectionId, articleId));

  @override
  Future<Result<void>> removeFromCollection(String collectionId, String articleId) =>
      guardApi(() => _api.removeFromCollection(collectionId, articleId));
}

/// Case- and Arabic-insensitive matching for the offline search, close to the API's collation: no diacritics or
/// tatweel, and one form each of alef, yeh and teh marbuta.
String normalizeForSearch(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    if ((rune >= 0x064B && rune <= 0x0652) || rune == 0x0640 || rune == 0x0670) continue;
    buffer.writeCharCode(switch (rune) {
      0x0622 || 0x0623 || 0x0625 || 0x0671 => 0x0627, // آ أ إ ٱ → ا
      0x0649 => 0x064A, // ى → ي
      0x0629 => 0x0647, // ة → ه
      _ => rune,
    });
  }
  return buffer.toString().trim();
}
