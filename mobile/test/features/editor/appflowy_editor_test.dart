import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';
import 'package:readin/features/editor/presentation/appflowy/appflowy_block_editor_controller.dart';
import 'package:readin/features/editor/presentation/appflowy/appflowy_surface.dart';
import 'package:readin/features/editor/presentation/appflowy/rdoc_appflowy_codec.dart';
import 'package:readin/features/editor/presentation/block_editor/block_editor_surface.dart';
import 'package:readin/features/editor/presentation/widgets/editor_widgets.dart';
import 'package:readin/shared/rdoc/editing/block_editing.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';
import 'package:readin/shared/rdoc/rdoc_scope.dart';

import '../../helpers/comment_fixtures.dart';
import '../../helpers/test_app.dart';

const _en = Variant(AppLocales.en, Brightness.light);

/// The editor's cursor blinks forever, so pumpAndSettle never settles: pump through the animations instead.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MockMentionSuggestionsCubit mentions;

  setUp(() {
    mentions = MockMentionSuggestionsCubit();
    whenListen(mentions, const Stream<List<Author>>.empty(), initialState: const <Author>[]);
    when(() => mentions.search(any())).thenReturn(null);
    when(mentions.clear).thenReturn(null);
  });

  Future<AppFlowyBlockEditorController> pumpEditor(WidgetTester tester, List<RBlock> blocks, {String language = 'en'}) async {
    usePhoneSurface(tester, size: const Size(390, 1400));
    const surface = AppFlowyBlockEditorSurface();
    final controller = surface.createController(RDocDocument(version: 1, language: language, blocks: blocks)) as AppFlowyBlockEditorController;
    final focus = EditorFocus();
    addTearDown(focus.dispose);
    await tester.pumpWidget(testApp(
      BlocProvider<MentionSuggestionsCubit>.value(
        value: mentions,
        child: Scaffold(
          body: RDocScope(
            baseDirection: language == 'en' ? TextDirection.ltr : TextDirection.rtl,
            child: Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) => surface.build(
                      context,
                      controller,
                      BlockEditorContext(
                        fallbackDirection: TextDirection.ltr,
                        focus: focus,
                        pickImage: () async => null,
                        uploadImage: (_) async => null,
                        header: const Text('HEADER'),
                      ),
                    ),
                  ),
                ),
                EditorToolbar(
                  formatter: controller,
                  enabled: true,
                  onAddBlock: () {},
                  onBlockOptions: () {
                    final id = controller.focusedBlockId;
                    if (id != null) showBlockOptionsSheet(tester.element(find.byType(Scaffold)), controller, id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      variant: _en,
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
    for (final text in ['Plain text', 'A heading', 'Callout body', 'Quoted', 'In short', 'Cell']) {
      expect(find.textContaining(text, findRichText: true), findsWidgets, reason: text);
    }
    expect(find.text('Careful'), findsOneWidget);
    expect(find.text('— Someone'), findsOneWidget);
    expect(find.byKey(const ValueKey('structured-code')), findsOneWidget);
    expect(controller.document.blocks, hasLength(8));
  });

  testWidgets('typing goes into the RDoc document and keeps glossary terms and mentions', (tester) async {
    final controller = await pumpEditor(tester, const [
      RParagraph('p', dir: 'auto', content: [RText('Use '), RTerm(termId: 'di', text: 'DI'), RText(' with '), RMention(userId: 'u1', text: '@mona')]),
    ]);
    var changes = 0;
    controller.addListener(() => changes++);
    await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 17)));
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
    await tester.tap(find.byKey(const ValueKey('format-bold')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('format-highlight')));
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

  testWidgets('mentions replace the typed @query; hard breaks are line breaks', (tester) async {
    final controller = await pumpEditor(tester, const [RParagraph('p', dir: 'auto', content: [RText('thanks @mo')])]);
    await select(tester, controller, Selection.collapsed(Position(path: [0], offset: 10)));
    final query = controller.activeMention!;
    expect(query.query, 'mo');
    controller.insertMention(query, userId: 'u-1', text: '@mona');
    await settle(tester);
    controller.insertHardBreak();
    await settle(tester);
    expect((controller.document.blocks.single as RParagraph).content, const [
      RText('thanks '),
      RMention(userId: 'u-1', text: '@mona'),
      RText(' '),
      RHardBreak(),
    ]);
  });

  testWidgets('a structured block opens in its sheet and saves back with its id', (tester) async {
    final controller = await pumpEditor(tester, const [RCode('code', lang: 'dart', code: 'old()')]);
    await tester.tap(find.byKey(const ValueKey('structured-code')));
    await settle(tester);
    await tester.enterText(find.text('old()'), 'newCode()');
    await tester.tap(find.byKey(const ValueKey('structured-done')));
    await settle(tester);
    expect(controller.document.blocks.single, const RCode('code', lang: 'dart', code: 'newCode()'));
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
}
