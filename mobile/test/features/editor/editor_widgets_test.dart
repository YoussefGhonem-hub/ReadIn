import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/bidi/bidi.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/categories/domain/usecases/category_usecases.dart';
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

import '../../helpers/category_fixtures.dart';
import '../../helpers/comment_fixtures.dart';
import '../../helpers/editor_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

const _en = Variant(AppLocales.en, Brightness.light);

/// The writer has no categories (F31): the settings sheet's picker offers "No category" and "New category" only.
final _noCategories = FakeCategoriesRepository();

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
        GetMyCategories(_noCategories),
        ManageCategories(_noCategories),
        SetArticleCategory(_noCategories),
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

  group('tag field (F32)', () {
    late ArticleEditorCubit cubit;
    late MockTagSuggestionsCubit suggestions;
    late List<String> searched;
    late AppLocalizations l10n;

    setUpAll(() async => l10n = await AppLocalizations.delegate.load(AppLocales.en));

    Future<void> pumpField(
      WidgetTester tester, {
      List<ArticleTag> suggested = const [],
      List<String> tags = const [],
      ArticleEdit Function(String id)? edit,
      Result<ArticleEdit>? createResult,
      Variant variant = _en,
    }) async {
      usePhoneSurface(tester, size: const Size(390, 2400));
      final repo = FakeArticleEditorRepository();
      if (edit != null) repo.onGet = (id) => Ok(edit(id));
      if (createResult != null) repo.onCreate = (_) => createResult;
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
        GetMyCategories(_noCategories),
        ManageCategories(_noCategories),
        SetArticleCategory(_noCategories),
      );
      await cubit.open(articleId: edit == null ? null : 'art-1', language: 'ar-EG');
      for (final tag in tags) {
        cubit.addTag(tag, existing: true);
      }
      searched = [];
      suggestions = MockTagSuggestionsCubit();
      whenListen(suggestions, const Stream<List<ArticleTag>>.empty(), initialState: suggested);
      when(() => suggestions.search(any())).thenAnswer((i) => searched.add(i.positionalArguments.first as String));
      final attachments = MockAttachmentsCubit();
      whenListen(attachments, const Stream<AttachmentsState>.empty(), initialState: const AttachmentsState());
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<ArticleEditorCubit>.value(value: cubit),
            BlocProvider<TagSuggestionsCubit>.value(value: suggestions),
            BlocProvider<AttachmentsCubit>.value(value: attachments),
          ],
          child: const Scaffold(body: ArticleSettingsPanel()),
        ),
        variant: variant,
      ));
      await tester.pump();
    }

    final input = find.byKey(const ValueKey('settings-tag-input'));
    final create = find.byKey(const ValueKey('tag-create'));

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(input, text);
      await tester.pump();
    }

    Future<void> enter(WidgetTester tester) async {
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    testWidgets('typing asks for suggestions; a picked one is added as it is, even an older name', (tester) async {
      await pumpField(tester, suggested: const [
        ArticleTag(slug: 'ef-core', name: 'EF Core', articleCount: 24),
        ArticleTag(slug: 'ci-cd', name: 'CI/CD', articleCount: 3),
      ]);
      await type(tester, '#e');
      expect(searched.last, '#e', reason: 'what was typed; the cubit cleans it');
      expect(find.text('EF Core'), findsOneWidget);
      expect(find.text(l10n.tagPageArticleCount(24)), findsOneWidget);
      expect(create, findsNothing, reason: 'one letter is too short for a new tag');

      await tester.tap(find.byKey(const ValueKey('tag-suggestion-ci-cd')));
      await tester.pump();
      expect(cubit.state.document.tags, ['CI/CD']);
      expect(find.byKey(const ValueKey('tag-suggestion-ci-cd')), findsNothing, reason: 'a chosen tag is no longer suggested');
      expect(find.text('#CI/CD'), findsOneWidget);
      expect(tester.widget<TextField>(find.descendant(of: input, matching: find.byType(TextField))).controller!.text, isEmpty);
      await cubit.close();
    });

    testWidgets('a new name offers "Create new tag"; the typed spelling of an existing tag becomes that tag', (tester) async {
      await pumpField(tester, suggested: const [ArticleTag(slug: 'ai', name: 'AI', articleCount: 40)]);
      await type(tester, 'AI agents');
      expect(find.text(l10n.tagCreate('${Bidi.fsi}AI agents${Bidi.pdi}')), findsOneWidget);
      await tester.tap(create);
      await tester.pump();
      expect(cubit.state.document.tags, ['AI agents']);

      await type(tester, '#ai');
      expect(create, findsNothing, reason: '"ai" is the tag AI');
      await enter(tester);
      expect(cubit.state.document.tags, ['AI agents', 'AI'], reason: 'the first spelling is kept');
      await cubit.close();
    });

    testWidgets('the rules show inline: characters at once, length on Enter, repeats ignored', (tester) async {
      await pumpField(tester, tags: const ['dotnet']);
      await type(tester, 'CI/CD');
      expect(find.text(l10n.tagInvalidCharacters), findsOneWidget);
      expect(create, findsNothing);
      await enter(tester);
      expect(cubit.state.document.tags, ['dotnet']);

      await type(tester, 'x');
      expect(find.text(l10n.tagTooShort), findsNothing, reason: 'it may still grow');
      await enter(tester);
      expect(find.text(l10n.tagTooShort), findsOneWidget);
      await type(tester, 'x' * 31);
      expect(find.text(l10n.tagTooLong), findsOneWidget);

      await type(tester, '++');
      expect(find.text(l10n.tagNoLetter), findsNothing, reason: 'a letter may still come');
      expect(find.text(l10n.tagInvalidCharacters), findsNothing, reason: 'every character is allowed');
      await enter(tester);
      expect(find.text(l10n.tagNoLetter), findsOneWidget);
      expect(cubit.state.document.tags, ['dotnet']);

      await type(tester, 'DotNet');
      await enter(tester);
      expect(find.text(l10n.tagAlreadyAdded), findsOneWidget);
      expect(cubit.state.document.tags, ['dotnet']);
      await cubit.close();
    });

    testWidgets('a comma (or "،") adds a tag; pasted names are added one by one', (tester) async {
      await pumpField(tester);
      await type(tester, 'C#,');
      expect(cubit.state.document.tags, ['C#']);
      await type(tester, '.NET، C++, EF');
      expect(cubit.state.document.tags, ['C#', '.NET', 'C++']);
      expect(tester.widget<TextField>(find.descendant(of: input, matching: find.byType(TextField))).controller!.text, ' EF');
      await tester.tap(find.byKey(const ValueKey('settings-tag-add')));
      await tester.pump();
      expect(cubit.state.document.tags, ['C#', '.NET', 'C++', 'EF']);
      await cubit.close();
    });

    testWidgets('a repeat in a pasted list is skipped, and the names after it are still added', (tester) async {
      await pumpField(tester, tags: const ['dotnet']);
      await type(tester, 'Flutter, flutter، DotNet, Dart, Go');
      expect(cubit.state.document.tags, ['dotnet', 'Flutter', 'Dart']);
      expect(tester.widget<TextField>(find.descendant(of: input, matching: find.byType(TextField))).controller!.text, ' Go');
      expect(find.text(l10n.tagAlreadyAdded), findsNothing);

      // The first name that breaks a rule still stops there, with its message.
      await type(tester, 'Rust, CI/CD, Zig,');
      expect(cubit.state.document.tags, ['dotnet', 'Flutter', 'Dart', 'Rust']);
      expect(tester.widget<TextField>(find.descendant(of: input, matching: find.byType(TextField))).controller!.text, 'CI/CD');
      expect(find.text(l10n.tagInvalidCharacters), findsOneWidget);
      await cubit.close();
    });

    testWidgets('at 5 tags the field is disabled with a hint; removing one enables it again', (tester) async {
      await pumpField(tester, tags: const ['a1', 'b2', 'c3', 'd4', 'e5']);
      expect(tester.widget<TextField>(find.descendant(of: input, matching: find.byType(TextField))).enabled, isFalse);
      expect(find.text(l10n.tagsFull), findsOneWidget);
      expect(find.text(l10n.tagsLimit(5)), findsOneWidget);
      await tester.tap(find.byTooltip(l10n.removeTag('c3')));
      await tester.pump();
      expect(tester.widget<TextField>(find.descendant(of: input, matching: find.byType(TextField))).enabled, isTrue);
      expect(find.text(l10n.tagsFull), findsNothing);
      await cubit.close();
    });

    testWidgets("the API's hidden tag and daily limit mark their chips, with a message", (tester) async {
      await pumpField(
        tester,
        edit: (id) => sampleEdit(
          id: id,
          document: sampleEdit().document.copyWith(tags: const ['Old', 'dotnet']),
          checks: const DraftChecks(problems: [DraftProblem(DraftProblemCodes.tagHidden, tag: 'Old')]),
        ),
      );
      expect(find.text(l10n.problemTagHidden('${Bidi.fsi}#Old${Bidi.pdi}')), findsOneWidget);
      final chip = tester.widget<InputChip>(find.descendant(of: find.byKey(const ValueKey('tag-Old')), matching: find.byType(InputChip)));
      expect(chip.avatar, isNotNull);
      await tester.tap(find.byTooltip(l10n.removeTag('Old')));
      await tester.pump();
      expect(find.text(l10n.problemTagHidden('${Bidi.fsi}#Old${Bidi.pdi}')), findsNothing);
      await cubit.close();
    });

    testWidgets('a save the API refused for its tags says why under the field', (tester) async {
      await pumpField(
        tester,
        tags: const ['dotnet'],
        createResult: const Err(Failure(
          FailureCodes.validationFailed,
          statusCode: 400,
          fieldErrors: {
            'document.tags[0]': [FailureCodes.tagInvalid],
          },
        )),
      );
      await cubit.save();
      await tester.pump();
      expect(cubit.state.saveStatus, SaveStatus.failed);
      expect(find.text(l10n.errTagInvalid), findsOneWidget);
      await cubit.close();
    });
  });

  group('the editor page', () {
    late FakeArticleEditorRepository repo;
    late ArticleEditorCubit cubit;

    Future<void> pumpPage(WidgetTester tester, {Size size = const Size(390, 1400), Variant variant = _en}) async {
      usePhoneSurface(tester, size: size);
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
        variant: variant,
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
        GetMyCategories(_noCategories),
        ManageCategories(_noCategories),
        SetArticleCategory(_noCategories),
      );
    });

    tearDown(() => cubit.close());

    for (final variant in Variant.all) {
      testWidgets('the toolbar is pinned under the language tabs and fits a small phone without scrolling ${variant.name}', (tester) async {
        await tester.runAsync(() => cubit.open(articleId: 'art-1', language: 'ar-EG'));
        const screen = Size(360, 740);
        await pumpPage(tester, size: screen, variant: variant);
        expect(tester.takeException(), isNull); // no overflow

        final toolbar = find.byKey(const ValueKey('editor-toolbar'));
        expect(find.descendant(of: toolbar, matching: find.byType(Scrollable)), findsNothing);
        expect(tester.getRect(toolbar).top, greaterThanOrEqualTo(tester.getRect(find.byKey(const ValueKey('language-ar-EG'))).bottom));
        expect(tester.getRect(toolbar).bottom, lessThanOrEqualTo(tester.getRect(find.byKey(const ValueKey('editor-title-ar-EG'))).top));

        const tools = [
          'format-bold', 'format-italic', 'format-strike', 'format-code', 'format-highlight', 'format-link', //
          'format-mention', 'format-term', 'toolbar-add-block', 'toolbar-block-options', 'format-line-break',
          'toolbar-undo', 'toolbar-redo',
        ];
        final page = Offset.zero & screen;
        for (final key in tools) {
          final rect = tester.getRect(find.byKey(ValueKey(key)));
          expect(page.intersect(rect), rect, reason: '$key is cut off');
          expect(rect.width, greaterThanOrEqualTo(36), reason: '$key is too small to tap');
        }
        // The formatting first, then the blocks; the add-a-block button says what it does.
        expect(
          tester.getRect(find.byKey(const ValueKey('format-bold'))).bottom,
          lessThanOrEqualTo(tester.getRect(find.byKey(const ValueKey('toolbar-add-block'))).top),
        );
        final l10n = tester.element(toolbar).l10n;
        final label = find.descendant(of: find.byKey(const ValueKey('toolbar-add-block')), matching: find.text(l10n.addBlock));
        expect(label, findsOneWidget);
        expect(tester.renderObject<RenderParagraph>(label).didExceedMaxLines, isFalse, reason: 'the label is cut off');
        // Nothing follows the caret yet, so nothing shows above the keyboard.
        expect(find.byKey(const ValueKey('editor-assist')), findsNothing);
        await tester.runAsync(cubit.close);
      });
    }

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

  group('category picker (F31)', () {
    late ArticleEditorCubit cubit;
    late FakeCategoriesRepository categories;
    late FakeArticleEditorRepository repo;
    late AppLocalizations l10n;

    setUpAll(() async => l10n = await AppLocalizations.delegate.load(AppLocales.en));

    Future<void> pumpPanel(WidgetTester tester, {String? categoryId, bool isNew = false}) async {
      usePhoneSurface(tester, size: const Size(390, 1400));
      repo = FakeArticleEditorRepository()
        ..onGet = ((id) => Ok(sampleEdit(id: id, categoryId: categoryId)))
        ..onCreate = ((doc) => Ok(sampleEdit(id: 'new-1', version: 1, document: doc)));
      categories = FakeCategoriesRepository(mine: const [backendTips, efCore]);
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
        GetMyCategories(categories),
        ManageCategories(categories),
        SetArticleCategory(categories),
      );
      await cubit.open(articleId: isNew ? null : 'art-1', language: 'en');
      final tags = MockTagSuggestionsCubit();
      whenListen(tags, const Stream<List<ArticleTag>>.empty(), initialState: const <ArticleTag>[]);
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
    }

    Finder picker() => find.byWidgetPredicate((w) => w is DropdownButtonFormField<String?> && '${w.key}'.contains('settings-category'));

    Future<void> choose(WidgetTester tester, String label) async {
      await tester.tap(picker());
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(label).last);
      await tester.pumpAndSettle();
    }

    testWidgets('shows the article\'s category; choosing another applies it at once', (tester) async {
      await pumpPanel(tester, categoryId: 'c-2');
      expect(find.text(l10n.editorCategoryLabel), findsOneWidget);
      expect(find.descendant(of: picker(), matching: find.text('EF Core')), findsOneWidget);

      await choose(tester, 'Backend');
      expect(categories.calls.last, 'set art-1 c-1');
      expect(cubit.state.categoryId, 'c-1');
      expect(repo.calls, ['get art-1'], reason: 'not part of the draft: no save');

      await choose(tester, l10n.editorCategoryNone);
      expect(categories.calls.last, 'set art-1 none');
      expect(cubit.state.categoryId, isNull);
      await cubit.close();
    });

    testWidgets('"New category" asks for a name, creates it and puts the article in it', (tester) async {
      await pumpPanel(tester);
      await choose(tester, l10n.categoryNew);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('category-name-input')), 'EF core');
      await tester.pump();
      expect(find.text(l10n.errCategoryNameTaken), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('category-name-input')), 'Flutter');
      await tester.tap(find.byKey(const ValueKey('category-name-submit')));
      await tester.pumpAndSettle();
      expect(categories.calls, containsAllInOrder(['create Flutter', 'set art-1 c-new-3']));
      expect(cubit.state.category?.name, 'Flutter');
      expect(find.descendant(of: picker(), matching: find.text('Flutter')), findsOneWidget);
      await cubit.close();
    });

    testWidgets('cancelling "New category" keeps the article\'s category', (tester) async {
      await pumpPanel(tester, categoryId: 'c-2');
      await choose(tester, l10n.categoryNew);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(find.descendant(of: picker(), matching: find.text('EF Core')), findsOneWidget);
      expect(categories.calls.where((c) => c.startsWith('set') || c.startsWith('create')), isEmpty);
      await cubit.close();
    });

    testWidgets('a new article is saved first, then put in the category', (tester) async {
      await pumpPanel(tester, isNew: true);
      await choose(tester, 'EF Core');
      expect(repo.calls, ['create']);
      expect(categories.calls.last, 'set new-1 c-2');
      await cubit.close();
    });
  });
}
