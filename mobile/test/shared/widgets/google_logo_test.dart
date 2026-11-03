import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/shared/widgets/google_logo.dart';

void main() {
  testWidgets('paints the logo at the requested size', (tester) async {
    await tester.pumpWidget(const Center(child: GoogleLogo(size: 24)));

    expect(tester.getSize(find.byType(GoogleLogo)), const Size.square(24));
    expect(find.descendant(of: find.byType(GoogleLogo), matching: find.byType(CustomPaint)), findsOneWidget);
  });
}
