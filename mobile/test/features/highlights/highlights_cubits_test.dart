import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/highlights/domain/entities/highlight.dart';
import 'package:readin/features/highlights/domain/repositories/highlights_repository.dart';
import 'package:readin/features/highlights/domain/usecases/highlight_usecases.dart';
import 'package:readin/features/highlights/presentation/cubit/article_highlights_cubit.dart';
import 'package:readin/features/highlights/presentation/cubit/my_highlights_cubit.dart';
import 'package:readin/shared/rdoc/highlights/rdoc_highlight_text.dart';

class _MockRepository extends Mock implements HighlightsRepository {}

Highlight _h(String id, {String block = 'p1', int start = 15, int end = 27, String text = 'ASP.NET Core'}) =>
    Highlight(id: id, blockId: block, startOffset: start, endOffset: end, text: text, createdAt: DateTime.utc(2026, 11, 5));

HighlightGroup _group(String article, String language, List<Highlight> highlights) => HighlightGroup(
      article: HighlightArticle(id: article, slug: '$article-slug', language: language, title: 'T $article'),
      highlights: highlights,
      latestAt: DateTime.utc(2026, 11, 5),
    );

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(const HighlightRange(blockId: 'x', startOffset: 0, endOffset: 3, text: 'abc')));

  setUp(() {
    repository = _MockRepository();
    when(() => repository.changes).thenAnswer((_) => const Stream<void>.empty());
  });

  group('ArticleHighlightsCubit', () {
    ArticleHighlightsCubit build() => ArticleHighlightsCubit(GetArticleHighlights(repository), EditHighlights(repository));
    const range = HighlightRange(blockId: 'p2', startOffset: 6, endOffset: 34, text: '@youssef_dev على الشرح 👨‍💻');

    void answer({List<Highlight> mine = const [], List<PopularHighlight> popular = const [], String language = 'ar-EG'}) =>
        when(() => repository.forArticle(any(), language: any(named: 'language')))
            .thenAnswer((_) async => Ok(ArticleHighlights(articleId: 'a-1', language: language, mine: mine, popular: popular)));

    blocTest<ArticleHighlightsCubit, ArticleHighlightsState>(
      'open loads the version once; marks are drawn by block, yours and popular',
      setUp: () => answer(mine: [_h('h-1')], popular: const [
        PopularHighlight(blockId: 'q1', startOffset: 24, endOffset: 37, text: 'ده احترام للي', count: 5),
      ]),
      build: build,
      act: (cubit) async {
        await cubit.open('a-1', 'ar-EG');
        await cubit.open('a-1', 'ar-EG');
      },
      verify: (cubit) {
        verify(() => repository.forArticle('a-1', language: 'ar-EG')).called(1);
        expect(cubit.state.marksFor('a-1', 'ar-EG'), {
          'p1': [const RHighlightMark(start: 15, end: 27, mine: true, id: 'h-1')],
          'q1': [const RHighlightMark(start: 24, end: 37, count: 5)],
        });
        // Another version or article draws nothing.
        expect(cubit.state.marksFor('a-1', 'en'), isEmpty);
        expect(cubit.state.marksFor('a-2', 'ar-EG'), isEmpty);
      },
    );

    blocTest<ArticleHighlightsCubit, ArticleHighlightsState>(
      "the API's version wins: asked for en, answered ar-EG, so en draws nothing",
      setUp: () => answer(mine: [_h('h-1')]),
      build: build,
      act: (cubit) => cubit.open('a-1', 'en'),
      verify: (cubit) {
        expect(cubit.state.language, 'ar-EG');
        expect(cubit.state.marksFor('a-1', 'en'), isEmpty);
      },
    );

    test('Highlight is drawn at once (not removable yet), then replaced by what the API joined', () async {
      answer(mine: [_h('h-1', block: 'p2', start: 0, end: 5, text: 'شكراً'), _h('h-other')]);
      final reply = Completer<Result<HighlightCreated>>();
      when(() => repository.create('a-1', language: 'ar-EG', range: range)).thenAnswer((_) => reply.future);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.open('a-1', 'ar-EG');

      final done = cubit.create(range);
      final pending = cubit.state.marksFor('a-1', 'ar-EG')['p2']!;
      expect(pending, contains(const RHighlightMark(start: 6, end: 34, mine: true)));

      final joined = _h('h-9', block: 'p2', start: 0, end: 34, text: 'شكراً @youssef_dev على الشرح 👨‍💻');
      reply.complete(Ok(HighlightCreated(highlight: joined, replacedIds: const ['h-1'])));
      expect(await done, isNull);
      expect(cubit.state.mine.map((h) => h.id), ['h-other', 'h-9']);
    });

    test('a refused Highlight goes away again and says why', () async {
      answer();
      when(() => repository.create(any(), language: any(named: 'language'), range: any(named: 'range')))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.highlightLimit)));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.open('a-1', 'ar-EG');
      expect((await cubit.create(range))?.code, FailureCodes.highlightLimit);
      expect(cubit.state.mine, isEmpty);
    });

    test('200 "already inside one of yours" changes nothing', () async {
      answer(mine: [_h('h-1', block: 'p2', start: 0, end: 40, text: 'x' * 40)]);
      when(() => repository.create(any(), language: any(named: 'language'), range: any(named: 'range')))
          .thenAnswer((_) async => Ok(HighlightCreated(highlight: _h('h-1', block: 'p2', start: 0, end: 40, text: 'x' * 40))));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.open('a-1', 'ar-EG');
      await cubit.create(range);
      expect(cubit.state.mine.map((h) => h.id), ['h-1']);
    });

    test('Remove is optimistic; a refusal puts it back where it was; "already gone" counts as removed', () async {
      answer(mine: [_h('h-1'), _h('h-2'), _h('h-3')]);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.open('a-1', 'ar-EG');

      when(() => repository.remove('h-2')).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      expect((await cubit.remove('h-2'))?.code, FailureCodes.networkOffline);
      expect(cubit.state.mine.map((h) => h.id), ['h-1', 'h-2', 'h-3']);

      when(() => repository.remove('h-2')).thenAnswer((_) async => const Err(Failure(FailureCodes.highlightNotFound)));
      expect(await cubit.remove('h-2'), isNull);
      expect(cubit.state.mine.map((h) => h.id), ['h-1', 'h-3']);

      when(() => repository.remove('h-3')).thenAnswer((_) async => const Ok(null));
      expect(await cubit.remove('h-3'), isNull);
      expect(cubit.state.mine.map((h) => h.id), ['h-1']);
    });

    test('a highlight still being created is never sent to DELETE', () async {
      answer();
      when(() => repository.create(any(), language: any(named: 'language'), range: any(named: 'range')))
          .thenAnswer((_) => Completer<Result<HighlightCreated>>().future);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.open('a-1', 'ar-EG');
      unawaited(cubit.create(range));
      expect(await cubit.remove(cubit.state.mine.single.id), isNull);
      verifyNever(() => repository.remove(any()));
      expect(cubit.state.mine, hasLength(1));
    });

    test('switching versions drops the old marks; a late answer for the old one is ignored', () async {
      final ar = Completer<Result<ArticleHighlights>>();
      when(() => repository.forArticle('a-1', language: 'ar-EG')).thenAnswer((_) => ar.future);
      when(() => repository.forArticle('a-1', language: 'en'))
          .thenAnswer((_) async => Ok(ArticleHighlights(articleId: 'a-1', language: 'en', mine: [_h('h-en', block: 'e1')])));
      final cubit = build();
      addTearDown(cubit.close);
      unawaited(cubit.open('a-1', 'ar-EG'));
      await cubit.open('a-1', 'en');
      ar.complete(Ok(ArticleHighlights(articleId: 'a-1', language: 'ar-EG', mine: [_h('h-ar')])));
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.language, 'en');
      expect(cubit.state.mine.map((h) => h.id), ['h-en']);
    });

    test('a failed load draws nothing but still highlights into the version on screen, and open tries again', () async {
      when(() => repository.forArticle(any(), language: any(named: 'language')))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.open('a-1', 'ar-EG');
      expect(cubit.state.status, ArticleHighlightsStatus.failure);
      expect(cubit.state.marksFor('a-1', 'ar-EG'), isEmpty);

      when(() => repository.create('a-1', language: 'ar-EG', range: range))
          .thenAnswer((_) async => Ok(HighlightCreated(highlight: _h('h-9', block: 'p2', start: 6, end: 34, text: range.text))));
      await cubit.create(range);
      expect(cubit.state.marksFor('a-1', 'ar-EG')['p2'], hasLength(1));

      answer();
      await cubit.open('a-1', 'ar-EG');
      verify(() => repository.forArticle('a-1', language: 'ar-EG')).called(2);
      expect(cubit.state.status, ArticleHighlightsStatus.ready);
    });
  });

  group('MyHighlightsCubit', () {
    MyHighlightsCubit build() => MyHighlightsCubit(GetMyHighlights(repository));

    test('loads the first page, then the next one without the groups already shown', () async {
      when(() => repository.mine(limit: 20)).thenAnswer((_) async => Ok(CursorPage(
            items: [_group('a-1', 'ar-EG', [_h('h-1')]), _group('a-2', 'en', [_h('h-2')])],
            nextCursor: 'c2',
          )));
      when(() => repository.mine(cursor: 'c2', limit: 20)).thenAnswer((_) async => Ok(CursorPage(
            // a-1 ar-EG moved to the top meanwhile; a-1 en is another version, so another group.
            items: [_group('a-1', 'ar-EG', [_h('h-1')]), _group('a-1', 'en', [_h('h-3')]), _group('a-3', 'en', [_h('h-4')])],
          )));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, MyHighlightsStatus.ready);
      expect(cubit.state.hasMore, isTrue);
      await cubit.loadMore();
      expect(cubit.state.groups.map((g) => g.key), ['a-1|ar-EG', 'a-2|en', 'a-1|en', 'a-3|en']);
      expect(cubit.state.hasMore, isFalse);
      await cubit.loadMore();
      verify(() => repository.mine(cursor: 'c2', limit: 20)).called(1);
    });

    test('a failed page keeps the list and can be tried again; a failed first load shows the error', () async {
      when(() => repository.mine(limit: 20))
          .thenAnswer((_) async => Ok(CursorPage(items: [_group('a-1', 'ar-EG', [_h('h-1')])], nextCursor: 'c2')));
      when(() => repository.mine(cursor: 'c2', limit: 20)).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.loadMore();
      expect(cubit.state.groups, hasLength(1));
      expect(cubit.state.loadMoreFailure?.code, FailureCodes.networkOffline);
      expect(cubit.state.nextCursor, 'c2');

      when(() => repository.mine(limit: 20)).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      await cubit.refresh();
      expect(cubit.state.groups, hasLength(1), reason: 'pull to refresh keeps what is shown');
      await cubit.load();
      expect(cubit.state.status, MyHighlightsStatus.failure);
    });

    test('making or removing a highlight elsewhere loads the list again, keeping it on screen meanwhile', () async {
      final changes = StreamController<void>.broadcast();
      addTearDown(changes.close);
      when(() => repository.changes).thenAnswer((_) => changes.stream);
      when(() => repository.mine(limit: 20)).thenAnswer((_) async => Ok(CursorPage(items: [_group('a-1', 'ar-EG', [_h('h-1')])])));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.groups.single.highlights.map((h) => h.id), ['h-1']);

      final answer = Completer<Result<CursorPage<HighlightGroup>>>();
      when(() => repository.mine(limit: 20)).thenAnswer((_) => answer.future);
      changes.add(null);
      await pumpEventQueue();
      expect(cubit.state.status, MyHighlightsStatus.ready, reason: 'no skeleton while it reloads');
      expect(cubit.state.groups, hasLength(1));
      answer.complete(Ok(CursorPage(items: [
        _group('a-2', 'en', [_h('h-2')]),
        _group('a-1', 'ar-EG', [_h('h-1')]),
      ])));
      await pumpEventQueue();
      expect(cubit.state.groups.map((g) => g.key), ['a-2|en', 'a-1|ar-EG']);
      verify(() => repository.mine(limit: 20)).called(2);
    });

    test('an older answer arriving after a newer one is dropped', () async {
      final first = Completer<Result<CursorPage<HighlightGroup>>>();
      when(() => repository.mine(limit: 20)).thenAnswer((_) => first.future);
      final cubit = build();
      addTearDown(cubit.close);
      final loading = cubit.load();
      when(() => repository.mine(limit: 20)).thenAnswer((_) async => Ok(CursorPage(items: [_group('a-2', 'en', [_h('h-2')])])));
      await cubit.refresh();
      first.complete(Ok(CursorPage(items: [_group('a-1', 'ar-EG', [_h('h-1')])])));
      await loading;
      expect(cubit.state.groups.map((g) => g.key), ['a-2|en']);
    });
  });
}
