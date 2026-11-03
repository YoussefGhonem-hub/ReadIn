import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:readin/features/article/data/datasources/article_offline_store.dart';

import '../../helpers/social_fakes.dart';

void main() {
  late Directory dir;
  late HiveArticleOfflineStore store;
  var box = 0;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('readin_offline_');
    Hive.init(dir.path);
    final name = 'offline_${box++}';
    store = HiveArticleOfflineStore.withBox(() => Hive.openLazyBox<String>(name));
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('keeps a copy per language and finds it by slug', () async {
    await store.put(detailsModel(1, isSaved: true));
    await store.put(detailsModel(1, language: 'en', isSaved: true));

    expect((await store.find('article-1', language: 'en'))!.language, 'en');
    expect((await store.find('article-1', language: 'ar-EG'))!.language, 'ar-EG');
    expect(await store.find('article-1'), isNotNull, reason: 'any language when none is asked for');
    expect(await store.find('article-2'), isNull);
    expect(await store.contains('art-1'), isTrue);
  });

  test('unsaving drops every language', () async {
    await store.put(detailsModel(1));
    await store.put(detailsModel(1, language: 'en'));
    await store.remove('art-1');
    expect(await store.contains('art-1'), isFalse);
    expect(await store.find('article-1'), isNull);
  });

  test('lists one copy per article, the most recently saved first; a refresh keeps the save time', () async {
    await store.put(detailsModel(1), savedAt: DateTime.utc(2026, 10, 1));
    await store.put(detailsModel(2), savedAt: DateTime.utc(2026, 11, 1));
    await store.put(detailsModel(1, language: 'en'));

    final all = await store.all();
    expect([for (final copy in all) copy.article.id], ['art-2', 'art-1']);
    expect(all.last.savedAt, DateTime.utc(2026, 10, 1));
  });

  test('retainOnly keeps the articles still saved', () async {
    await store.put(detailsModel(1));
    await store.put(detailsModel(2));
    await store.retainOnly({'art-2'});
    expect([for (final copy in await store.all()) copy.article.id], ['art-2']);
  });

  test('copies belong to one account: another user or signing out clears them', () async {
    await store.claim('u-1');
    await store.put(detailsModel(1));
    await store.claim('u-1');
    expect(await store.contains('art-1'), isTrue, reason: 'same user, e.g. an app restart');

    await store.claim('u-2');
    expect(await store.contains('art-1'), isFalse);

    await store.put(detailsModel(2));
    await store.claim(null);
    expect(await store.all(), isEmpty);
  });

  test('remembers the last few details fetched this session', () {
    for (var i = 0; i < 10; i++) {
      store.remember(detailsModel(i));
    }
    store.remember(detailsModel(2)); // used again: the most recent now
    store.remember(detailsModel(10));
    expect(store.recent('art-2'), isNotNull);
    expect(store.recent('art-10'), isNotNull);
    expect(store.recent('art-3'), isNull, reason: 'only the 8 most recent are kept');
  });
}
