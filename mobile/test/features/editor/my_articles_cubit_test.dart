import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/features/editor/data/datasources/editor_backup_store.dart';
import 'package:readin/features/editor/domain/entities/editor_backup.dart';
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/editor/domain/usecases/editor_usecases.dart';
import 'package:readin/features/editor/presentation/cubit/my_articles_cubit.dart';

import '../../helpers/editor_fixtures.dart';

void main() {
  late FakeArticleEditorRepository repo;
  late InMemoryEditorBackupStore backups;

  setUp(() {
    repo = FakeArticleEditorRepository();
    repo.onList = (status, cursor) => Ok(CursorPage(items: sampleMyArticles(status), nextCursor: cursor == null && status == ArticleLifecycle.draft ? 'c2' : null));
    backups = InMemoryEditorBackupStore();
  });

  MyArticlesCubit build() => MyArticlesCubit(GetMyArticles(repo), DeleteArticle(repo), backups);

  blocTest<MyArticlesCubit, MyArticlesState>(
    'each tab loads the first time it shows, and only then',
    build: build,
    act: (cubit) async {
      await cubit.ensureLoaded(ArticleLifecycle.draft);
      await cubit.ensureLoaded(ArticleLifecycle.draft);
      await cubit.ensureLoaded(ArticleLifecycle.published);
    },
    verify: (cubit) {
      expect(repo.calls, ['list draft', 'list published']);
      expect(cubit.state.drafts.items, hasLength(3));
      expect(cubit.state.drafts.hasMore, isTrue);
      expect(cubit.state.published.items.first.hasUnpublishedChanges, isTrue);
    },
  );

  blocTest<MyArticlesCubit, MyArticlesState>(
    'infinite scroll appends the next page without duplicates and stops at the end',
    build: build,
    act: (cubit) async {
      await cubit.load(ArticleLifecycle.draft);
      repo.onList = (status, cursor) => Ok(CursorPage(items: [
            sampleMyArticles(status).first, // already shown
            MyArticle(id: 'd4', status: ArticleLifecycle.draft, language: 'en', title: 'Fourth', savedAt: DateTime.utc(2026, 10, 1)),
          ]));
      await cubit.loadMore(ArticleLifecycle.draft);
      await cubit.loadMore(ArticleLifecycle.draft);
    },
    verify: (cubit) {
      expect(repo.calls, ['list draft', 'list draft c2']);
      expect([for (final a in cubit.state.drafts.items) a.id], ['d1', 'd2', 'd3', 'd4']);
      expect(cubit.state.drafts.hasMore, isFalse);
    },
  );

  blocTest<MyArticlesCubit, MyArticlesState>(
    'a failed first load shows the error; a failed refresh keeps the rows',
    build: build,
    act: (cubit) async {
      repo.onList = (status, cursor) => const Err(Failure(FailureCodes.networkOffline));
      await cubit.load(ArticleLifecycle.published);
      repo.onList = (status, cursor) => Ok(CursorPage(items: sampleMyArticles(status)));
      await cubit.load(ArticleLifecycle.published);
      repo.onList = (status, cursor) => const Err(Failure(FailureCodes.networkOffline));
      await cubit.load(ArticleLifecycle.published);
    },
    verify: (cubit) {
      expect(cubit.state.published.status, MyArticlesStatus.ready);
      expect(cubit.state.published.items, hasLength(2));
      expect(cubit.state.published.failure?.code, FailureCodes.networkOffline);
    },
  );

  test('delete removes the row at once and the device copy after the API agrees', () async {
    repo.onDelete = (id) => const Ok(null);
    await backups.write(EditorBackup(key: 'd1', articleId: 'd1', document: mixedDocument(), editedAt: DateTime.utc(2026, 11, 1)));
    final cubit = build();
    await cubit.load(ArticleLifecycle.draft);
    final future = cubit.delete(cubit.state.drafts.items.first);
    expect([for (final a in cubit.state.drafts.items) a.id], ['d2', 'd3']);
    expect(cubit.state.deleting, {'d1'});
    expect(await future, isTrue);
    expect(cubit.state.deleting, isEmpty);
    expect(backups.backups, isEmpty);
    await cubit.close();
  });

  test('a refused delete puts the row back where it was and explains', () async {
    repo.onDelete = (id) => const Err(Failure(FailureCodes.articleNotFound));
    final cubit = build();
    await cubit.load(ArticleLifecycle.draft);
    final second = cubit.state.drafts.items[1];
    expect(await cubit.delete(second), isFalse);
    expect([for (final a in cubit.state.drafts.items) a.id], ['d1', 'd2', 'd3']);
    expect(cubit.state.notice?.code, FailureCodes.articleNotFound);
    expect(cubit.state.noticeSeq, 1);
    await cubit.close();
  });
}
