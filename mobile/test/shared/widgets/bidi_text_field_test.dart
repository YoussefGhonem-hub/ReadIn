import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/shared/widgets/bidi_text_field.dart';

void main() {
  Future<TextEditingController> pump(WidgetTester tester, String text) async {
    final controller = TextEditingController(text: text);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: BidiTextField(controller: controller, maxLength: 5000, counterWithin: 500, maxLines: 6)),
    ));
    return controller;
  }

  testWidgets('long limits show the counter only near the limit', (tester) async {
    final controller = await pump(tester, 'short');
    expect(find.text('5/5000'), findsNothing);

    controller.text = 'x' * 4499;
    await tester.pump();
    expect(find.text('4499/5000'), findsNothing);

    controller.text = 'x' * 4500;
    await tester.pump();
    expect(find.text('4500/5000'), findsOneWidget);
  });

  testWidgets('the limit still applies', (tester) async {
    await pump(tester, '');

    await tester.enterText(find.byType(TextField), 'y' * 6000);
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, hasLength(5000));
  });
}
