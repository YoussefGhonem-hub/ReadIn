import 'package:flutter_test/flutter_test.dart';
import 'package:readin/app/router.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/failure_messages.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/storage/key_value_store.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/search/data/datasources/recent_searches_store.dart';
import 'package:readin/features/search/domain/entities/search.dart';
import 'package:readin/features/search/domain/services/search_query.dart';
import 'package:readin/features/search/presentation/search_routes.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';

import '../../helpers/fixtures.dart';

/// The query rules (contract "Search (F16)" → "The query"), the device's recent searches, the filters' wire values,
/// the field page links and the `/search` route.
void main() {
  group('SearchQuery', () {
    test('as you type from 2 characters, on Enter from 1', () {
      expect(SearchQuery.canSearch('d'), isFalse);
      expect(SearchQuery.canSearch('do'), isTrue);
      expect(SearchQuery.canSearch('C', submitted: true), isTrue);
      expect(SearchQuery.canSearch('', submitted: true), isFalse);
      expect(SearchQuery.canSearch('ذك'), isTrue);
    });

    test('counts what the API counts: cleaned, without a leading # or @', () {
      expect(SearchQuery.canSearch('  d  '), isFalse, reason: 'trimmed');
      expect(SearchQuery.canSearch('#a'), isFalse, reason: 'the # is dropped');
      expect(SearchQuery.canSearch('@m'), isFalse, reason: 'one leading @ is dropped');
      expect(SearchQuery.canSearch('@mo'), isTrue);
      expect(SearchQuery.canSearch('٢٠'), isTrue, reason: 'Arabic-Indic digits are digits');
    });

    test('needs a letter or a digit: symbols or tatweel alone are refused', () {
      expect(SearchQuery.canSearch('##', submitted: true), isFalse);
      expect(SearchQuery.canSearch('@', submitted: true), isFalse);
      expect(SearchQuery.canSearch('++', submitted: true), isFalse);
      expect(SearchQuery.canSearch('ـــ', submitted: true), isFalse);
      expect(SearchQuery.canSearch('C++', submitted: true), isTrue);
    });

    test('at most 100 characters', () {
      expect(SearchQuery.canSearch('a' * 100), isTrue);
      expect(SearchQuery.canSearch('a' * 101), isFalse);
    });

    test('clean: what is sent as q', () {
      final lrm = String.fromCharCode(0x200E);
      expect(SearchQuery.clean('  Docker   compose '), 'Docker compose');
      expect(SearchQuery.clean('${lrm}EF Core$lrm'), 'EF Core');
      expect(SearchQuery.clean('.NET ١٠'), '.NET 10');
      expect(SearchQuery.clean('@mona_dev'), '@mona_dev', reason: 'the API drops the @ itself');
    });

    test('the same search whatever the case, the letter forms, # or @', () {
      expect(SearchQuery.key('Docker'), SearchQuery.key('docker '));
      expect(SearchQuery.key('أحمد'), SearchQuery.key('احمد'));
      expect(SearchQuery.key('مكتبة'), SearchQuery.key('مكتبه'));
      expect(SearchQuery.key('الذَّكاء'), SearchQuery.key('الذكاء'));
      expect(SearchQuery.key('#AI'), SearchQuery.key('ai'));
      expect(SearchQuery.key('@mona'), SearchQuery.key('mona'));
      expect(SearchQuery.key('docker'), isNot(SearchQuery.key('dockers')));
    });
  });

  group('RecentSearchesStore', () {
    test('newest first, at most 10', () async {
      final store = RecentSearchesStore(InMemoryKeyValueStore());
      expect(store.read(), isEmpty);
      for (var i = 1; i <= 12; i++) {
        await store.add('query $i');
      }
      expect(store.read(), [for (var i = 12; i >= 3; i--) 'query $i']);
    });

    test('searching again moves it first, once, with the newest spelling', () async {
      final store = RecentSearchesStore(InMemoryKeyValueStore());
      await store.add('Docker');
      await store.add('أحمد');
      await store.add('  docker ');
      expect(store.read(), ['docker', 'أحمد']);
      await store.add('احمد');
      expect(store.read(), ['احمد', 'docker']);
    });

    test('remove one, clear all, and they persist in the key/value store', () async {
      final kv = InMemoryKeyValueStore();
      final store = RecentSearchesStore(kv);
      await store.add('a1');
      await store.add('b2');
      await store.add('c3');
      expect(await store.remove('B2'), ['c3', 'a1']);
      expect(RecentSearchesStore(kv).read(), ['c3', 'a1'], reason: 'another instance reads the same box');
      await store.clear();
      expect(store.read(), isEmpty);
      expect(kv.read<String>(RecentSearchesStore.key), isNull);
    });

    test('unreadable data counts as none; blanks are skipped', () async {
      expect(RecentSearchesStore(InMemoryKeyValueStore({RecentSearchesStore.key: 'not json'})).read(), isEmpty);
      expect(RecentSearchesStore(InMemoryKeyValueStore({RecentSearchesStore.key: '{"a":1}'})).read(), isEmpty);
      expect(RecentSearchesStore(InMemoryKeyValueStore({RecentSearchesStore.key: '["x1"," ",3,"y2"]'})).read(), ['x1', 'y2']);
      final store = RecentSearchesStore(InMemoryKeyValueStore());
      expect(await store.add('   '), isEmpty);
    });
  });

  test('the reading-time chips send the contract values', () {
    expect([for (final f in ReadingTimeFilter.values) (f.minMinutes, f.maxMinutes)], [
      (null, null),
      (null, 5),
      (6, 10),
      (11, null),
    ]);
    expect(const ArticleSearchFilters().isEmpty, isTrue);
    const set = ArticleSearchFilters(fieldSlug: 'ai', language: 'en', readingTime: ReadingTimeFilter.over10);
    expect(set.isEmpty, isFalse);
    expect(set.copyWith(fieldSlug: () => null, language: () => null, readingTime: ReadingTimeFilter.any).isEmpty, isTrue);
  });

  test('a topic opens its field page; slugs are encoded', () {
    const field = SearchTopic(kind: SearchTopicKind.field, id: 'f', name: 'AI', nameAr: '', nameEn: '', fieldSlug: 'ai', fieldName: 'AI');
    const topic = SearchTopic(
      kind: SearchTopicKind.topic,
      id: 't',
      name: 'x',
      nameAr: '',
      nameEn: '',
      fieldSlug: 'ai',
      topicSlug: 'تعلم-الالة',
      fieldName: 'AI',
    );
    expect(field.location, '/f/ai');
    expect(topic.location, '/f/ai?topic=${Uri.encodeQueryComponent('تعلم-الالة')}');
    expect(Uri.parse(topic.location).queryParameters['topic'], 'تعلم-الالة');
    expect(SearchTopicKind.fromWire('field'), SearchTopicKind.field);
    expect(SearchTopicKind.fromWire(null), SearchTopicKind.topic);
  });

  test('/search links: a query and a tab', () {
    expect(SearchRoutes.of(), '/search');
    expect(AppRoutes.search, '/search');
    expect(SearchRoutes.of(query: ' docker ', type: SearchType.tags), '/search?q=docker&type=tags');
    expect(Uri.parse(SearchRoutes.of(query: 'ذكاء اصطناعي')).queryParameters['q'], 'ذكاء اصطناعي');
    expect(SearchType.fromWire('users'), SearchType.users);
    expect(SearchType.fromWire('people'), isNull);
  });

  test('guests and members open /search; a first-time guest sees Welcome first', () {
    String? redirect(String location, SessionState session, AppSettings settings) =>
        resolveRedirect(uri: Uri.parse(location), session: session, settings: settings);
    const guest = SessionState(status: SessionStatus.guest);
    const member = SessionState(status: SessionStatus.authenticated, me: sampleMe);
    expect(redirect('/search?q=docker', guest, const AppSettings(welcomeSeen: true)), isNull);
    expect(redirect('/search', member, const AppSettings()), isNull);
    expect(redirect('/search', guest, const AppSettings()), AppRoutes.welcome);
  });

  test('the search error codes are translated', () async {
    for (final locale in [AppLocales.ar, AppLocales.en]) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final code in [FailureCodes.searchQueryInvalid, FailureCodes.searchTypeInvalid, FailureCodes.searchFilterInvalid]) {
        expect(localizeErrorCode(l10n, code), isNot(l10n.errServer), reason: '$code ${locale.languageCode}');
      }
    }
  });
}
