import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/bidi/bidi.dart';
import 'package:readin/shared/rdoc/rdoc_text.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../../helpers/test_app.dart';

void main() {
  final document = RDocDocument.fromJson(readSharedJson('rdoc/examples/kitchen-sink.ar-EG.json'));

  Future<void> pumpDocument(WidgetTester tester) async {
    usePhoneSurface(tester, size: const Size(390, 6000));
    await tester.pumpWidget(testApp(
      Scaffold(
        body: SingleChildScrollView(
          child: RDocScope(
            baseDirection: RDocScope.directionForLanguage(document.language),
            child: RDocColumn(document),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  test('parses every block type in the kitchen-sink example', () {
    expect(document.language, 'ar-EG');
    expect(document.blocks.map((b) => b.type).toSet(), {
      'summary', 'paragraph', 'heading', 'bulletList', 'orderedList', 'steps', 'callout',
      'code', 'codeTabs', 'table', 'quote', 'image', 'divider', 'embed',
    });
  });

  testWidgets('renders every block of the kitchen-sink example', (tester) async {
    await pumpDocument(tester);
    for (final block in document.blocks) {
      expect(find.byKey(ValueKey('rdoc-${block.type}-${block.id}')), findsOneWidget, reason: block.type);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('code blocks are LTR inside an RTL article', (tester) async {
    await pumpDocument(tester);
    final panels = find.byKey(const ValueKey('rdoc-code-panel'));
    expect(panels, findsNWidgets(2)); // code + codeTabs
    for (final element in panels.evaluate()) {
      expect(Directionality.of(element), TextDirection.ltr);
    }
    expect(find.textContaining('AddScoped<IOrderService, OrderService>', findRichText: true), findsOneWidget);
  });

  testWidgets('Arabic paragraphs are RTL and wrap English runs in isolates', (tester) async {
    await pumpDocument(tester);
    final paragraph = find.descendant(of: find.byKey(const ValueKey('rdoc-paragraph-p1')), matching: find.byType(RDocText));
    expect(tester.widget<RDocText>(paragraph).direction, TextDirection.rtl);

    final rich = tester.widget<RichText>(find.descendant(of: paragraph, matching: find.byType(RichText)));
    final plain = rich.text.toPlainText();
    expect(plain, contains('${Bidi.fsi}ASP.NET Core${Bidi.pdi}'));
    expect(plain, contains('${Bidi.fsi}Dependency Injection${Bidi.pdi}'));
  });

  testWidgets('code tabs switch content', (tester) async {
    await pumpDocument(tester);
    await tester.tap(find.text('Dart'));
    await tester.pump();
    expect(find.textContaining('abstract interface class Clock', findRichText: true), findsOneWidget);
  });
}
