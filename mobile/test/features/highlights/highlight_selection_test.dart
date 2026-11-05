import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../../helpers/test_app.dart';

/// The reader's selection toolbar and marks (F30) on the shared fixture documents: real long presses through Flutter's
/// SelectionArea, the toolbar's Highlight / Remove, popular taps, and BiDi kept intact under marks.
void main() {
  final fixtures = readSharedJson('rdoc/highlight-fixtures.json');
  final documents = {
    for (final e in (fixtures['documents'] as Map<String, dynamic>).entries)
      e.key: RDocDocument.fromJson(e.value as Map<String, dynamic>),
  };

  late List<HighlightSelection> highlighted;
  late List<String> removed;
  late List<int> counted;
  late List<String> terms;

  setUp(() {
    highlighted = [];
    removed = [];
    counted = [];
    terms = [];
  });

  Future<void> pump(
    WidgetTester tester,
    String document, {
    Map<String, List<RHighlightMark>> marks = const {},
    bool enabled = true,
    bool canHighlight = true,
    RHighlightMineTapHandler? onMineTap,
    Variant variant = const Variant(AppLocales.ar, Brightness.light),
  }) async {
    final doc = documents[document]!;
    usePhoneSurface(tester, size: const Size(390, 3000));
    await tester.pumpWidget(testApp(
      Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: RDocScope(
            baseDirection: RDocScope.directionForLanguage(doc.language),
            onTermTap: (term) => terms.add(term.termId),
            child: RDocHighlights(
              enabled: enabled,
              marks: marks,
              canHighlight: canHighlight,
              onHighlight: (_, selection) => highlighted.add(selection),
              onRemove: (_, id) => removed.add(id),
              onCountTap: (_, _, count) => counted.add(count),
              onMineTap: onMineTap,
              child: RDocColumn(doc),
            ),
          ),
        ),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  Finder block(RBlock b) => find.byKey(ValueKey('rdoc-${b.type}-${b.id}'));

  Finder unitText(String document, String blockId, {int unit = 0}) {
    final b = documents[document]!.blocks.firstWhere((x) => x.id == blockId);
    return find.descendant(
      of: find.descendant(of: block(b), matching: find.byWidgetPredicate((w) => w is RHighlightUnit && w.unit == unit)),
      matching: find.byType(RichText),
    );
  }

  /// The middle of the character at plain offset [plain] of a unit (isolates skipped), in global coordinates.
  Offset at(WidgetTester tester, Finder rich, int plain) {
    final paragraph = tester.renderObject<RenderParagraph>(rich);
    final rendered = paragraph.text.toPlainText();
    final offset = renderedOffsetsOf(rendered)[plain];
    // A letter followed by combining marks is one cluster: widen until it has a box.
    for (var end = offset + 1; end <= rendered.length; end++) {
      final boxes = paragraph.getBoxesForSelection(TextSelection(baseOffset: offset, extentOffset: end));
      if (boxes.isNotEmpty) return paragraph.localToGlobal(boxes.first.toRect().center);
    }
    throw StateError('no box at $plain');
  }

  Future<void> longPress(WidgetTester tester, Finder rich, int plain) async {
    await tester.longPressAt(at(tester, rich, plain));
    await tester.pumpAndSettle();
  }

  group('rendering under highlights', () {
    for (final document in ['ar', 'en']) {
      testWidgets('every highlightable unit of "$document" draws its plain text plus isolates only', (tester) async {
        await pump(tester, document);
        for (final b in documents[document]!.blocks) {
          final text = RBlockText.of(b);
          expect(find.descendant(of: block(b), matching: find.byType(SelectionArea)), text == null ? findsNothing : findsOneWidget,
              reason: b.id);
          if (text == null) continue;
          for (final unit in text.units) {
            final rich = tester.widget<RichText>(unitText(document, b.id, unit: unit.index));
            final rendered = rich.text.toPlainText();
            expect(String.fromCharCodes(rendered.codeUnits.where((c) => !isBidiControl(c))), unit.text, reason: b.id);
            final reported = tester.widget<RHighlightUnit>(
              find.descendant(of: block(b), matching: find.byWidgetPredicate((w) => w is RHighlightUnit && w.unit == unit.index)),
            );
            expect(reported.rendered, rendered, reason: b.id);
          }
        }
      });
    }

    testWidgets('marks never change the drawn text: same characters, same isolates, same order', (tester) async {
      await pump(tester, 'ar');
      final before = <String, String>{};
      for (final b in documents['ar']!.blocks) {
        final text = RBlockText.of(b);
        if (text == null) continue;
        for (final u in text.units) {
          before['${b.id}/${u.index}'] = tester.widget<RichText>(unitText('ar', b.id, unit: u.index)).text.toPlainText();
        }
      }
      // Every fixture range as one of yours, plus overlapping popular ranges.
      final marks = <String, List<RHighlightMark>>{};
      var n = 0;
      for (final s in (fixtures['selections'] as List).cast<Map<String, dynamic>>()) {
        final e = s['expected'] as Map<String, dynamic>?;
        if (e == null || s['document'] != 'ar') continue;
        final start = e['startOffset'] as int;
        final end = e['endOffset'] as int;
        marks.putIfAbsent(e['blockId'] as String, () => []).addAll([
          RHighlightMark(start: start, end: end, mine: n.isEven, id: 'h${n++}', count: n.isOdd ? 3 : 0),
          RHighlightMark(start: start + 1, end: end, count: 7),
        ]);
      }
      await pump(tester, 'ar', marks: marks);
      var styled = 0;
      for (final entry in before.entries) {
        final [id, unit] = entry.key.split('/');
        final rich = tester.widget<RichText>(unitText('ar', id, unit: int.parse(unit)));
        expect(rich.text.toPlainText(), entry.value, reason: entry.key);
        rich.text.visitChildren((span) {
          if (span is TextSpan && span.style?.decoration?.contains(TextDecoration.underline) == true) styled++;
          return true;
        });
      }
      expect(styled, greaterThan(10));
    });

    testWidgets('yours: the soft background and the amber underline; popular: the lighter underline only', (tester) async {
      await pump(tester, 'en', marks: const {
        'e3': [RHighlightMark(start: 0, end: 3, mine: true, id: 'h1'), RHighlightMark(start: 7, end: 14, count: 5)],
      });
      final context = tester.element(unitText('en', 'e3'));
      final colors = context.colors;
      final spans = <TextSpan>[];
      tester.widget<RichText>(unitText('en', 'e3')).text.visitChildren((s) {
        if (s is TextSpan && s.text != null) spans.add(s);
        return true;
      });
      final mine = spans.firstWhere((s) => s.text == 'Why');
      expect(mine.style!.backgroundColor, colors.accentContainer);
      expect(mine.style!.decorationColor, colors.accent);
      final popular = spans.firstWhere((s) => s.text == 'matters');
      expect(popular.style!.backgroundColor, isNull);
      expect(popular.style!.decorationColor, colors.accent.withValues(alpha: 0.55));
      // The link keeps its color.
      expect(popular.style!.color, colors.link);
    });

    testWidgets('hidden: no selection, no marks', (tester) async {
      await pump(tester, 'en', enabled: false, marks: const {
        'e3': [RHighlightMark(start: 0, end: 3, mine: true, id: 'h1')],
      });
      expect(find.byType(SelectionArea), findsNothing);
      expect(find.byType(RHighlightUnit), findsNothing);
      final rich = tester.widget<RichText>(find.descendant(of: find.byKey(const ValueKey('rdoc-heading-e3')), matching: find.byType(RichText)));
      var underlined = 0;
      rich.text.visitChildren((s) {
        if (s is TextSpan && s.style?.backgroundColor != null) underlined++;
        return true;
      });
      expect(underlined, 0);
    });
  });

  group('toolbar', () {
    testWidgets('a long press on an English word offers Highlight, which sends its range', (tester) async {
      await pump(tester, 'en', variant: const Variant(AppLocales.en, Brightness.light));
      await longPress(tester, unitText('en', 'e3'), 9); // "matters"
      final l10n = tester.element(find.byType(Scaffold)).l10n;
      expect(find.text(l10n.highlightAction), findsOneWidget);
      expect(find.text(l10n.highlightRemove), findsNothing);
      await tester.tap(find.text(l10n.highlightAction));
      await tester.pumpAndSettle();
      expect(highlighted.single.status, HighlightSelectionStatus.ok);
      expect(highlighted.single.range, const HighlightRange(blockId: 'e3', startOffset: 7, endOffset: 14, text: 'matters'));
      // The toolbar closed and the selection cleared.
      expect(find.text(l10n.highlightAction), findsNothing);
    });

    testWidgets('inside an isolated English run of an Arabic paragraph, the isolates are not counted', (tester) async {
      await pump(tester, 'ar');
      await longPress(tester, unitText('ar', 'p1'), 45); // "Dependency" (plain 42–52)
      await tester.tap(find.text('علّم'));
      await tester.pumpAndSettle();
      expect(highlighted.single.range, const HighlightRange(blockId: 'p1', startOffset: 42, endOffset: 52, text: 'Dependency'));
    });

    testWidgets('an Arabic word with tashkeel keeps every combining mark', (tester) async {
      await pump(tester, 'ar');
      await longPress(tester, unitText('ar', 'p3'), 18); // "مُهِمّ" (plain 16–22: 3 letters, 3 marks)
      await tester.tap(find.text('علّم'));
      await tester.pumpAndSettle();
      expect(highlighted.single.range, const HighlightRange(blockId: 'p3', startOffset: 16, endOffset: 22, text: 'مُهِمّ'));
    });

    testWidgets('a list item counts from the start of the whole list', (tester) async {
      await pump(tester, 'en', variant: const Variant(AppLocales.en, Brightness.light));
      await longPress(tester, unitText('en', 'e4', unit: 1), 5); // "words" (item 2: 4–18)
      await tester.tap(find.text('Highlight'));
      await tester.pumpAndSettle();
      expect(highlighted.single.range, const HighlightRange(blockId: 'e4', startOffset: 8, endOffset: 13, text: 'words'));
    });

    testWidgets('a selection from a callout title into its text starts at the text (mouse drag, right click)', (tester) async {
      await pump(tester, 'ar');
      final c1 = documents['ar']!.blocks.firstWhere((b) => b.id == 'c1');
      final title = find.descendant(
        of: block(c1),
        matching: find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == 'نصيحة سريعة'),
      );
      final drag = await tester.startGesture(at(tester, title, 3), kind: PointerDeviceKind.mouse);
      await tester.pump();
      await drag.moveTo(at(tester, unitText('ar', 'c1'), 3));
      await tester.pump();
      await drag.moveTo(at(tester, unitText('ar', 'c1'), 11));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();
      final menu = await tester.startGesture(at(tester, unitText('ar', 'c1'), 2), kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
      await menu.up();
      await tester.pumpAndSettle();
      await tester.tap(find.text('علّم'));
      await tester.pumpAndSettle();
      final range = highlighted.single.range!;
      expect(range.blockId, 'c1');
      expect(range.startOffset, 0);
      expect(range.text, startsWith('استخدم AddSc'));
      expect(range.text, isNot(contains('نصيحة')));
    });

    testWidgets('two characters: no Highlight button, Copy stays', (tester) async {
      await pump(tester, 'ar');
      await longPress(tester, unitText('ar', 'p1'), 0); // "لو"
      final material = MaterialLocalizations.of(tester.element(find.byType(Scaffold)));
      expect(find.text(material.copyButtonLabel), findsOneWidget);
      expect(find.text('علّم'), findsNothing);
    });

    testWidgets('inside one of your highlights: Remove, which sends its id', (tester) async {
      await pump(tester, 'ar', marks: const {
        'p1': [RHighlightMark(start: 15, end: 27, mine: true, id: 'h-asp')],
      });
      await longPress(tester, unitText('ar', 'p1'), 24); // "Core"
      expect(find.text('علّم'), findsNothing);
      await tester.tap(find.text('شيل العلامة'));
      await tester.pumpAndSettle();
      expect(removed, ['h-asp']);
      expect(highlighted, isEmpty);
    });

    testWidgets('one of yours still being created offers no Remove (nor Highlight inside it)', (tester) async {
      await pump(tester, 'ar', marks: const {
        'p1': [RHighlightMark(start: 15, end: 27, mine: true)],
      });
      await longPress(tester, unitText('ar', 'p1'), 24);
      expect(find.text('شيل العلامة'), findsNothing);
      // The server joins it: Highlight is still offered.
      expect(find.text('علّم'), findsOneWidget);
    });

    testWidgets('without the permission there is no Highlight button, nor Remove', (tester) async {
      await pump(tester, 'ar', canHighlight: false, marks: const {
        'p1': [RHighlightMark(start: 15, end: 27, mine: true, id: 'h-asp')],
      });
      await longPress(tester, unitText('ar', 'p1'), 45);
      expect(find.text('علّم'), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await longPress(tester, unitText('ar', 'p1'), 24);
      expect(find.text('شيل العلامة'), findsNothing);
    });

    testWidgets('code, table and steps blocks never select', (tester) async {
      await pump(tester, 'ar');
      for (final id in ['k1', 't1', 'st1']) {
        final b = documents['ar']!.blocks.firstWhere((x) => x.id == id);
        expect(find.descendant(of: block(b), matching: find.byType(SelectionArea)), findsNothing, reason: id);
      }
    });
  });

  group('taps', () {
    testWidgets('a popular range says how many readers marked it', (tester) async {
      await pump(tester, 'ar', marks: const {
        'q1': [RHighlightMark(start: 24, end: 37, count: 6)],
      });
      await tester.tapAt(at(tester, unitText('ar', 'q1'), 28));
      await tester.pumpAndSettle();
      expect(counted, [6]);
    });

    testWidgets('yours that is also popular shows the count too; plain text and yours alone do not', (tester) async {
      await pump(tester, 'ar', marks: const {
        'q1': [
          RHighlightMark(start: 24, end: 37, mine: true, id: 'h1'),
          RHighlightMark(start: 24, end: 37, count: 3),
          RHighlightMark(start: 0, end: 10, mine: true, id: 'h2'),
        ],
      });
      await tester.tapAt(at(tester, unitText('ar', 'q1'), 28));
      await tester.pumpAndSettle();
      await tester.tapAt(at(tester, unitText('ar', 'q1'), 4));
      await tester.pumpAndSettle();
      await tester.tapAt(at(tester, unitText('ar', 'q1'), 44));
      await tester.pumpAndSettle();
      expect(counted, [3]);
    });

    testWidgets('tapping one of yours offers Remove: its id, with the count when it is popular too', (tester) async {
      final mine = <(String, int)>[];
      const marks = {
        'q1': [
          RHighlightMark(start: 24, end: 37, mine: true, id: 'h1'),
          RHighlightMark(start: 24, end: 37, count: 3),
          RHighlightMark(start: 0, end: 10, mine: true, id: 'h2'),
          // Still being created: nothing to remove yet.
          RHighlightMark(start: 40, end: 44, mine: true),
        ],
      };
      await pump(tester, 'ar', marks: marks, onMineTap: (_, _, id, count) => mine.add((id, count)));
      for (final plain in [28, 4, 42]) {
        await tester.tapAt(at(tester, unitText('ar', 'q1'), plain));
        await tester.pumpAndSettle();
      }
      expect(mine, [('h1', 3), ('h2', 0)]);
      expect(counted, isEmpty);

      // Without the permission, yours can't be removed: only the count shows.
      mine.clear();
      await pump(tester, 'ar', marks: marks, canHighlight: false, onMineTap: (_, _, id, count) => mine.add((id, count)));
      for (final plain in [28, 4]) {
        await tester.tapAt(at(tester, unitText('ar', 'q1'), plain));
        await tester.pumpAndSettle();
      }
      expect(mine, isEmpty);
      expect(counted, [3]);
    });

    testWidgets('a glossary term still opens inside a highlightable block, marked or not', (tester) async {
      await pump(tester, 'ar', marks: const {
        'p1': [RHighlightMark(start: 42, end: 52, count: 4)],
      });
      await tester.tapAt(at(tester, unitText('ar', 'p1'), 45));
      await tester.pumpAndSettle();
      await tester.tapAt(at(tester, unitText('ar', 'p1'), 55));
      await tester.pumpAndSettle();
      expect(terms, ['dependency-injection', 'dependency-injection']);
      expect(counted, isEmpty);
    });
  });
}
