import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';
import 'package:readin/features/editor/presentation/appflowy/appflowy_block_editor_controller.dart';
import 'package:readin/features/editor/presentation/appflowy/appflowy_surface.dart';
import 'package:readin/features/editor/presentation/appflowy/rdoc_appflowy_codec.dart';
import 'package:readin/features/editor/presentation/block_editor/block_editor_surface.dart';
import 'package:readin/features/editor/presentation/block_editor/block_editors.dart';
import 'package:readin/features/editor/presentation/block_editor/inline_formatter.dart';
import 'package:readin/features/editor/presentation/widgets/editor_widgets.dart';
import 'package:readin/features/glossary/domain/usecases/search_glossary_terms.dart';
import 'package:readin/features/glossary/presentation/cubit/glossary_search_cubit.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/shared/rdoc/blocks/media_blocks.dart';
import 'package:readin/shared/rdoc/editing/block_editing.dart';
import 'package:readin/shared/rdoc/editing/rdoc_codec.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';
import 'package:readin/shared/rdoc/rdoc_scope.dart';
import 'package:readin/shared/widgets/app_network_image.dart';

import '../../helpers/comment_fixtures.dart';
import '../../helpers/fake_media.dart';
import '../../helpers/glossary_fixtures.dart';
import '../../helpers/media_fixtures.dart';
import '../../helpers/test_app.dart';

const _en = Variant(AppLocales.en, Brightness.light);
const _ar = Variant(AppLocales.ar, Brightness.light);
const _p = RDocNodeKeys.placeholder;

/// The editor's cursor blinks forever, so pumpAndSettle never settles: pump through the animations instead.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// [document] after an RDoc → AppFlowy → RDoc round trip, as JSON.
Map<String, dynamic> roundTripped(RDocDocument document) => RDocCodec.encode(
      RDocAppFlowyCodec.fromDocument(RDocAppFlowyCodec.toDocument(document), language: document.language),
      language: document.language,
    );

void main() {
  late MockMentionSuggestionsCubit mentions;
  late EditorFocus focus;

  setUpAll(() async {
    await FakeMedia.install();
    AppNetworkImage.providerFactory = FakeImageProvider.new;
  });

  tearDownAll(() => AppNetworkImage.providerFactory = NetworkImage.new);

  setUp(() {
    mentions = MockMentionSuggestionsCubit();
    whenListen(mentions, const Stream<List<Author>>.empty(), initialState: const <Author>[]);
    when(() => mentions.search(any())).thenReturn(null);
    when(mentions.clear).thenReturn(null);
  });

  Future<AppFlowyBlockEditorController> pumpEditor(
    WidgetTester tester,
    List<RBlock> blocks, {
    String language = 'en',
    Variant variant = _en,
    Future<PickedMediaFile?> Function()? pickImage,
    Future<MediaAsset?> Function(PickedMediaFile file)? uploadImage,
  }) async {
    usePhoneSurface(tester, size: const Size(390, 1400));
    const surface = AppFlowyBlockEditorSurface();
    final controller = surface.createController(RDocDocument(version: 1, language: language, blocks: blocks)) as AppFlowyBlockEditorController;
    focus = EditorFocus();
    addTearDown(focus.dispose);
    final rtl = language != 'en';
    await tester.pumpWidget(testApp(
      BlocProvider<MentionSuggestionsCubit>.value(
        value: mentions,
        child: Scaffold(
          body: RDocScope(
            baseDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) => surface.build(
                      context,
                      controller,
                      BlockEditorContext(
                        fallbackDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                        focus: focus,
                        pickImage: pickImage ?? () async => null,
                        uploadImage: uploadImage ?? (_) async => null,
                        header: const Text('HEADER'),
                      ),
                    ),
                  ),
                ),
                EditorToolbar(
                  formatter: controller,
                  focus: focus,
                  history: controller,
                  enabled: true,
                  onAddBlock: () {},
                  onBlockOptions: () {
                    final id = focus.blockId ?? controller.focusedBlockId;
                    if (id != null) showBlockOptionsSheet(tester.element(find.byType(Scaffold)), controller, id);
                  },
                  onTableTool: (tool) => applyTableTool(controller, controller, focus, tool),
                ),
              ],
            ),
          ),
        ),
      ),
      variant: variant,
    ));
    await settle(tester);
    return controller;
  }

  EditorState stateOf(AppFlowyBlockEditorController c) => c.editorState;

  Future<void> select(WidgetTester tester, AppFlowyBlockEditorController c, Selection selection) async {
    // Completes after a frame: pump instead of awaiting it.
    unawaited(stateOf(c).updateSelectionWithReason(selection, reason: SelectionUpdateReason.uiEvent));
    await settle(tester);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey(key)));
    await settle(tester);
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(ValueKey(key)), text);
    await settle(tester);
  }

  String fieldText(WidgetTester tester, String key) =>
      tester.widget<EditableText>(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText))).controller.text;

  T blockOf<T extends RBlock>(AppFlowyBlockEditorController c, String id) => c.document.blocks.firstWhere((b) => b.id == id) as T;

  testWidgets('renders every kind of block with the header above them', (tester) async {
    final controller = await pumpEditor(tester, const [
      RParagraph('p', dir: 'auto', content: [RText('Plain text')]),
      RHeading('h', level: 2, dir: 'auto', content: [RText('A heading')]),
      RCallout('c', variant: RCalloutVariant.warning, dir: 'auto', title: 'Careful', content: [RText('Callout body')]),
      RQuote('q', dir: 'auto', content: [RText('Quoted')], cite: 'Someone'),
      RSummary('s', dir: 'auto', content: [RText('In short')]),
      RCode('code', lang: 'dart', code: 'void main() {}'),
      RDivider('d'),
      RTable('t', dir: 'auto', header: [[RText('Col')]], rows: [[[RText('Cell')]]]),
    ]);
    expect(find.text('HEADER'), findsOneWidget);
    for (final text in ['Plain text', 'A heading', 'Callout body', 'Quoted', 'In short']) {
      expect(find.textContaining(text, findRichText: true), findsWidgets, reason: text);
    }
    // The chrome and the structured blocks are fields in place.
    expect(fieldText(tester, 'callout-title-c'), 'Careful');
    expect(fieldText(tester, 'quote-cite-q'), 'Someone');
    expect(fieldText(tester, 'code-code'), 'void main() {}');
    expect(fieldText(tester, 't-field-0-0'), 'Col');
    expect(fieldText(tester, 't-field-1-0'), 'Cell');
    expect(find.byKey(const ValueKey('structured-code')), findsOneWidget);
    expect(controller.document.blocks, hasLength(8));
  });

  testWidgets('typing goes into the RDoc document and keeps glossary terms and mentions', (tester) async {
    final controller = await pumpEditor(tester, const [
      RParagraph('p', dir: 'auto', content: [RText('Use '), RTerm(termId: 'di', text: 'DI'), RText(' with '), RMention(userId: 'u1', text: '@mona')]),
    ]);
    var changes = 0;
    controller.addListener(() => changes++);
    // 'Use ' + the term (one character) + ' with ' + the mention (one character).
    expect(stateOf(controller).getNodeAtPath([0])!.delta!.toPlainText(), 'Use $_p with $_p');
    await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 12)));
    await stateOf(controller).insertTextAtPosition(' today');
    await settle(tester);
    expect(changes, greaterThan(0));
    expect((controller.document.blocks.single as RParagraph).content, const [
      RText('Use '),
      RTerm(termId: 'di', text: 'DI'),
      RText(' with '),
      RMention(userId: 'u1', text: '@mona'),
      RText(' today'),
    ]);
  });

  testWidgets('markdown shortcuts: ## → H2, ### → H3, > → quote, ```dart → code', (tester) async {
    final controller = await pumpEditor(tester, const [
      RParagraph('a', dir: 'auto', content: [RText('##')]),
      RParagraph('b', dir: 'auto', content: [RText('###')]),
      RParagraph('c', dir: 'auto', content: [RText('>')]),
      RParagraph('d', dir: 'auto', content: [RText('```dart')]),
    ]);
    Future<void> shortcut(CharacterShortcutEvent event, int path, int offset) async {
      await select(tester, controller, Selection.collapsed(Position(path: [path], offset: offset)));
      expect(await event.handler(stateOf(controller)), isTrue);
      await settle(tester);
    }

    await shortcut(rdocHeadingShortcut, 0, 2);
    await shortcut(rdocHeadingShortcut, 1, 3);
    await shortcut(rdocQuoteShortcut, 2, 1);
    await shortcut(rdocCodeShortcut, 3, 7);
    final blocks = controller.document.blocks;
    expect(blocks[0], isA<RHeading>().having((h) => h.level, 'level', 2));
    expect(blocks[1], isA<RHeading>().having((h) => h.level, 'level', 3));
    expect(blocks[2], isA<RQuote>());
    expect(blocks[3], isA<RCode>().having((c) => c.lang, 'lang', 'dart'));
  });

  testWidgets('/ opens the slash menu in the toolbar; picking a block replaces the paragraph', (tester) async {
    final controller = await pumpEditor(tester, const [RParagraph('p', dir: 'auto', content: [RText('/cal')])]);
    await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 4)));
    expect(controller.slashQuery, 'cal');
    expect(find.byKey(const ValueKey('slash-callout')), findsOneWidget);
    expect(find.byKey(const ValueKey('slash-table')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('slash-callout')));
    await settle(tester);
    expect(controller.document.blocks.single, const RCallout('p', variant: RCalloutVariant.tip, dir: 'auto', content: []));
  });

  testWidgets('the block options set a direction override; code stays LTR', (tester) async {
    final controller = await pumpEditor(tester, const [
      RParagraph('p', dir: 'auto', content: [RText('React ولا Angular؟')]),
      RCode('c', lang: 'dart', code: 'x'),
    ]);
    await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 2)));
    expect(controller.focusedBlockId, 'p');
    await tester.tap(find.byKey(const ValueKey('toolbar-block-options')));
    await settle(tester);
    await tester.tap(find.text('RTL'));
    await settle(tester);
    expect((controller.document.blocks.first as RParagraph).dir, 'rtl');
    expect(stateOf(controller).getNodeAtPath([0])!.attributes[blockComponentTextDirection], 'rtl');
    controller.setDirection('c', 'rtl');
    await settle(tester);
    expect(controller.document.blocks.last, const RCode('c', lang: 'dart', code: 'x'));
  });

  testWidgets('the toolbar marks the selection and links it', (tester) async {
    final controller = await pumpEditor(tester, const [RParagraph('p', dir: 'auto', content: [RText('make it bold')])]);
    await select(tester, controller, Selection.single(path: [0], startOffset: 8, endOffset: 12));
    await tap(tester, 'format-bold');
    await settle(tester);
    await tap(tester, 'format-highlight');
    await settle(tester);
    expect((controller.document.blocks.single as RParagraph).content, const [
      RText('make it '),
      RText('bold', marks: [RMark(RMarkType.bold), RMark(RMarkType.highlight)]),
    ]);
    controller.setLink('https://readin.app');
    controller.setLink('javascript:alert(1)'); // refused
    await settle(tester);
    expect((controller.document.blocks.single as RParagraph).content.last, isA<RText>().having((t) => t.href, 'href', 'https://readin.app'));
  });

  testWidgets('the link button links the selected words through its dialog', (tester) async {
    final controller = await pumpEditor(tester, const [RParagraph('p', dir: 'auto', content: [RText('read the docs')])]);
    await select(tester, controller, Selection.single(path: [0], startOffset: 9, endOffset: 13));
    await tap(tester, 'format-link');
    await tester.enterText(find.byKey(const ValueKey('link-url')), 'https://readin.app/docs');
    await tester.tap(find.byKey(const ValueKey('link-save')));
    await settle(tester);
    expect((controller.document.blocks.single as RParagraph).content, const [
      RText('read the '),
      RText('docs', marks: [RMark(RMarkType.link, href: 'https://readin.app/docs')]),
    ]);
  });

  testWidgets('insertBlock, convert, move and remove keep ids', (tester) async {
    final controller = await pumpEditor(tester, const [
      RParagraph('p', dir: 'auto', content: [RText('x')]),
      RDivider('d'),
    ]);
    final id = controller.insertBlock(RBlockKind.table, afterId: 'p');
    await settle(tester);
    expect([for (final b in controller.document.blocks) b.id], ['p', id, 'd']);
    controller.convert('p', RBlockKind.heading3);
    await settle(tester);
    expect(controller.document.blocks.first, const RHeading('p', level: 3, dir: 'auto', content: [RText('x')]));
    controller.move('p', 1);
    await settle(tester);
    expect([for (final b in controller.document.blocks) b.id], [id, 'p', 'd']);
    controller.remove(id);
    await settle(tester);
    expect([for (final b in controller.document.blocks) b.id], ['p', 'd']);
  });

  testWidgets('load replaces the content with a new editor', (tester) async {
    final controller = await pumpEditor(tester, const [RParagraph('p', dir: 'auto', content: [RText('before')])]);
    final generation = controller.generation;
    controller.load(const RDocDocument(version: 1, language: 'en', blocks: [RParagraph('n', dir: 'auto', content: [RText('after')])]));
    expect(controller.generation, generation + 1);
    expect(controller.document.blocks.single.id, 'n');
    expect(RDocAppFlowyCodec.fromDocument(controller.editorState.document, language: 'en').blocks.single.id, 'n');
  });

  group('mentions and glossary terms are atomic', () {
    const sentence = RParagraph('p', dir: 'auto', content: [RText('hi '), RMention(userId: 'u1', text: '@mona'), RText(' there')]);

    testWidgets('the caret steps over a mention as one character', (tester) async {
      final controller = await pumpEditor(tester, const [sentence]);
      expect(stateOf(controller).getNodeAtPath([0])!.delta!.toPlainText(), 'hi $_p there');
      await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 4)));
      moveCursorLeftCommand.execute(stateOf(controller));
      await settle(tester);
      expect(stateOf(controller).selection, Selection.collapsed(Position(path: [0], offset: 3)));
      moveCursorRightCommand.execute(stateOf(controller));
      await settle(tester);
      expect(stateOf(controller).selection, Selection.collapsed(Position(path: [0], offset: 4)));
    });

    testWidgets('Backspace after a mention removes it whole', (tester) async {
      final controller = await pumpEditor(tester, const [sentence]);
      await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 4)));
      backspaceCommand.execute(stateOf(controller));
      await settle(tester);
      expect((controller.document.blocks.single as RParagraph).content, const [RText('hi  there')]);
      expect(find.byKey(const ValueKey('mention-chip-u1')), findsNothing);
    });

    testWidgets('typing next to a mention never extends it or splits it', (tester) async {
      final controller = await pumpEditor(tester, const [
        RParagraph('p', dir: 'auto', content: [RText('hi '), RMention(userId: 'u1', text: '@mona'), RTerm(termId: 'di', text: 'DI')]),
      ]);
      // Before the mention, between the mention and the term, after the term.
      for (final (offset, text) in [(3, 'a'), (5, 'b'), (7, 'c')]) {
        await select(tester, controller, Selection.collapsed(Position(path: [0], offset: offset)));
        await stateOf(controller).insertTextAtPosition(text);
        await settle(tester);
      }
      expect((controller.document.blocks.single as RParagraph).content, const [
        RText('hi a'),
        RMention(userId: 'u1', text: '@mona'),
        RText('b'),
        RTerm(termId: 'di', text: 'DI'),
        RText('c'),
      ]);
    });

    testWidgets('picking an @ suggestion replaces "@query" with one atomic mention', (tester) async {
      whenListen(mentions, const Stream<List<Author>>.empty(), initialState: const [mona]);
      final controller = await pumpEditor(tester, const [RParagraph('p', dir: 'auto', content: [RText('thanks @mo')])]);
      await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 10)));
      expect(controller.activeMention!.query, 'mo');
      await tester.tap(find.text('@mona_dev'));
      await settle(tester);
      expect(stateOf(controller).getNodeAtPath([0])!.delta!.toPlainText(), 'thanks $_p ');
      expect(stateOf(controller).selection, Selection.collapsed(Position(path: [0], offset: 9)));
      expect(find.byKey(const ValueKey('mention-chip-w-1')), findsOneWidget);
      controller.insertHardBreak();
      await settle(tester);
      expect((controller.document.blocks.single as RParagraph).content, const [
        RText('thanks '),
        RMention(userId: 'w-1', text: '@mona_dev'),
        RText(' '),
        RHardBreak(),
      ]);
    });

    testWidgets('a mention at the end of an RTL line is a chip laid out LTR, at the line end', (tester) async {
      await pumpEditor(
        tester,
        const [
          RParagraph('p', dir: 'auto', content: [RText('شكراً لـ '), RMention(userId: 'u1', text: '@mona')]),
        ],
        language: 'ar-EG',
        variant: _ar,
      );
      final chip = find.byKey(const ValueKey('mention-chip-u1'));
      expect(chip, findsOneWidget);
      expect(tester.widget<Text>(find.descendant(of: chip, matching: find.byType(Text))).textDirection, TextDirection.ltr);
      final line = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains(_p));
      expect(tester.widget<RichText>(line).textDirection, TextDirection.rtl);
      // The Arabic text runs from the right; the chip ends the line on the left of all of it.
      final paragraph = tester.renderObject<RenderParagraph>(line);
      final arabic = paragraph.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 9));
      final chipRect = tester.getRect(chip);
      final arabicLeft = arabic.map((b) => paragraph.localToGlobal(Offset(b.left, 0)).dx).reduce((a, b) => a < b ? a : b);
      expect(chipRect.right, lessThanOrEqualTo(arabicLeft + 0.5));
      expect(chipRect.center.dy, closeTo(paragraph.localToGlobal(Offset(0, arabic.first.toRect().center.dy)).dy, 6));
    });

    test('the codec maps a mention and a term to one placeholder and back', () {
      const doc = RDocDocument(version: 1, language: 'ar-EG', blocks: [
        RParagraph('p', dir: 'auto', content: [
          RText('اسأل '),
          RMention(userId: 'u1', text: '@mona'),
          RText(' عن '),
          RTerm(termId: 'di', text: 'Dependency Injection'),
        ]),
      ]);
      final node = RDocAppFlowyCodec.toDocument(doc).root.children.single;
      expect(node.delta!.toPlainText(), 'اسأل $_p عن $_p');
      expect(roundTripped(doc), RDocCodec.encode(doc, language: 'ar-EG'));
    });
  });

  group('glossary terms (F21)', () {
    late FakeGlossaryRepository glossary;

    setUp(() {
      glossary = FakeGlossaryRepository();
      getIt.registerFactory<GlossarySearchCubit>(() => GlossarySearchCubit(SearchGlossaryTerms(glossary)));
    });

    tearDown(() => getIt.unregister<GlossarySearchCubit>());

    IconButton termButton(WidgetTester tester) => tester.widget<IconButton>(find.byKey(const ValueKey('format-term')));

    testWidgets('select words → the picker searches for them → the pick makes one atomic term', (tester) async {
      final controller = await pumpEditor(
        tester,
        const [RParagraph('p', dir: 'auto', content: [RText('استخدم Dependency Injection هنا')])],
        language: 'ar-EG',
        variant: _ar,
      );
      // A caret in plain words: nothing to mark.
      await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 3)));
      expect(termButton(tester).onPressed, isNull);

      // " Dependency Injection " → the words without the spaces.
      await select(tester, controller, Selection.single(path: [0], startOffset: 6, endOffset: 28));
      expect(controller.termSelection, const TermSelection(start: 7, end: 27, text: 'Dependency Injection'));
      await tap(tester, 'format-term');
      await tester.pump(const Duration(milliseconds: 400));
      expect(glossary.searches, ['Dependency Injection']);
      expect(find.byKey(const ValueKey('term-option-dependency-injection')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('term-option-dependency-injection')));
      await settle(tester);
      expect((controller.document.blocks.single as RParagraph).content, const [
        RText('استخدم '),
        RTerm(termId: 'dependency-injection', text: 'Dependency Injection'),
        RText(' هنا'),
      ]);
      expect(stateOf(controller).getNodeAtPath([0])!.delta!.toPlainText(), 'استخدم $_p هنا');
      expect(find.byKey(const ValueKey('term-chip-dependency-injection')), findsOneWidget);
    });

    testWidgets('the caret after a term opens it again: Remove term gives the words back', (tester) async {
      final controller = await pumpEditor(tester, const [
        RParagraph('p', dir: 'auto', content: [RText('Use '), RTerm(termId: 'ioc-container', text: 'IoC'), RText(' here')]),
      ]);
      await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 5)));
      expect(controller.termSelection, const TermSelection(start: 4, end: 5, text: 'IoC', termId: 'ioc-container'));
      expect(termButton(tester).isSelected, isTrue);

      await tap(tester, 'format-term');
      await tester.pump(const Duration(milliseconds: 400));
      expect(glossary.searches, ['ioc-container']);
      expect(tester.widget<ListTile>(find.byKey(const ValueKey('term-option-ioc-container'))).selected, isTrue);
      await tester.tap(find.byKey(const ValueKey('term-remove')));
      await settle(tester);
      expect((controller.document.blocks.single as RParagraph).content, const [RText('Use IoC here')]);
    });

    testWidgets('a mention in the selection, or spaces only: nothing to mark', (tester) async {
      final controller = await pumpEditor(tester, const [
        RParagraph('p', dir: 'auto', content: [RText('hi '), RMention(userId: 'u1', text: '@mona'), RText('   there')]),
      ]);
      await select(tester, controller, Selection.single(path: [0], startOffset: 0, endOffset: 6));
      expect(controller.termSelection, isNull);
      await select(tester, controller, Selection.single(path: [0], startOffset: 4, endOffset: 7));
      expect(controller.termSelection, isNull);
      expect(termButton(tester).onPressed, isNull);
    });
  });

  group('structured blocks are edited in place', () {
    testWidgets('table: type in a cell, add and delete a row and a column from the toolbar, delete the table', (tester) async {
      final controller = await pumpEditor(tester, const [
        RTable('t', dir: 'auto', header: [
          [RText('A')],
          [RText('B')],
        ], rows: [
          [
            [RText('1')],
            [RText('2')],
          ],
        ]),
      ]);
      expect(find.byKey(const ValueKey('table-tools')), findsNothing);
      await type(tester, 't-field-1-0', 'one');
      expect(focus.cell, (row: 1, col: 0));
      expect(find.byKey(const ValueKey('table-tools')), findsOneWidget);
      expect(blockOf<RTable>(controller, 't').rows.single.first, const [RText('one')]);

      await tap(tester, 'table-addRow');
      await tap(tester, 'table-addColumn');
      var table = blockOf<RTable>(controller, 't');
      expect(table.header, const [
        [RText('A')],
        <RInline>[],
        [RText('B')],
      ]);
      expect(table.rows, const [
        [
          [RText('one')],
          <RInline>[],
          [RText('2')],
        ],
        [<RInline>[], <RInline>[], <RInline>[]],
      ]);
      await type(tester, 't-field-2-1', 'new');
      expect(blockOf<RTable>(controller, 't').rows.last[1], const [RText('new')]);
      expect(roundTripped(controller.document), RDocCodec.encode(controller.document, language: 'en'));

      // The cell in focus is (2, 1): its row goes and the caret moves up to (1, 1); then that column goes.
      await tap(tester, 'table-deleteRow');
      expect(focus.cell, (row: 1, col: 1));
      await tap(tester, 'table-deleteColumn');
      table = blockOf<RTable>(controller, 't');
      expect(table.header, const [
        [RText('A')],
        [RText('B')],
      ]);
      expect(table.rows, const [
        [
          [RText('one')],
          [RText('2')],
        ],
      ]);

      await type(tester, 't-field-1-1', 'two');
      await tap(tester, 'table-deleteTable');
      expect(controller.document.blocks.whereType<RTable>(), isEmpty);
    });

    testWidgets('table: the header row and the last column stay', (tester) async {
      final controller = await pumpEditor(tester, const [
        RTable('t', dir: 'auto', header: [
          [RText('A')],
        ], rows: []),
      ]);
      await type(tester, 't-field-0-0', 'Head');
      await tap(tester, 'table-deleteRow');
      await tap(tester, 'table-deleteColumn');
      expect(blockOf<RTable>(controller, 't'), const RTable('t', dir: 'auto', header: [
        [RText('Head')],
      ], rows: []));
    });

    testWidgets('code: Enter adds a line inside the code; language and file name in its header', (tester) async {
      final controller = await pumpEditor(tester, const [RCode('code', lang: 'dart', code: 'old()')]);
      await tester.showKeyboard(find.byKey(const ValueKey('code-code')));
      // The keyboard types a line break, then more code.
      tester.testTextInput.updateEditingValue(const TextEditingValue(text: 'old()\n', selection: TextSelection.collapsed(offset: 6)));
      await settle(tester);
      tester.testTextInput.updateEditingValue(const TextEditingValue(text: 'old()\nnext()', selection: TextSelection.collapsed(offset: 12)));
      await settle(tester);
      expect(controller.document.blocks, const [RCode('code', lang: 'dart', code: 'old()\nnext()')]);

      await tap(tester, 'code-lang');
      await tester.tap(find.text('Python').last);
      await settle(tester);
      await type(tester, 'code-filename', 'main.py');
      expect(controller.document.blocks.single, const RCode('code', lang: 'python', code: 'old()\nnext()', filename: 'main.py'));
      expect(roundTripped(controller.document), RDocCodec.encode(controller.document, language: 'en'));
    });

    testWidgets("a tap on a block's field takes the keyboard from the text around it", (tester) async {
      final controller = await pumpEditor(tester, const [
        RParagraph('p', dir: 'auto', content: [RText('Before the code')]),
        RCode('code', lang: 'dart', code: 'x'),
      ]);
      await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 3)));
      expect(stateOf(controller).selection, isNotNull);
      await tester.tap(find.byKey(const ValueKey('code-filename')));
      await settle(tester);
      final field = tester.widget<EditableText>(find.descendant(of: find.byKey(const ValueKey('code-filename')), matching: find.byType(EditableText)));
      expect(field.focusNode.hasFocus, isTrue);
      expect(stateOf(controller).selection, isNull, reason: 'one caret at a time');
      // Typing goes to the field, not to the paragraph.
      tester.testTextInput.enterText('main.dart');
      await settle(tester);
      expect(controller.document.blocks, const [
        RParagraph('p', dir: 'auto', content: [RText('Before the code')]),
        RCode('code', lang: 'dart', code: 'x', filename: 'main.dart'),
      ]);
    });

    testWidgets('code tabs: add, rename, change language, switch and remove', (tester) async {
      final controller = await pumpEditor(tester, const [
        RCodeTabs('tabs', tabs: [RCodeTab(label: 'C#', lang: 'csharp', code: 'var x = 1;')]),
      ]);
      await tap(tester, 'tabs-tab-add');
      var tabs = blockOf<RCodeTabs>(controller, 'tabs').tabs;
      expect(tabs, hasLength(2));
      expect(tabs.last, const RCodeTab(label: 'Text', lang: 'plaintext', code: ''));
      expect(fieldText(tester, 'tabs-tab-code'), '', reason: 'the new tab is the active one');

      // A name that still names the language follows it; a renamed tab keeps its name.
      await tap(tester, 'tabs-tab-lang');
      await tester.tap(find.text('Python').last);
      await settle(tester);
      expect(blockOf<RCodeTabs>(controller, 'tabs').tabs.last.label, 'Python');
      await type(tester, 'tabs-tab-label', 'Python 3');
      await type(tester, 'tabs-tab-filename', 'main.py');
      await type(tester, 'tabs-tab-code', 'x = 1');
      await tap(tester, 'tabs-tab-lang');
      await tester.tap(find.text('Go').last);
      await settle(tester);
      tabs = blockOf<RCodeTabs>(controller, 'tabs').tabs;
      expect(tabs.last, const RCodeTab(label: 'Python 3', lang: 'go', code: 'x = 1', filename: 'main.py'));

      await tap(tester, 'tabs-tab-0');
      expect(fieldText(tester, 'tabs-tab-code'), 'var x = 1;');
      expect(fieldText(tester, 'tabs-tab-label'), 'C#');

      await tap(tester, 'tabs-tab-remove');
      expect(blockOf<RCodeTabs>(controller, 'tabs').tabs, [tabs.last]);
      expect(roundTripped(controller.document), RDocCodec.encode(controller.document, language: 'en'));
      // Removing the last tab removes the block.
      await tap(tester, 'tabs-tab-remove');
      expect(controller.document.blocks.whereType<RCodeTabs>(), isEmpty);
    });

    testWidgets('code tabs: at most 8', (tester) async {
      await pumpEditor(tester, [
        RCodeTabs('tabs', tabs: [for (var i = 0; i < 7; i++) RCodeTab(label: 'T$i', lang: 'dart', code: '')]),
      ]);
      await tap(tester, 'tabs-tab-add');
      expect(find.byKey(const ValueKey('tabs-tab-7')), findsOneWidget);
      expect(find.byKey(const ValueKey('tabs-tab-add')), findsNothing);
    });

    testWidgets('steps: add, edit and remove steps in place', (tester) async {
      final controller = await pumpEditor(tester, const [
        RSteps('st', dir: 'auto', items: [RStep(title: 'One', content: [RText('first')])]),
      ]);
      await tap(tester, 'st-step-add');
      await type(tester, 'st-step-title-1', 'Two');
      await type(tester, 'st-step-body-1', 'second');
      expect(blockOf<RSteps>(controller, 'st').items, const [
        RStep(title: 'One', content: [RText('first')]),
        RStep(title: 'Two', content: [RText('second')]),
      ]);
      await tap(tester, 'st-step-remove-0');
      expect(blockOf<RSteps>(controller, 'st').items, const [
        RStep(title: 'Two', content: [RText('second')]),
      ]);
      expect(find.byKey(const ValueKey('st-step-remove-0')), findsNothing, reason: 'a list of steps keeps one step');
    });

    testWidgets('image: upload in place, then alt text (flagged while missing) and caption under it', (tester) async {
      final controller = await pumpEditor(
        tester,
        const [RImage('img', src: '', alt: '')],
        pickImage: () async => sampleImageFile,
        uploadImage: (_) async => imageAsset('a1'),
      );
      expect(find.byKey(const ValueKey('img-alt')), findsNothing);
      await tap(tester, 'image-choose-img');
      final uploaded = blockOf<RImage>(controller, 'img');
      expect(uploaded.src, imageAsset('a1').variants.last.url);
      expect((uploaded.width, uploaded.height), (1600, 1200));

      final l10n = tester.element(find.byType(Scaffold)).l10n;
      expect(find.text(l10n.problemImageAlt), findsOneWidget);
      await type(tester, 'img-alt', 'A diagram of the request scope');
      await type(tester, 'img-caption', 'One scope per request');
      expect(find.text(l10n.problemImageAlt), findsNothing);
      expect(
        blockOf<RImage>(controller, 'img'),
        RImage('img', src: uploaded.src, alt: 'A diagram of the request scope', caption: 'One scope per request', width: 1600, height: 1200),
      );
      expect(find.byKey(const ValueKey('image-replace-img')), findsOneWidget);
    });

    testWidgets('image: a dark mode version is added and removed as on the web; the size stays the picture\'s', (tester) async {
      const picture = RImage('img', src: 'https://cdn.readin.app/a.webp', alt: 'A diagram', width: 1600, height: 1200);
      final controller = await pumpEditor(
        tester,
        const [picture],
        pickImage: () async => sampleImageFile,
        uploadImage: (_) async => imageAsset('dark'),
      );
      final l10n = tester.element(find.byType(Scaffold)).l10n;
      expect(find.text(l10n.imageDarkAdd), findsOneWidget);
      expect(find.byKey(const ValueKey('image-dark-remove-img')), findsNothing);

      await tap(tester, 'image-dark-add-img');
      final withDark = blockOf<RImage>(controller, 'img');
      expect(withDark.darkSrc, imageAsset('dark').variants.last.url);
      expect((withDark.src, withDark.width, withDark.height), (picture.src, 1600, 1200));
      expect(find.text(l10n.imageDarkVersion), findsOneWidget);
      expect(find.byKey(const ValueKey('image-dark-add-img')), findsNothing);

      await tap(tester, 'image-dark-remove-img');
      expect(blockOf<RImage>(controller, 'img'), picture);
      expect(find.text(l10n.imageDarkAdd), findsOneWidget);
    });

    testWidgets('embed: the link is checked as on the web, and a valid one shows the preview', (tester) async {
      final controller = await pumpEditor(tester, const [REmbed('e', provider: 'youtube', url: '')]);
      final l10n = tester.element(find.byType(Scaffold)).l10n;
      await type(tester, 'e-url', 'https://vimeo.com/123');
      expect(find.text(l10n.embedInvalid), findsOneWidget);
      expect(find.byType(REmbedView), findsNothing);
      await type(tester, 'e-url', 'https://youtu.be/dQw4w9WgXcQ');
      expect(find.text(l10n.embedInvalid), findsNothing);
      expect(find.byType(REmbedView), findsOneWidget);
      expect(controller.document.blocks.single, const REmbed('e', provider: 'youtube', url: 'https://youtu.be/dQw4w9WgXcQ'));
      // The same link is not a Gist.
      await tester.tap(find.text('GitHub Gist'));
      await settle(tester);
      expect(find.text(l10n.embedInvalid), findsOneWidget);
    });

    test("EmbedLinks matches the web editor's isAllowedEmbed", () {
      for (final url in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtube.com/watch?v=dQw4w9WgXcQ&t=42',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        'https://www.youtube.com/live/dQw4w9WgXcQ',
        'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
      ]) {
        expect(EmbedLinks.isValid('youtube', url), isTrue, reason: url);
      }
      for (final url in [
        'https://vimeo.com/123',
        'https://www.youtube.com/watch?v=short',
        'https://www.youtube.com/channel/UC123',
        'https://youtube.evil.com/watch?v=dQw4w9WgXcQ',
        'javascript:alert(1)',
        'https://gist.github.com/mona/abc123',
      ]) {
        expect(EmbedLinks.isValid('youtube', url), isFalse, reason: url);
      }
      expect(EmbedLinks.isValid('github-gist', 'https://gist.github.com/mona-dev/0a1b2c3d4e'), isTrue);
      expect(EmbedLinks.isValid('github-gist', 'https://gist.github.com/mona-dev/not-hex'), isFalse);
      expect(EmbedLinks.isValid('github-gist', 'http://gist.github.com/mona/0a1b'), isFalse);
      expect(EmbedLinks.isValid('github-gist', 'https://github.com/mona/repo'), isFalse);
    });

    testWidgets('quote cite and callout variant and title are edited in place', (tester) async {
      final controller = await pumpEditor(tester, const [
        RQuote('q', dir: 'auto', content: [RText('Quoted')]),
        RCallout('c', variant: RCalloutVariant.tip, dir: 'auto', content: [RText('Body')]),
      ]);
      await type(tester, 'quote-cite-q', 'Ada');
      await type(tester, 'callout-title-c', 'Heads up');
      await tap(tester, 'callout-variant-c');
      await tester.tap(find.text(tester.element(find.byType(Scaffold)).l10n.calloutWarning).last);
      await settle(tester);
      expect(controller.document.blocks, const [
        RQuote('q', dir: 'auto', content: [RText('Quoted')], cite: 'Ada'),
        RCallout('c', variant: RCalloutVariant.warning, dir: 'auto', title: 'Heads up', content: [RText('Body')]),
      ]);
    });
  });

  group('undo and redo', () {
    IconButton button(WidgetTester tester, String key) => tester.widget<IconButton>(find.byKey(ValueKey(key)));

    testWidgets('the buttons undo and redo, and are disabled when there is nothing to undo or redo', (tester) async {
      final controller = await pumpEditor(tester, const [RParagraph('p', dir: 'auto', content: [RText('Hello')])]);
      expect(find.byTooltip('Undo'), findsOneWidget);
      expect(find.byTooltip('Redo'), findsOneWidget);
      expect(button(tester, 'toolbar-undo').onPressed, isNull);
      expect(button(tester, 'toolbar-redo').onPressed, isNull);

      await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 5)));
      await stateOf(controller).insertTextAtPosition(' world');
      await settle(tester);
      expect(button(tester, 'toolbar-undo').onPressed, isNotNull);
      expect(button(tester, 'toolbar-redo').onPressed, isNull);

      await tap(tester, 'toolbar-undo');
      expect((controller.document.blocks.single as RParagraph).content, const [RText('Hello')]);
      expect(button(tester, 'toolbar-undo').onPressed, isNull);
      expect(button(tester, 'toolbar-redo').onPressed, isNotNull);

      await tap(tester, 'toolbar-redo');
      expect((controller.document.blocks.single as RParagraph).content, const [RText('Hello world')]);
      expect(button(tester, 'toolbar-redo').onPressed, isNull);
      expect(button(tester, 'toolbar-undo').onPressed, isNotNull);
    });

    testWidgets('an edit inside a structured block is undone in place, even while its field has focus', (tester) async {
      final controller = await pumpEditor(tester, const [RCode('code', lang: 'dart', code: 'old()')]);
      await type(tester, 'code-code', 'new()');
      expect(controller.document.blocks.single, const RCode('code', lang: 'dart', code: 'new()'));
      await tap(tester, 'toolbar-undo');
      expect(controller.document.blocks.single, const RCode('code', lang: 'dart', code: 'old()'));
      expect(fieldText(tester, 'code-code'), 'old()');
      await tap(tester, 'toolbar-redo');
      expect(fieldText(tester, 'code-code'), 'new()');
    });

    testWidgets('in Arabic the buttons have Arabic labels and mirror: undo sits on the right of redo', (tester) async {
      await pumpEditor(tester, const [RParagraph('p', dir: 'auto', content: [RText('أهلاً')])], language: 'ar-EG', variant: _ar);
      expect(find.byTooltip('تراجع'), findsOneWidget);
      expect(find.byTooltip('إعادة'), findsOneWidget);
      expect(Icons.undo_rounded.matchTextDirection, isTrue);
      expect(Icons.redo_rounded.matchTextDirection, isTrue);
      expect(
        tester.getCenter(find.byKey(const ValueKey('toolbar-undo'))).dx,
        greaterThan(tester.getCenter(find.byKey(const ValueKey('toolbar-redo'))).dx),
      );
    });
  });
}
