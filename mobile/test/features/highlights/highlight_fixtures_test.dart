import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/shared/rdoc/highlights/rdoc_highlight_text.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/test_app.dart';

/// `shared/rdoc/highlight-fixtures.json` (F30): the block plain text, the selection → range mapping and the isolate
/// mapping must agree with the backend's and the web's.
void main() {
  final fixtures = readSharedJson('rdoc/highlight-fixtures.json');
  final documents = {
    for (final e in (fixtures['documents'] as Map<String, dynamic>).entries)
      e.key: RDocDocument.fromJson(e.value as Map<String, dynamic>),
  };

  RBlock blockById(String document, String id) => documents[document]!.blocks.firstWhere((b) => b.id == id);

  group('block plain text', () {
    for (final e in (fixtures['blocks'] as Map<String, dynamic>).entries) {
      for (final raw in (e.value as List).cast<Map<String, dynamic>>()) {
        test('${e.key}/${raw['blockId']} (${raw['type']})', () {
          final text = RBlockText.of(blockById(e.key, raw['blockId'] as String));
          if (raw['highlightable'] != true) {
            expect(text, isNull);
            return;
          }
          expect(text, isNotNull);
          expect(text!.text, raw['plainText']);
          final items = (raw['items'] as List?)?.cast<Map<String, dynamic>>();
          if (items != null) {
            expect([for (final u in text.units) (u.start, u.end)], [for (final i in items) (i['startOffset'], i['endOffset'])]);
          } else {
            expect([for (final u in text.units) (u.start, u.end)], [(0, text.text.length)]);
          }
        });
      }
    }
  });

  group('selections', () {
    // Rendered both ways: the isolates a direction adds must never change the range.
    for (final direction in TextDirection.values) {
      for (final raw in (fixtures['selections'] as List).cast<Map<String, dynamic>>()) {
        test('${raw['id']} (${direction.name})', () {
          final document = documents[raw['document'] as String]!;
          final result = _select(document, raw['anchor'] as Map<String, dynamic>, raw['focus'] as Map<String, dynamic>, direction);
          final expected = raw['expected'] as Map<String, dynamic>?;
          if (expected == null) {
            final status = switch (raw['reason']) {
              'too_short' => HighlightSelectionStatus.tooShort,
              'block_not_allowed' => HighlightSelectionStatus.notAllowed,
              final other => fail('unknown reason $other'),
            };
            expect(result.status, status, reason: raw['description'] as String);
            return;
          }
          expect(result.status, HighlightSelectionStatus.ok, reason: raw['description'] as String);
          expect(result.range, _range(expected));
        });
      }
    }
  });

  group('isolate mapping', () {
    final mapping = fixtures['isolateMapping'] as Map<String, dynamic>;
    for (final raw in (mapping['cases'] as List).cast<Map<String, dynamic>>()) {
      test(raw['id'] as String, () {
        final block = blockById(raw['document'] as String, raw['blockId'] as String);
        final rendered = raw['rendered'] as String;
        // The rendered string is the plain text plus isolates, nothing else.
        expect(String.fromCharCodes(rendered.codeUnits.where((c) => !isBidiControl(c))), RBlockText.of(block)!.text);
        final result = mapBlockSelection(block, [rendered], [(base: raw['renderedStart'] as int, extent: raw['renderedEnd'] as int)]);
        expect(result.status, HighlightSelectionStatus.ok);
        expect(result.range, _range(raw['expected'] as Map<String, dynamic>));
        // Backwards gives the same.
        final back = mapBlockSelection(block, [rendered], [(base: raw['renderedEnd'] as int, extent: raw['renderedStart'] as int)]);
        expect(back.range, result.range);
      });
    }

    test("the reader's own rendering of p1 is the fixture's (FSI isolates)", () {
      final p1 = blockById('ar', 'p1') as RParagraph;
      final rendered = p1.content.map((n) => renderedInlineText(n, TextDirection.rtl)).join();
      final iso = (mapping['cases'] as List).cast<Map<String, dynamic>>().firstWhere((c) => c['id'] == 'iso-inside-isolated-run');
      expect(rendered, iso['rendered']);
    });
  });

  group('rules', () {
    final p = RDocDocument.fromJson({
      'version': 1,
      'language': 'en',
      'blocks': [
        {
          'id': 'x',
          'type': 'paragraph',
          'content': [
            {'type': 'text', 'text': '   ${'a' * 1001} 　'},
          ],
        },
      ],
    }).blocks.single;
    final text = RBlockText.of(p)!;

    test('every whitespace of the list is trimmed at both ends', () {
      final r = resolveHighlightSelection(text, text.units.single, 0, text.text.length);
      expect(r.range!.startOffset, 3);
      expect(r.range!.endOffset, 3 + 1001);
      expect(r.status, HighlightSelectionStatus.tooLong);
    });

    test('1,000 code units is fine, 2 is too short, 3 is fine', () {
      expect(resolveHighlightSelection(text, text.units.single, 3, 1003).status, HighlightSelectionStatus.ok);
      expect(resolveHighlightSelection(text, text.units.single, 3, 5).status, HighlightSelectionStatus.tooShort);
      expect(resolveHighlightSelection(text, text.units.single, 3, 6).status, HighlightSelectionStatus.ok);
    });

    test('isolates and embeddings are bidi controls; other format characters are not', () {
      for (final c in [0x2066, 0x2067, 0x2068, 0x2069, 0x202A, 0x202B, 0x202C, 0x202D, 0x202E]) {
        expect(isBidiControl(c), isTrue, reason: c.toRadixString(16));
      }
      for (final c in [0x200D, 0x200E, 0x200F, 0x061C, 0x20]) {
        expect(isBidiControl(c), isFalse, reason: c.toRadixString(16));
      }
    });
  });

  group('marks', () {
    final l1 = RBlockText.of(blockById('ar', 'l1'))!;

    test('a unit without marks is one plain piece', () {
      expect(highlightPieces(l1.units[1], const []), [RHighlightPiece(start: 0, end: l1.units[1].text.length, mine: false, count: 0)]);
    });

    test('pieces are cut where marks start and end, in unit offsets; yours and popular combine', () {
      final unit = l1.units[1]; // 32..63
      final pieces = highlightPieces(unit, const [
        RHighlightMark(start: 39, end: 50, mine: true, id: 'h1'),
        RHighlightMark(start: 45, end: 63, count: 4),
        RHighlightMark(start: 0, end: 20, mine: true, id: 'other-item'),
      ]);
      expect(pieces, const [
        RHighlightPiece(start: 0, end: 7, mine: false, count: 0),
        RHighlightPiece(start: 7, end: 13, mine: true, count: 0),
        RHighlightPiece(start: 13, end: 18, mine: true, count: 4),
        RHighlightPiece(start: 18, end: 31, mine: false, count: 4),
      ]);
    });
  });
}

HighlightRange _range(Map<String, dynamic> raw) => HighlightRange(
      blockId: raw['blockId'] as String,
      startOffset: raw['startOffset'] as int,
      endOffset: raw['endOffset'] as int,
      text: raw['text'] as String,
    );

/// A selection end in the reader: block [block], unit [unit] (-1 before the first unit: a callout title; units.length
/// after the last: a quote cite), at [offset] in that unit's rendered string.
typedef _Point = ({int block, int unit, int offset});

/// What the reader's selection reports for a fixture selection: each unit of the block where it starts gets its
/// selected part (rendered offsets, reversed for a backwards selection), as Flutter's selection does; then the app's
/// [mapBlockSelection] decides.
HighlightSelection _select(RDocDocument doc, Map<String, dynamic> anchor, Map<String, dynamic> focus, TextDirection dir) {
  _Point point(Map<String, dynamic> p) {
    final index = doc.blocks.indexWhere((b) => b.id == p['block']);
    final block = doc.blocks[index];
    final text = RBlockText.of(block);
    switch (p['part']) {
      case 'title':
        return (block: index, unit: -1, offset: 0);
      case 'cite':
        return (block: index, unit: text!.units.length, offset: 0);
      case String():
        return (block: index, unit: 0, offset: p['offset'] as int);
    }
    final unit = (p['item'] as int?) ?? 0;
    final nodes = text!.units[unit].nodes;
    final inline = p['inline'] as int;
    var offset = 0;
    for (var i = 0; i < inline; i++) {
      offset += renderedInlineText(nodes[i], dir).length;
    }
    // Inside node [inline]: before its plain character [p.offset] (after any isolate that opens there).
    final rendered = renderedInlineText(nodes[inline], dir);
    offset += renderedOffsetsOf(rendered)[p['offset'] as int];
    return (block: index, unit: unit, offset: offset);
  }

  int compare(_Point a, _Point b) =>
      a.block != b.block ? a.block - b.block : (a.unit != b.unit ? a.unit - b.unit : a.offset - b.offset);

  final a = point(anchor);
  final f = point(focus);
  final backwards = compare(f, a) < 0;
  final start = backwards ? f : a;
  final end = backwards ? a : f;
  final block = doc.blocks[start.block];
  final text = RBlockText.of(block);
  if (text == null) return mapBlockSelection(block, const [], const []);
  final rendered = [for (final u in text.units) u.nodes.map((n) => renderedInlineText(n, dir)).join()];
  final selected = <RenderedRange?>[];
  for (var i = 0; i < text.units.length; i++) {
    final from = i < start.unit ? null : (i == start.unit ? start.offset : 0);
    final to = end.block > start.block || i < end.unit ? rendered[i].length : (i == end.unit ? end.offset : null);
    if (from == null || to == null) {
      selected.add(null);
      continue;
    }
    final lo = math.min(from, to);
    final hi = math.max(from, to);
    selected.add(backwards ? (base: hi, extent: lo) : (base: lo, extent: hi));
  }
  return mapBlockSelection(block, rendered, selected);
}

