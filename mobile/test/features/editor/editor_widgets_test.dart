import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';
import 'package:readin/features/editor/data/datasources/editor_backup_store.dart';
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/editor/domain/usecases/editor_usecases.dart';
import 'package:readin/features/editor/presentation/cubit/article_editor_cubit.dart';
import 'package:readin/features/editor/presentation/cubit/tag_suggestions_cubit.dart';
import 'package:readin/features/editor/presentation/pages/article_editor_page.dart';
import 'package:readin/features/editor/presentation/pages/my_articles_page.dart';
import 'package:readin/features/editor/presentation/widgets/article_settings_sheet.dart';
import 'package:readin/features/editor/presentation/widgets/editor_widgets.dart';
import 'package:readin/features/media/domain/usecases/media_usecases.dart';
import 'package:readin/features/media/presentation/cubit/attachments_cubit.dart';
import 'package:readin/features/taxonomy/domain/usecases/taxonomy_usecases.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/comment_fixtures.dart';
import '../../helpers/editor_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

const _en = Variant(AppLocales.en, Brightness.light);

void main() {
  late MockMentionSuggestionsCubit mentions;

  setUp(() {
    mentions = MockMentionSuggestionsCubit();
    whenListen(mentions, const Stream<List<Author>>.empty(), initialState: const <Author>[]);
    when(() => mentions.search(any())).thenReturn(null);
    when(mentions.clear).thenReturn(null);
  });

  group('My articles', () {
    testWidgets('a row shows "Untitled", its dates and the unpublished-changes chip', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 400));
      final draft = sampleMyArticles(ArticleLifecycle.draft)[1];
      final published = sampleMyArticles(ArticleLifecycle.published).first;
      var edited = 0;
      await tester.pumpWidget(testApp(
        Scaffold(
          body: Column(children: [
            MyArticleTile(article: draft, onEdit: () => edited++, onDelete: () {}),
            MyArticleTile(article: published, onEdit: () {}, onDelete: () {}),
          ]),
        ),
        variant: _en,
      ));
      expect(find.text('Untitled'), findsOneWidget);
      expect(find.text('Unpublished changes'), findsOneWidget);
      expect(find.textContaining('Published Oct 20'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('my-article-edit-d2')));
      expect(edited, 1);
    });
  });

  group('checks', () {
    testWidgets('tapping a problem jumps to it', (tester) async {
      final tapped = <DraftProblem>[];
      final state = ArticleEditorState(
        document: mixedDocument(withTranslation: true),
        activeLanguage: 'ar-EG',
        loadStatus: EditorLoadStatus.ready,
        dirty: true,
        checks: const DraftChecks(readingTime: [ReadingTime(language: 'ar-EG', minutes: 6)]),
      ).copyWith(document: ArticleDraftDocument.empty('ar-EG'));
      await tester.pumpWidget(testApp(Scaffold(body: ChecksList(state: state, onProblem: tapped.add)), variant: _en));
      expect(find.text('Choose a field.'), findsOneWidget);
      await tester.tap(find.text('The title needs 5 to 150 characters.'));
      expect(tapped.single.code, DraftProblemCodes.titleLength);
    });
  });

  group('settings sheet', () {
    testWidgets('tags are added from the field and removed from their chips', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 2200));
      final repo = FakeArticleEditorRepository();
      final taxonomy = FakeTaxonomyRepository();
      final cubit = ArticleEditorCubit(
        CreateArticle(repo),
        GetArticleForEdit(repo),
        SaveDraft(repo),
        DiscardChanges(repo),
        PublishArticle(repo),
        RestoreRevision(repo),
        DeleteArticle(repo),
        GetFields(taxonomy),
        GetTopics(taxonomy),
        UploadImage(FakeMediaRepository()),
        InMemoryEditorBackupStore(),
      );
      await cubit.open(language: 'ar-EG');
      final tags = MockTagSuggestionsCubit();
      whenListen(tags, const Stream<List<ArticleTag>>.empty(), initialState: const [ArticleTag(slug: 'efcore', name: 'efcore', articleCount: 4)]);
      when(() => tags.search(any())).thenReturn(null);
      final attachments = MockAttachmentsCubit();
      whenListen(attachments, const Stream<AttachmentsState>.empty(), initialState: const AttachmentsState());
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<ArticleEditorCubit>.value(value: cubit),
            BlocProvider<TagSuggestionsCubit>.value(value: tags),
            BlocProvider<AttachmentsCubit>.value(value: attachments),
          ],
          child: const Scaffold(body: ArticleSettingsPanel()),
        ),
        variant: _en,
      ));
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('settings-tag-input')), 'dotnet');
      await tester.tap(find.byKey(const ValueKey('settings-tag-add')));
      await tester.pump();
      expect(cubit.state.document.tags, ['dotnet']);
      await tester.tap(find.byTooltip('Remove dotnet'));
      await tester.pump();
      expect(cubit.state.document.tags, isEmpty);

      await tester.tap(find.byKey(const ValueKey('settings-add-translation')));
      await tester.pump();
      expect(cubit.state.document.languages, ['ar-EG', 'en']);
      await cubit.close();
    });
  });

  group('the editor page', () {
    late FakeArticleEditorRepository repo;
    late ArticleEditorCubit cubit;

    Future<void> pumpPage(WidgetTester tester) async {
      usePhoneSurface(tester, size: const Size(390, 1400));
      final attachments = MockAttachmentsCubit();
      whenListen(attachments, const Stream<AttachmentsState>.empty(), initialState: const AttachmentsState());
      final tags = MockTagSuggestionsCubit();
      whenListen(tags, const Stream<List<ArticleTag>>.empty(), initialState: const <ArticleTag>[]);
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<ArticleEditorCubit>.value(value: cubit),
            BlocProvider<AttachmentsCubit>.value(value: attachments),
            BlocProvider<MentionSuggestionsCubit>.value(value: mentions),
            BlocProvider<TagSuggestionsCubit>.value(value: tags),
          ],
          child: const ArticleEditorView(author: editorial),
        ),
        variant: _en,
      ));
      await tester.pump();
    }

    setUp(() {
      repo = FakeArticleEditorRepository();
      repo.onGet = (id) => Ok(sampleEdit(id: id));
      final taxonomy = FakeTaxonomyRepository();
      cubit = ArticleEditorCubit(
        CreateArticle(repo),
        GetArticleForEdit(repo),
        SaveDraft(repo),
        DiscardChanges(repo),
        PublishArticle(repo),
        RestoreRevision(repo),
        DeleteArticle(repo),
        GetFields(taxonomy),
        GetTopics(taxonomy),
        UploadImage(FakeMediaRepository()),
        InMemoryEditorBackupStore(),
      );
    });

    tearDown(() => cubit.close());

    testWidgets('the title, the content and the language versions edit the document', (tester) async {
      await tester.runAsync(() => cubit.open(articleId: 'art-1', language: 'ar-EG'));
      await pumpPage(tester);
      expect(find.text('Update'), findsNothing);
      expect(find.text('Publish'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('editor-title-ar-EG')), 'عنوان جديد للمقال');
      await tester.pump();
      expect(cubit.state.document.source.title, 'عنوان جديد للمقال');
      expect(find.text('Not saved yet'), findsOneWidget);

      // Typing in the AppFlowy surface reaches the document.
      final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;
      unawaited(editor.updateSelectionWithReason(Selection.collapsed(Position(path: [0])), reason: SelectionUpdateReason.uiEvent));
      await tester.pump();
      await editor.insertTextAtPosition('مقدمة: ');
      await tester.pump();
      final first = cubit.state.document.source.content.blocks.first as RParagraph;
      expect(first.id, 'p1');
      expect(first.content.first, const RText('مقدمة: لو انت شغال بـ '));
      unawaited(editor.updateSelectionWithReason(null));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('language-add')));
      await tester.pump();
      expect(cubit.state.activeLanguage, 'en');
      expect(find.byKey(const ValueKey('editor-title-en')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('editor-title-en')), 'A new title');
      await tester.pump();
      expect(cubit.state.document.translation('en')!.title, 'A new title');

      cubit.removeTranslation('en');
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('editor-title-ar-EG')), findsOneWidget);
      await tester.runAsync(cubit.close); // stops the autosave and backup timers
    });

    testWidgets('a save conflict asks which version to keep', (tester) async {
      await tester.runAsync(() => cubit.open(articleId: 'art-1', language: 'ar-EG'));
      repo.onSave = (id, v, doc) => const Err(Failure(FailureCodes.articleDraftConflict));
      repo.onGet = (id) => Ok(sampleEdit(id: id, version: 9));
      await pumpPage(tester);
      await tester.enterText(find.byKey(const ValueKey('editor-title-ar-EG')), 'تعديل بيتعارض');
      await tester.runAsync(cubit.save);
      await tester.pumpAndSettle();
      expect(find.text('Edited somewhere else'), findsOneWidget);
      repo.onSave = (id, v, doc) => Ok(sampleEdit(version: v + 1, document: doc));
      await tester.tap(find.byKey(const ValueKey('conflict-keep')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'save art-1 v9');
      expect(cubit.state.conflicted, isFalse);
      await tester.runAsync(cubit.close);
    });
  });
}
