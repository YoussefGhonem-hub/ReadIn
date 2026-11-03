import 'package:flutter_test/flutter_test.dart';
import 'package:readin/shared/rdoc/rdoc_builder.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

void main() {
  test('blank lines split paragraphs; single newlines become hard breaks', () {
    final json = RDocBuilder.fromPlainText(
      'أول فقرة عن الـ DI.\r\n  \r\nتاني فقرة\nبسطر تاني.\n\n\n\nThird paragraph.  ',
      language: 'ar-EG',
    );
    expect(json['version'], 1);
    expect(json['language'], 'ar-EG');
    final blocks = json['blocks'] as List;
    expect(blocks, hasLength(3));
    expect(blocks.first, {
      'id': 'p1',
      'type': 'paragraph',
      'dir': 'auto',
      'content': [
        {'type': 'text', 'text': 'أول فقرة عن الـ DI.'},
      ],
    });
    expect((blocks[1] as Map)['content'], [
      {'type': 'text', 'text': 'تاني فقرة'},
      {'type': 'hardBreak'},
      {'type': 'text', 'text': 'بسطر تاني.'},
    ]);

    // Round-trips through the reader's parser.
    final doc = RDocDocument.fromJson(json);
    expect(doc.blocks.whereType<RParagraph>().map((p) => p.id), ['p1', 'p2', 'p3']);
    expect(plainTextOf((doc.blocks[2] as RParagraph).content), 'Third paragraph.');
  });

  test('empty text has no blocks; long runs are split under the schema limit', () {
    expect(RDocBuilder.fromPlainText(' \n\n ', language: 'en')['blocks'], isEmpty);
    final long = RDocBuilder.fromPlainText('x' * (RDocBuilder.maxTextLength + 5), language: 'en');
    final content = ((long['blocks'] as List).single as Map)['content'] as List;
    expect(content.map((n) => ((n as Map)['text'] as String).length), [RDocBuilder.maxTextLength, 5]);
  });
}
