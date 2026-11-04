import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/editor/data/datasources/editor_backup_store.dart';
import 'package:readin/features/editor/domain/entities/editor_backup.dart';
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/editor/domain/usecases/editor_usecases.dart';
import 'package:readin/features/editor/presentation/cubit/article_editor_cubit.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/media/domain/usecases/media_usecases.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/editor_fixtures.dart';
import '../../helpers/media_fixtures.dart';

void main() {
  late FakeArticleEditorRepository repo;
  late InMemoryEditorBackupStore backups;
  late FakeMediaRepository media;
  var now = DateTime.utc(2026, 11, 3, 12);

  setUp(() {
    repo = FakeArticleEditorRepository();
    repo.onSave = (id, v, doc) => Ok(sampleEdit(id: id, version: v + 1, document: doc));
    repo.onCreate = (doc) => Ok(sampleEdit(id: 'new-1', version: 1, document: doc));
    backups = InMemoryEditorBackupStore();
    media = FakeMediaRepository();
    now = DateTime.utc(2026, 11, 3, 12);
  });

  ArticleEditorCubit build() {
    final taxonomy = FakeTaxonomyRepository();
    return ArticleEditorCubit(
      CreateArticle(repo),
      GetArticleForEdit(repo),
      SaveDraft(repo),
      DiscardChanges(repo),
      PublishArticle(repo),
      RestoreRevision(repo),
      DeleteArticle(repo),
      GetFields(taxonomy),
      GetTopics(taxonomy),
      UploadImage(media),
      backups,
      clock: () => now,
    );
  }

  const ar = ArticleLanguages.ar;

  group('autosave', () {
    test('a new article is created by the first autosave, then saved with its version', () {
      fakeAsync((async) {
        final cubit = build()..open(language: 'ar-EG');
        async.flushMicrotasks();
        expect(cubit.state.isReady, isTrue);
        expect(cubit.state.isNew, isTrue);
        expect(cubit.state.document.sourceLanguage, ar);

        cubit.setTitle(ar, 'عنوان تجريبي عن DI');
        expect(cubit.state.dirty, isTrue);
        async.elapse(const Duration(seconds: 1));
        expect(backups.backups[EditorBackup.newArticleKey]?.document.source.title, 'عنوان تجريبي عن DI');
        expect(repo.calls, isEmpty, reason: 'nothing is sent before the 10 s tick');

        async.elapse(const Duration(seconds: 9));
        expect(repo.calls, ['create']);
        expect(cubit.state.articleId, 'new-1');
        expect(cubit.state.version, 1);
        expect(cubit.state.dirty, isFalse);
        expect(cubit.state.saveStatus, SaveStatus.saved);
        expect(backups.backups, isEmpty, reason: 'the API has everything');

        cubit.setTitle(ar, 'عنوان تاني عن DI');
        async.elapse(const Duration(seconds: 10));
        expect(repo.calls.last, 'save new-1 v1');
        expect(repo.saved.last.document.source.title, 'عنوان تاني عن DI');
        expect(cubit.state.version, 2);
        cubit.close();
      });
    });

    test('nothing is saved while there is nothing new', () {
      fakeAsync((async) {
        repo.onGet = (id) => Ok(sampleEdit(id: id));
        final cubit = build()..open(articleId: 'art-1', language: 'ar-EG');
        async.elapse(const Duration(seconds: 30));
        expect(repo.calls, ['get art-1']);
        cubit.close();
      });
    });

    test('edits made while a save runs keep the article dirty and go in the next save', () {
      fakeAsync((async) {
        repo.onGet = (id) => Ok(sampleEdit(id: id));
        final pending = Completer<Result<ArticleEdit>>();
        repo.onSave = (id, v, doc) => pending.future;
        final cubit = build()..open(articleId: 'art-1', language: 'ar-EG');
        async.flushMicrotasks();

        cubit.setTitle(ar, 'أول تعديل في العنوان');
        async.elapse(const Duration(seconds: 10));
        expect(cubit.state.saveStatus, SaveStatus.saving);
        cubit.setTitle(ar, 'تاني تعديل في العنوان');
        pending.complete(Ok(sampleEdit(version: 4, document: repo.saved.last.document)));
        async.flushMicrotasks();
        expect(cubit.state.dirty, isTrue);
        expect(cubit.state.version, 4);
        expect(backups.backups['art-1'], isNotNull, reason: 'the newer edit is kept on the device');

        repo.onSave = (id, v, doc) => Ok(sampleEdit(version: v + 1, document: doc));
        async.elapse(const Duration(seconds: 10));
        expect(repo.calls.last, 'save art-1 v4');
        expect(repo.saved.last.document.source.title, 'تاني تعديل في العنوان');
        expect(cubit.state.dirty, isFalse);
        cubit.close();
      });
    });

    test('offline: the status says saved on the device, the backup stays and the next tick retries', () {
      fakeAsync((async) {
        repo.onGet = (id) => Ok(sampleEdit(id: id));
        repo.onSave = (id, v, doc) => const Err(Failure(FailureCodes.networkOffline));
        final cubit = build()..open(articleId: 'art-1', language: 'ar-EG');
        async.flushMicrotasks();
        cubit.setSubtitle(ar, 'عنوان فرعي جديد');
        async.elapse(const Duration(seconds: 10));
        expect(cubit.state.saveStatus, SaveStatus.offline);
        expect(cubit.state.dirty, isTrue);
        expect(backups.backups['art-1']?.document.source.subtitle, 'عنوان فرعي جديد');
        expect(backups.backups['art-1']?.baseVersion, 3);

        repo.onSave = (id, v, doc) => Ok(sampleEdit(version: v + 1, document: doc));
        async.elapse(const Duration(seconds: 10));
        expect(cubit.state.saveStatus, SaveStatus.saved);
        expect(backups.backups, isEmpty);
        cubit.close();
      });
    });

    test('flush saves at once (app pause, back)', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      cubit.setTitle(ar, 'عنوان بعد التعديل');
      await cubit.flush();
      expect(repo.calls.last, 'save art-1 v3');
      expect(cubit.state.dirty, isFalse);
      await cubit.close();
    });
  });

  group('local backup', () {
    test('a backup newer than the API copy is offered; restoring brings it back unsaved', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id, savedAt: DateTime.utc(2026, 11, 2, 10)));
      final local = mixedDocument().withTranslation(mixedDocument().source.copyWith(title: 'نسخة الجهاز من العنوان'));
      await backups.write(EditorBackup(key: 'art-1', articleId: 'art-1', baseVersion: 3, document: local, editedAt: DateTime.utc(2026, 11, 2, 11)));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      expect(cubit.state.backupOffer?.document, local);
      final revision = cubit.state.documentRevision;

      cubit.restoreBackup();
      expect(cubit.state.document, local);
      expect(cubit.state.dirty, isTrue);
      expect(cubit.state.backupOffer, isNull);
      expect(cubit.state.documentRevision, revision + 1);
      await cubit.flush();
      expect(repo.saved.single.document.source.title, 'نسخة الجهاز من العنوان');
      await cubit.close();
    });

    test('declining the offer deletes the backup', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id));
      await backups.write(EditorBackup(
        key: 'art-1',
        articleId: 'art-1',
        document: mixedDocument(complete: false),
        editedAt: DateTime.utc(2026, 11, 2, 11),
      ));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      await cubit.dismissBackup();
      expect(backups.backups, isEmpty);
      expect(cubit.state.document, mixedDocument());
      await cubit.close();
    });

    test('a backup older than the API copy is dropped without asking', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id, savedAt: DateTime.utc(2026, 11, 2, 12)));
      await backups.write(EditorBackup(key: 'art-1', articleId: 'art-1', document: mixedDocument(complete: false), editedAt: DateTime.utc(2026, 11, 2, 11)));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      expect(cubit.state.backupOffer, isNull);
      expect(backups.backups, isEmpty);
      await cubit.close();
    });

    test('a new article offers the backup of the last unsaved new one', () async {
      await backups.write(EditorBackup(key: 'new', document: mixedDocument(), editedAt: DateTime.utc(2026, 11, 2, 11)));
      final cubit = build();
      await cubit.open(language: 'en');
      expect(cubit.state.backupOffer?.key, 'new');
      cubit.restoreBackup();
      expect(cubit.state.document.sourceLanguage, ar);
      expect(cubit.state.activeLanguage, ar);
      await cubit.close();
    });

    test('offline, the editor opens from the device copy', () async {
      repo.onGet = (id) => const Err(Failure(FailureCodes.networkOffline));
      await backups.write(EditorBackup(
        key: 'art-1',
        articleId: 'art-1',
        baseVersion: 7,
        status: ArticleLifecycle.published,
        slug: 'scoped',
        document: mixedDocument(),
        editedAt: DateTime.utc(2026, 11, 2, 11),
      ));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      expect(cubit.state.isReady, isTrue);
      expect(cubit.state.version, 7);
      expect(cubit.state.isPublished, isTrue);
      expect(cubit.state.saveStatus, SaveStatus.offline);
      expect(cubit.state.dirty, isTrue);
      await cubit.close();
    });

    test('without a device copy, a failed open shows the error', () async {
      repo.onGet = (id) => const Err(Failure(FailureCodes.articleNotFound));
      final cubit = build();
      await cubit.open(articleId: 'art-9', language: 'ar-EG');
      expect(cubit.state.loadStatus, EditorLoadStatus.failure);
      expect(cubit.state.loadFailure?.code, FailureCodes.articleNotFound);
      await cubit.close();
    });
  });

  group('conflicts', () {
    test('409 stops autosave until the writer chooses; "load the saved version" takes the API copy', () {
      fakeAsync((async) {
        final server = sampleEdit(version: 9, document: mixedDocument(withTranslation: true));
        var gets = 0;
        repo.onGet = (id) => Ok(gets++ == 0 ? sampleEdit(id: id) : server);
        repo.onSave = (id, v, doc) => const Err(Failure(FailureCodes.articleDraftConflict, statusCode: 409));
        final cubit = build()..open(articleId: 'art-1', language: 'ar-EG');
        async.flushMicrotasks();
        cubit.setTitle(ar, 'تعديل من الجهاز ده');
        async.elapse(const Duration(seconds: 10));
        expect(cubit.state.conflicted, isTrue);
        expect(cubit.state.conflictCopy, server);
        expect(backups.backups['art-1'], isNotNull);

        final saves = repo.saved.length;
        async.elapse(const Duration(seconds: 30));
        expect(repo.saved.length, saves, reason: 'autosave waits for the choice');

        cubit.reloadServerCopy();
        async.flushMicrotasks();
        expect(cubit.state.conflicted, isFalse);
        expect(cubit.state.document, server.document);
        expect(cubit.state.version, 9);
        expect(cubit.state.dirty, isFalse);
        expect(backups.backups, isEmpty);
        cubit.close();
      });
    });

    test('"keep mine" saves this device\'s document over the API copy, based on its version', () async {
      var gets = 0;
      repo.onGet = (id) => Ok(gets++ == 0 ? sampleEdit(id: id) : sampleEdit(id: id, version: 9));
      var conflict = true;
      repo.onSave = (id, v, doc) =>
          conflict ? const Err(Failure(FailureCodes.articleDraftConflict)) : Ok(sampleEdit(version: v + 1, document: doc));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      cubit.setTitle(ar, 'نسختي أنا من العنوان');
      await cubit.save();
      expect(cubit.state.conflicted, isTrue);

      conflict = false;
      await cubit.keepMine();
      expect(repo.calls.last, 'save art-1 v9');
      expect(repo.saved.last.document.source.title, 'نسختي أنا من العنوان');
      expect(cubit.state.conflicted, isFalse);
      expect(cubit.state.version, 10);
      await cubit.close();
    });
  });

  group('actions', () {
    test('publish saves pending edits first, then publishes with the new version', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id));
      repo.onSave = (id, v, doc) => Ok(sampleEdit(version: v + 1, document: doc, checks: const DraftChecks()));
      repo.onPublish = (id, v) => Ok(PublishedArticle(id: id, slug: 'scoped-vs-transient', publishedAt: DateTime.utc(2026, 11, 3), revision: 1, firstPublish: true));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      await Future<void>.delayed(Duration.zero); // fields
      cubit.setTitle(ar, 'إزاي تختار بين Scoped و Transient؟');
      expect(cubit.state.canPublish, isTrue);
      await cubit.publish();
      expect(repo.calls.sublist(1), ['save art-1 v3', 'publish art-1 v4']);
      expect(cubit.state.event, EditorEvent.published);
      expect(cubit.state.publishedSlug, 'scoped-vs-transient');
      expect(cubit.state.isPublished, isTrue);
      await cubit.close();
    });

    test('a refused publish shows every problem the API listed', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id, checks: const DraftChecks()));
      repo.onPublish = (id, v) => const Err(DraftProblemsFailure(
            FailureCodes.articleSourcesRequired,
            problems: [DraftProblem(FailureCodes.articleSourcesRequired), DraftProblem(FailureCodes.articleImageAltRequired, language: 'ar-EG', blockId: 'img')],
          ));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      await cubit.publish();
      expect(cubit.state.problems.map((p) => p.code), [FailureCodes.articleSourcesRequired, FailureCodes.articleImageAltRequired]);
      expect(cubit.state.canPublish, isFalse);
      expect(cubit.state.notice, isA<DraftProblemsFailure>());
      await cubit.close();
    });

    test('Update stays off for a published article with nothing new', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id, status: ArticleLifecycle.published, checks: const DraftChecks()));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      expect(cubit.state.canPublish, isFalse);
      cubit.setTitle(ar, 'عنوان محدّث للمقال');
      expect(cubit.state.canPublish, isTrue);
      await cubit.close();
    });

    test('discard changes reloads the live version', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id, status: ArticleLifecycle.published, hasUnpublishedChanges: true));
      repo.onDiscard = (id) => Ok(sampleEdit(id: id, status: ArticleLifecycle.published, version: 5, document: mixedDocument(withTranslation: true)));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      await cubit.discardChanges();
      expect(cubit.state.document.hasTranslation, isTrue);
      expect(cubit.state.version, 5);
      expect(cubit.state.hasUnpublishedChanges, isFalse);
      expect(cubit.state.event, EditorEvent.discarded);
      await cubit.close();
    });

    test('restoring a revision replaces the working copy', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id, status: ArticleLifecycle.published));
      repo.onRestore = (id, n, v) => Ok(sampleEdit(id: id, status: ArticleLifecycle.published, version: v + 1, hasUnpublishedChanges: true, document: mixedDocument(complete: false)));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      cubit.setTitle(ar, 'تعديل هيتلغي');
      expect(await cubit.restoreRevision(2), isTrue);
      expect(repo.calls.last, 'restore art-1 #2 v3');
      expect(cubit.state.document, mixedDocument(complete: false));
      expect(cubit.state.dirty, isFalse);
      expect(cubit.state.event, EditorEvent.restored);
      await cubit.close();
    });

    test('delete removes the article and its device copy', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id));
      repo.onDelete = (id) => const Ok(null);
      await backups.write(EditorBackup(key: 'art-1', articleId: 'art-1', document: mixedDocument(), editedAt: DateTime.utc(2026, 11, 1)));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      await cubit.delete();
      expect(repo.calls.last, 'delete art-1');
      expect(backups.backups, isEmpty);
      expect(cubit.state.event, EditorEvent.deleted);
      await cubit.close();
    });

    test('deleting a never-saved article only drops the device copy', () async {
      await backups.write(EditorBackup(key: 'new', document: mixedDocument(), editedAt: DateTime.utc(2026, 11, 1)));
      final cubit = build();
      await cubit.open(language: 'ar-EG');
      await cubit.delete();
      expect(repo.calls, isEmpty);
      expect(backups.backups, isEmpty);
      expect(cubit.state.event, EditorEvent.deleted);
      await cubit.close();
    });
  });

  group('editing', () {
    test('languages: add the other version, switch, remove it', () async {
      final cubit = build();
      await cubit.open(language: 'ar-EG');
      cubit.addTranslation();
      expect(cubit.state.document.languages, ['ar-EG', 'en']);
      expect(cubit.state.activeLanguage, 'en');
      cubit.setContent('en', const RDocDocument(version: 1, language: 'ar-EG', blocks: [RParagraph('p', dir: 'auto', content: [RText('Hi')])]));
      expect(cubit.state.document.translation('en')!.content.language, 'en', reason: 'content.language follows the version');
      cubit.removeTranslation('en');
      expect(cubit.state.document.languages, ['ar-EG']);
      expect(cubit.state.activeLanguage, 'ar-EG');
      cubit.setSourceLanguage('en');
      expect(cubit.state.document.sourceLanguage, 'en');
      expect(cubit.state.document.source.content.language, 'en');
      await cubit.close();
    });

    test('tags: trimmed, no duplicates, at most 5 of at most 40 characters', () async {
      final cubit = build();
      await cubit.open(language: 'ar-EG');
      expect(cubit.addTag('  dotnet '), isTrue);
      expect(cubit.addTag('DotNet'), isFalse);
      expect(cubit.addTag('x' * 41), isFalse);
      for (final t in ['a', 'b', 'c', 'd']) {
        cubit.addTag(t);
      }
      expect(cubit.addTag('f'), isFalse);
      expect(cubit.state.document.tags, ['dotnet', 'a', 'b', 'c', 'd']);
      cubit.removeTag('a');
      expect(cubit.state.document.tags, ['dotnet', 'b', 'c', 'd']);
      await cubit.close();
    });

    test('sources: only complete rows go into the document', () async {
      final cubit = build();
      await cubit.open(language: 'ar-EG');
      cubit.addSource();
      final key = cubit.state.sources.single.key;
      cubit.updateSource(key, title: 'Docs');
      expect(cubit.state.document.sources, isEmpty);
      cubit.updateSource(key, url: 'https://learn.microsoft.com');
      expect(cubit.state.document.sources.single.url, 'https://learn.microsoft.com');
      cubit.removeSource(key);
      expect(cubit.state.document.sources, isEmpty);
      await cubit.close();
    });

    test('the cover uploads with purpose cover and uses its largest variant; uploads block publishing', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id, checks: const DraftChecks()));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      cubit.setTitle(ar, 'عنوان كفاية للنشر');
      final upload = cubit.uploadCover(sampleImageFile);
      expect(cubit.state.uploading, isTrue);
      expect(cubit.state.canPublish, isFalse);
      await upload;
      expect(media.purposes, ['cover']);
      expect(cubit.state.document.coverUrl, endsWith('/1600.webp'));
      expect(cubit.state.uploading, isFalse);
      await cubit.close();
    });

    test('attachments come from the attachment bar; busy ones block publishing', () async {
      repo.onGet = (id) => Ok(sampleEdit(id: id, checks: const DraftChecks()));
      final cubit = build();
      await cubit.open(articleId: 'art-1', language: 'ar-EG');
      const items = [AttachmentItem(mediaAssetId: 'a1', order: 0, altText: 'Program.cs')];
      cubit.setAttachments(items, busy: true, assets: {'a1': imageAsset('a1')});
      expect(cubit.state.document.attachments, items);
      expect(cubit.state.canPublish, isFalse);
      cubit.setAttachments(items, busy: false, assets: {'a1': imageAsset('a1')});
      expect(cubit.state.canPublish, isTrue);
      await cubit.close();
    });
  });
}
