import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/bidi/bidi.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/widgets/reader_widgets.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  testWidgets('isolates the author handle so "@" stays with it in Arabic', (tester) async {
    final article = ArticleDetails(
      card: sampleCard(0),
      availableLanguages: const ['ar-EG'],
      content: const RDocDocument(version: 1, language: 'ar-EG', blocks: []),
    );

    await tester.pumpWidget(testApp(
      SingleChildScrollView(child: ArticleHeader(article: article, titleScale: 1)),
      variant: Variant.all.first,
    ));

    expect(find.textContaining('${Bidi.ltrIsolate('@editorial')} · '), findsOneWidget);
  });
}
