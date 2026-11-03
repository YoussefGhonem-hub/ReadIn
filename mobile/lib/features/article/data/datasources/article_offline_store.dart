import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../models/article_models.dart';

/// A saved article as kept on this device: its `ArticleDetailsDto` JSON and when it was saved.
class OfflineArticle {
  const OfflineArticle({required this.article, required this.savedAt});

  final ArticleDetailsModel article;
  final DateTime savedAt;
}

/// Device copies of saved articles, readable without a connection (SPEC F13, F25, §8.2). One copy per article and
/// language, belonging to one account: [claim] clears them when someone else signs in or the user signs out.
abstract interface class ArticleOfflineStore {
  /// Keeps (or refreshes) the copy of [article]. [savedAt] defaults to the existing copy's, else now.
  Future<void> put(ArticleDetailsModel article, {DateTime? savedAt});

  /// The copy of [slug] in [language], else in any language; null when there is none.
  Future<ArticleDetailsModel?> find(String slug, {String? language});

  Future<bool> contains(String articleId);

  /// Drops every language of [articleId] (unsaved).
  Future<void> remove(String articleId);

  /// One copy per article, the most recently saved first.
  Future<List<OfflineArticle>> all();

  /// Keeps only the copies of [articleIds] (the full saved list from the API).
  Future<void> retainOnly(Set<String> articleIds);

  /// Copies belong to [userId]; another user (or null: signed out) clears them first.
  Future<void> claim(String? userId);

  /// The last details fetched in this session for [articleId], so saving from the reader needs no extra request.
  ArticleDetailsModel? recent(String articleId);

  void remember(ArticleDetailsModel article);
}

@LazySingleton(as: ArticleOfflineStore)
class HiveArticleOfflineStore implements ArticleOfflineStore {
  HiveArticleOfflineStore() : this.withBox(() => Hive.openLazyBox<String>(boxName));

  /// [open] is a test seam (a box in a temporary folder).
  @visibleForTesting
  HiveArticleOfflineStore.withBox(Future<LazyBox<String>> Function() open) : _open = open;

  /// Lazy: only the copies that are read are loaded into memory.
  static const boxName = 'readin.offline_articles';
  static const _ownerKey = '_owner';
  static const _recentLimit = 8;

  final Future<LazyBox<String>> Function() _open;
  Future<LazyBox<String>>? _box;
  final _recent = <String, ArticleDetailsModel>{};

  Future<LazyBox<String>> get _ready => _box ??= _open();

  static String _key(String articleId, String language) => '$articleId|$language';

  static String _idOf(String key) => key.split('|').first;

  Iterable<String> _articleKeys(LazyBox<String> box) =>
      box.keys.whereType<String>().where((key) => key != _ownerKey && key.contains('|'));

  Future<({ArticleDetailsModel article, DateTime savedAt})?> _read(LazyBox<String> box, String key) async {
    try {
      final raw = await box.get(key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        article: ArticleDetailsModel.fromJson(json['article'] as Map<String, dynamic>),
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (error) {
      debugPrint('Dropping an unreadable offline article $key: $error');
      await box.delete(key);
      return null;
    }
  }

  @override
  Future<void> put(ArticleDetailsModel article, {DateTime? savedAt}) async {
    final box = await _ready;
    var when = savedAt;
    if (when == null) {
      for (final key in _articleKeys(box).where((k) => _idOf(k) == article.id)) {
        when = (await _read(box, key))?.savedAt;
        if (when != null) break;
      }
    }
    final value = jsonEncode({'savedAt': (when ?? DateTime.now()).toUtc().toIso8601String(), 'article': article.toJson()});
    await box.put(_key(article.id, article.language), value);
  }

  @override
  Future<ArticleDetailsModel?> find(String slug, {String? language}) async {
    final box = await _ready;
    ArticleDetailsModel? any;
    for (final key in _articleKeys(box).toList()) {
      final entry = await _read(box, key);
      if (entry == null || entry.article.slug != slug) continue;
      if (language == null || entry.article.language == language) return entry.article;
      any ??= entry.article;
    }
    return any;
  }

  @override
  Future<bool> contains(String articleId) async => _articleKeys(await _ready).any((k) => _idOf(k) == articleId);

  @override
  Future<void> remove(String articleId) async {
    final box = await _ready;
    await box.deleteAll(_articleKeys(box).where((k) => _idOf(k) == articleId).toList());
  }

  @override
  Future<List<OfflineArticle>> all() async {
    final box = await _ready;
    final byId = <String, OfflineArticle>{};
    for (final key in _articleKeys(box).toList()) {
      final entry = await _read(box, key);
      if (entry == null) continue;
      final current = byId[entry.article.id];
      if (current == null || entry.savedAt.isAfter(current.savedAt)) {
        byId[entry.article.id] = OfflineArticle(article: entry.article, savedAt: entry.savedAt);
      }
    }
    return byId.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  @override
  Future<void> retainOnly(Set<String> articleIds) async {
    final box = await _ready;
    await box.deleteAll(_articleKeys(box).where((k) => !articleIds.contains(_idOf(k))).toList());
  }

  @override
  Future<void> claim(String? userId) async {
    final box = await _ready;
    final owner = await box.get(_ownerKey);
    if (owner == userId && (userId != null || box.isEmpty)) return;
    _recent.clear();
    await box.clear();
    if (userId != null) await box.put(_ownerKey, userId);
  }

  @override
  ArticleDetailsModel? recent(String articleId) => _recent[articleId];

  @override
  void remember(ArticleDetailsModel article) {
    _recent
      ..remove(article.id)
      ..[article.id] = article;
    if (_recent.length > _recentLimit) _recent.remove(_recent.keys.first);
  }
}
