import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/shared/rdoc/editing/block_editing.dart';
import 'package:readin/shared/rdoc/editing/rdoc_codec.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/rdoc_test_utils.dart';
import '../../helpers/test_app.dart';

void main() {
  final kitchenSink = readSharedJson('rdoc/examples/kitchen-sink.ar-EG.json');

  group('RDoc ⇄ editor document', () {
    test('every file in shared/rdoc/examples round-trips without loss', () {
      final files = Directory('../shared/rdoc/examples').listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
      expect(files, isNotEmpty);
      for (final file in files) {
        final json = readSharedJson('rdoc/examples/${file.uri.pathSegments.last}');
        final language = json['language'] as String;
        final decoded = RDocCodec.decode(json, language: language);
        expect(canonical(RDocCodec.encode(decoded, language: language)), canonical(json), reason: file.path);
        // A second pass changes nothing (stable ids, same content).
        expect(RDocCodec.decode(RDocCodec.encode(decoded, language: language), language: language), decoded);
      }
    });

    test('the kitchen sink covers every block type, mark and inline node', () {
      final doc = RDocCodec.decode(kitchenSink, language: 'ar-EG');
      expect({for (final b in doc.blocks) b.type}, {
        'summary', 'paragraph', 'heading', 'bulletList', 'orderedList', 'steps', 'callout', 'code', 'codeTabs', //
        'table', 'quote', 'image', 'divider', 'embed',
      });
      final json = RDocCodec.encode(doc, language: 'ar-EG').toString();
      for (final mark in RMarkType.values) {
        expect(json, contains('type: ${mark.name}'), reason: mark.name);
      }
      for (final node in ['term', 'mention', 'hardBreak']) {
        expect(json, contains('type: $node'));
      }
      final tabs = doc.blocks.whereType<RCodeTabs>().single;
      expect(tabs.tabs.first.compile, isFalse, reason: 'compile: false survives');
    });

    test('every BiDi fixture survives a round trip in every text block, with its terms and mentions', () {
      for (final fixture in bidiFixtures()) {
        final json = fixtureDocument(fixture);
        final decoded = RDocCodec.decode(json, language: 'ar-EG');
        expect(canonical(RDocCodec.encode(decoded, language: 'ar-EG')), canonical(json), reason: fixture['id'] as String);
        final terms = decoded.blocks.whereType<RParagraph>().single.content.whereType<RTerm>();
        expect(terms.single.termId, 'dependency-injection');
      }
    });

    test('auto direction follows the first strong character of every BiDi fixture; overrides win', () {
      for (final fixture in bidiFixtures()) {
        final paragraph = RParagraph('p', dir: 'auto', content: [RText(fixture['text'] as String)]);
        final expected = fixture['expectedDir'] == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
        expect(BlockDirection.resolve(paragraph, fallback: TextDirection.rtl), expected, reason: fixture['id'] as String);
        expect(BlockDirection.resolve(BlockDirection.withDir(paragraph, 'ltr'), fallback: TextDirection.rtl), TextDirection.ltr);
        expect(BlockDirection.resolve(BlockDirection.withDir(paragraph, 'rtl'), fallback: TextDirection.ltr), TextDirection.rtl);
      }
    });

    test('code and code tabs are always LTR and take no direction', () {
      const code = RCode('c', lang: 'csharp', code: 'var x = 1;');
      expect(BlockDirection.supportsDir(code), isFalse);
      expect(BlockDirection.withDir(code, 'rtl'), same(code));
      expect(BlockDirection.resolve(code, fallback: TextDirection.rtl), TextDirection.ltr);
      expect(BlockDirection.resolve(const RCodeTabs('t', tabs: []), fallback: TextDirection.rtl), TextDirection.ltr);
    });

    test('content.language is the translation language', () {
      final decoded = RDocCodec.decode(kitchenSink, language: 'en');
      expect(decoded.language, 'en');
      expect(RDocCodec.encode(decoded, language: 'ar-EG')['language'], 'ar-EG');
      expect(RDocCodec.decode(null, language: 'en'), const RDocDocument(version: 1, language: 'en', blocks: []));
    });
  });

  group('block ids', () {
    test('valid ids are kept; duplicates and invalid ones get new, unique ids', () {
      final json = {
        'version': 1,
        'language': 'en',
        'blocks': [
          {'id': 'a', 'type': 'divider'},
          {'id': 'a', 'type': 'divider'},
          {'id': 'not valid!', 'type': 'divider'},
          {'id': '', 'type': 'divider'},
          {'id': 'b', 'type': 'divider'},
        ],
      };
      final doc = RDocCodec.decode(json, language: 'en');
      final ids = [for (final b in doc.blocks) b.id];
      expect(ids.first, 'a');
      expect(ids.last, 'b');
      expect(ids.toSet(), hasLength(5));
      expect(ids.every(BlockIds.isValid), isTrue);
      // Stable: the next decode keeps them.
      expect([for (final b in RDocCodec.decode(RDocCodec.encode(doc, language: 'en'), language: 'en').blocks) b.id], ids);
    });

    test('generated ids match the schema and avoid taken ones', () {
      final random = Random(7);
      final taken = <String>{};
      for (var i = 0; i < 500; i++) {
        final id = BlockIds.generate(taken, random: random);
        expect(BlockIds.isValid(id), isTrue);
        expect(taken.add(id), isTrue);
      }
    });
  });

  group('what autosave sends', () {
    test('a complete document is sent unchanged', () {
      final doc = RDocCodec.decode(kitchenSink, language: 'ar-EG');
      expect(canonical(RDocCodec.encodeForSave(doc, language: 'ar-EG')), canonical(kitchenSink));
    });

    test('blocks still being filled in are left out; nothing with content is', () {
      const doc = RDocDocument(version: 1, language: 'en', blocks: [
        RHeading('h', level: 2, dir: 'auto', content: []),
        RImage('i', src: '', alt: ''),
        RImage('i2', src: 'https://cdn/x.webp', alt: ''),
        REmbed('e', provider: 'youtube', url: 'not a link'),
        RSteps('s', dir: 'auto', items: [RStep(title: '', content: [])]),
        RSteps('s2', dir: 'auto', items: [RStep(title: '', content: [RText('body')])]),
        RCodeTabs('t', tabs: [RCodeTab(label: '', lang: 'Not A Lang', code: 'x')]),
        RParagraph('p', dir: 'auto', content: [RText(''), RText('a'), RText('b')]),
      ]);
      final saved = RDocSanitizer.forSave(doc);
      expect([for (final b in saved.blocks) b.id], ['i2', 's2', 't', 'p']);
      expect((saved.blocks[2] as RCodeTabs).tabs.single, const RCodeTab(label: 'plaintext', lang: 'plaintext', code: 'x'));
      expect((saved.blocks[3] as RParagraph).content, const [RText('ab')]);
    });
  });
}
