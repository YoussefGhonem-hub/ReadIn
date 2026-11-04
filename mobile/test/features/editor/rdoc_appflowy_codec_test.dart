import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/editor/presentation/appflowy/rdoc_appflowy_codec.dart';
import 'package:readin/shared/rdoc/editing/rdoc_codec.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/rdoc_test_utils.dart';
import '../../helpers/test_app.dart';

Map<String, dynamic> roundTrip(Map<String, dynamic> json) {
  final language = json['language'] as String;
  final document = RDocAppFlowyCodec.toDocument(RDocCodec.decode(json, language: language));
  return RDocCodec.encode(RDocAppFlowyCodec.fromDocument(document, language: language), language: language);
}

void main() {
  group('RDoc ⇄ AppFlowy', () {
    test('every file in shared/rdoc/examples round-trips without loss', () {
      final files = Directory('../shared/rdoc/examples').listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
      expect(files, isNotEmpty);
      for (final file in files) {
        final json = readSharedJson('rdoc/examples/${file.uri.pathSegments.last}');
        expect(canonical(roundTrip(json)), canonical(json), reason: file.path);
      }
    });

    test('every BiDi fixture survives in every text block, with marks, links, terms, mentions and hard breaks', () {
      for (final fixture in bidiFixtures()) {
        final json = fixtureDocument(fixture);
        expect(canonical(roundTrip(json)), canonical(json), reason: fixture['id'] as String);
      }
    });

    test('block ids are node ids; list items share their list id; directions are textDirection', () {
      const doc = RDocDocument(version: 1, language: 'ar-EG', blocks: [
        RParagraph('p1', dir: 'rtl', content: [RText('نص')]),
        RList('l1', ordered: false, dir: 'ltr', items: [
          [RText('a')],
          [RText('b')],
        ]),
        RList('l2', ordered: false, dir: 'auto', items: [
          [RText('c')],
        ]),
        RCode('c1', lang: 'dart', code: 'void main() {}'),
      ]);
      final document = RDocAppFlowyCodec.toDocument(doc);
      final nodes = document.root.children.toList();
      expect([for (final n in nodes) n.type], ['paragraph', 'bulleted_list', 'bulleted_list', 'bulleted_list', RDocNodeKeys.block]);
      expect(nodes.first.id, 'p1');
      expect(nodes.first.attributes[blockComponentTextDirection], 'rtl');
      expect([for (final n in nodes.sublist(1, 4)) n.attributes[RDocNodeKeys.listId]], ['l1', 'l1', 'l2']);
      // Two lists of the same kind next to each other stay two lists.
      final back = RDocAppFlowyCodec.fromDocument(document, language: 'ar-EG');
      expect(back, doc);
    });

    test('items typed after a list join it; nested items are flattened in order', () {
      final document = Document(
        root: Node(type: 'page', children: [
          Node(id: 'l1', type: NumberedListBlockKeys.type, attributes: {
            blockComponentDelta: (Delta()..insert('one')).toJson(),
            RDocNodeKeys.listId: 'l1',
          }, children: [
            Node(id: 'x1', type: NumberedListBlockKeys.type, attributes: {blockComponentDelta: (Delta()..insert('nested')).toJson()}),
          ]),
          Node(id: 'x2', type: NumberedListBlockKeys.type, attributes: {blockComponentDelta: (Delta()..insert('two')).toJson()}),
          Node(id: 'h', type: HeadingBlockKeys.type, attributes: {HeadingBlockKeys.level: 1, blockComponentDelta: (Delta()..insert('H1')).toJson()}),
        ]),
      );
      final doc = RDocAppFlowyCodec.fromDocument(document, language: 'en');
      expect(doc.blocks.first, const RList('l1', ordered: true, dir: 'auto', items: [
        [RText('one')],
        [RText('nested')],
        [RText('two')],
      ]));
      expect(doc.blocks.last, const RHeading('h', level: 2, dir: 'auto', content: [RText('H1')]), reason: 'H1 is the title, so it maps to H2');
    });

    test("AppFlowy's toggled-off attributes are no marks, and only http(s) links survive", () {
      final delta = Delta()
        ..insert('a', attributes: {AppFlowyRichTextKeys.bold: false})
        ..insert('b', attributes: {AppFlowyRichTextKeys.href: 'javascript:alert(1)'})
        ..insert('c', attributes: {AppFlowyRichTextKeys.href: 'https://readin.app', RDocNodeKeys.highlight: true});
      expect(RDocAppFlowyCodec.inlinesFrom(delta), const [
        RText('ab'),
        RText('c', marks: [RMark(RMarkType.link, href: 'https://readin.app'), RMark(RMarkType.highlight)]),
      ]);
    });
  });
}
