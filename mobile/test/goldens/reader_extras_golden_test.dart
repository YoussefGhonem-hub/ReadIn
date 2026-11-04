@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/pages/article_page.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';

/// The reader's step 6.6 parts in ar/light and en/dark (the other two variants lay out the same screen): the health
/// disclaimer of a sensitive field with the tags at the end, and the table of contents opened.
void main() {
  const medicine = FieldRef(id: 'f-med', slug: 'medicine', nameAr: 'طب', nameEn: 'Medicine', isSensitive: true);

  Map<String, dynamic> text(String type, String id, String value, {int? level}) => {
        'type': type,
        'id': id,
        'level': ?level,
        'content': [
          {'type': 'text', 'text': value},
        ],
      };

  ArticleDetails details(Variant variant, {required bool sections}) {
    final ar = variant.locale.languageCode == 'ar';
    final language = ar ? 'ar-EG' : 'en';
    final headings = ar
        ? ['يعني إيه ضغط الدم العالي؟', 'إزاي تقيسه في البيت', 'إمتى تروح للدكتور']
        : ['What high blood pressure is', 'How to measure it at home', 'When to see a doctor'];
    final body = ar
        ? 'ضغط الدم العالي مشكلة شائعة ومن غير أعراض واضحة في الأول، عشان كده القياس المنتظم مهم.'
        : 'High blood pressure is common and often has no clear symptoms at first, so measuring it regularly matters.';
    return ArticleDetails(
      card: ArticleCard(
        id: 'art-med',
        slug: 'blood-pressure',
        language: language,
        title: ar ? 'ضغط الدم العالي: تعرف عليه بدري' : 'High blood pressure: catch it early',
        field: medicine,
        author: editorial,
        readingTimeMinutes: 6,
        publishedAt: DateTime.utc(2026, 10, 12),
      ),
      availableLanguages: [language],
      content: RDocDocument.fromJson({
        'version': 1,
        'language': language,
        'blocks': [
          text('paragraph', 'p0', body),
          if (sections)
            for (var i = 0; i < headings.length; i++) ...[
              text('heading', 'h$i', headings[i], level: i == 1 ? 3 : 2),
              text('paragraph', 'p${i + 1}', body),
            ],
        ],
      }),
      tags: ar ? const ['صحة', 'blood-pressure'] : const ['health', 'blood-pressure'],
      sources: const [ArticleSource(title: 'WHO: Hypertension', url: 'https://www.who.int/news-room/fact-sheets/detail/hypertension')],
    );
  }

  Future<void> pump(WidgetTester tester, Variant variant, ArticleDetails article, {double height = 844}) async {
    usePhoneSurface(tester, size: Size(390, height));
    await tester.pumpWidget(testApp(Scaffold(body: ReaderBody(article: article, bodyFontSize: 17)), variant: variant));
    await tester.pump();
  }

  for (final variant in Variant.golden) {
    testWidgets('reader health disclaimer and tags ${variant.name}', (tester) async {
      await pump(tester, variant, details(variant, sections: false));
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/reader_health_disclaimer_${variant.name}.png'));
    });

    testWidgets('reader table of contents ${variant.name}', (tester) async {
      await pump(tester, variant, details(variant, sections: true), height: 1100);
      await tester.tap(find.text(variant.locale.languageCode == 'ar' ? 'محتويات المقال' : 'In this article'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/reader_toc_${variant.name}.png'));
    });
  }
}
