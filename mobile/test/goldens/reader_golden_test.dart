@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../helpers/test_app.dart';

/// RDoc rendering (mixed Arabic/English, callouts, code, tables) in the 4
/// variants. Image/embed blocks are left out: they need the network.
void main() {
  final json = readSharedJson('rdoc/examples/kitchen-sink.ar-EG.json');
  final document = RDocDocument.fromJson(json);
  final offline = RDocDocument(
    version: document.version,
    language: document.language,
    blocks: document.blocks.where((b) => b is! RImage && b is! REmbed).toList(),
  );

  for (final variant in Variant.golden) {
    testWidgets('reader ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 2900));
      await tester.pumpWidget(testApp(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: RDocScope(
              baseDirection: RDocScope.directionForLanguage(offline.language),
              child: RDocColumn(offline),
            ),
          ),
        ),
        variant: variant,
      ));
      await tester.pump();

      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/reader_${variant.name}.png'));
    });
  }
}
