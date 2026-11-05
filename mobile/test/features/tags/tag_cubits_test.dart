import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/tags/domain/usecases/tag_usecases.dart';
import 'package:readin/features/tags/presentation/cubit/tag_cubits.dart';

import '../../helpers/tag_fixtures.dart';

void main() {
  group('TagCubit', () {
    test('loads the header; an unknown or hidden tag is "not found"', () async {
      final repo = FakeTagsRepository(tags: const [csharpTag]);
      final cubit = TagCubit(GetTag(repo));
      addTearDown(cubit.close);

      await cubit.load('csharp');
      expect(cubit.state.status, TagStatus.ready);
      expect(cubit.state.tag, csharpTag);

      await cubit.load(missingTagSlug);
      expect(cubit.state.status, TagStatus.failure);
      expect(cubit.state.notFound, isTrue);
    });

    test('another failure is retryable, not "not found"; refresh keeps the header when it fails', () async {
      final repo = FakeTagsRepository(tags: const [csharpTag])..failure = const Failure(FailureCodes.networkOffline);
      final cubit = TagCubit(GetTag(repo));
      addTearDown(cubit.close);

      await cubit.load('csharp');
      expect(cubit.state.status, TagStatus.failure);
      expect(cubit.state.notFound, isFalse);

      repo.failure = null;
      await cubit.refresh();
      expect(cubit.state.tag, csharpTag, reason: 'refresh without a header loads it');

      repo.failure = const Failure(FailureCodes.networkOffline);
      await cubit.refresh();
      expect(cubit.state.status, TagStatus.ready);
      expect(cubit.state.tag, csharpTag);
    });

    test('an older answer is dropped', () async {
      final gate = Completer<void>();
      final repo = FakeTagsRepository(tags: const [csharpTag, dotnetTag])..gate = gate;
      final cubit = TagCubit(GetTag(repo));
      addTearDown(cubit.close);
      final first = cubit.load('csharp');
      repo.gate = null;
      await cubit.load('dotnet');
      expect(cubit.state.tag, dotnetTag);
      gate.complete();
      await first;
      expect(cubit.state.tag, dotnetTag);
    });
  });

  group('TagArticlesCubit', () {
    test('pages through the articles with the cursor, newest first as the API sends them', () async {
      final pages = [tagPageCards(csharpTag, first: 1), tagPageCards(csharpTag, first: 3), tagPageCards(csharpTag, first: 5, count: 1)];
      final repo = FakeTagsRepository(tags: const [csharpTag], pages: {'csharp': pages});
      final cubit = TagArticlesCubit(GetTagArticles(repo), 'csharp');
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.items.map((a) => a.id), ['art-1', 'art-2']);
      expect(cubit.state.hasMore, isTrue);
      await cubit.loadMore();
      await cubit.loadMore();
      expect(cubit.state.items.map((a) => a.id), ['art-1', 'art-2', 'art-3', 'art-4', 'art-5']);
      expect(cubit.state.hasMore, isFalse);
      await cubit.loadMore();
      expect(repo.calls, ['articles csharp', 'articles csharp c1', 'articles csharp c2']);
    });

    test('an empty tag is ready with no items; a missing one fails with tag.not_found', () async {
      final repo = FakeTagsRepository(pages: {'zig': const [[]]});
      final empty = TagArticlesCubit(GetTagArticles(repo), 'zig');
      final missing = TagArticlesCubit(GetTagArticles(repo), missingTagSlug);
      addTearDown(empty.close);
      addTearDown(missing.close);

      await empty.load();
      expect(empty.state.isEmpty, isTrue);
      await missing.load();
      expect(missing.state.status, FeedStatus.failure);
      expect(isTagNotFound(missing.state.failure), isTrue);
    });
  });
}
