import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/pages/article_page.dart';
import 'package:readin/features/article/presentation/widgets/article_toc.dart';
import 'package:readin/features/article/presentation/widgets/reader_widgets.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

const _en = Variant(AppLocales.en, Brightness.light);

const medicine = FieldRef(id: 'f-med', slug: 'medicine', nameAr: 'طب', nameEn: 'Medicine', isSensitive: true);

Map<String, dynamic> _paragraph(String id, String text) => {
      'type': 'paragraph',
      'id': id,
      'content': [
        {'type': 'text', 'text': text},
      ],
    };

Map<String, dynamic> _heading(String id, String text, {int level = 2}) => {
      'type': 'heading',
      'id': id,
      'level': level,
      'content': [
        {'type': 'text', 'text': text},
      ],
    };

/// An English document: [headings] h2s, each followed by [paragraphsPerSection] paragraphs.
RDocDocument document({int headings = 3, int paragraphsPerSection = 1}) => RDocDocument.fromJson({
      'version': 1,
      'language': 'en',
      'blocks': [
        for (var h = 1; h <= headings; h++) ...[
          _heading('h$h', 'Heading number $h', level: h == 2 ? 3 : 2),
          for (var p = 1; p <= paragraphsPerSection; p++)
            _paragraph('p$h-$p', 'Section $h, paragraph $p. Dependency injection keeps the parts of an app apart, '
                'so each one can be tested and replaced on its own.'),
        ],
      ],
    });

ArticleDetails article({
  FieldRef field = dotnetField,
  RDocDocument? content,
  List<String> tags = const [],
  String? summary,
}) =>
    ArticleDetails(
      card: ArticleCard(
        id: 'art-1',
        slug: 'article-1',
        language: 'en',
        title: 'What dependency injection is',
        field: field,
        author: editorial,
        readingTimeMinutes: 5,
        publishedAt: DateTime.utc(2026, 10, 12),
      ),
      availableLanguages: const ['en'],
      content: content ?? document(headings: 0),
      tags: tags,
      summary: summary,
    );

Future<void> pumpBody(WidgetTester tester, ArticleDetails article, {Size size = const Size(390, 844)}) async {
  usePhoneSurface(tester, size: size);
  await tester.pumpWidget(testApp(Scaffold(body: ReaderBody(article: article, bodyFontSize: 17)), variant: _en));
  await tester.pump();
}

void main() {
  group('health disclaimer (SPEC F04)', () {
    const text = "This information is for awareness only and is not a substitute for a doctor's advice.";

    testWidgets('an article in a sensitive field shows it under the trust row, above the TL;DR', (tester) async {
      await pumpBody(tester, article(field: medicine, summary: 'Short version.'), size: const Size(390, 1200));

      expect(find.byType(HealthDisclaimer), findsOneWidget);
      expect(find.text(text), findsOneWidget);
      final title = tester.getTopLeft(find.text('What dependency injection is')).dy;
      final box = tester.getTopLeft(find.byType(HealthDisclaimer)).dy;
      final summary = tester.getTopLeft(find.text('Short version.')).dy;
      expect(title < box && box < summary, isTrue, reason: 'header, disclaimer, TL;DR');
    });

    testWidgets('other fields have none', (tester) async {
      await pumpBody(tester, article());
      expect(find.byType(HealthDisclaimer), findsNothing);
    });
  });

  group('table of contents (F04)', () {
    testWidgets('only from 3 headings, collapsed until opened', (tester) async {
      await pumpBody(tester, article(content: document(headings: 2)));
      expect(find.byType(ArticleToc), findsNothing);

      await pumpBody(tester, article(content: document()));
      expect(find.text('In this article'), findsOneWidget);
      expect(find.descendant(of: find.byType(ArticleToc), matching: find.text('Heading number 1')), findsNothing);

      await tester.tap(find.text('In this article'));
      await tester.pumpAndSettle();
      for (var h = 1; h <= 3; h++) {
        expect(find.descendant(of: find.byType(ArticleToc), matching: find.text('Heading number $h')), findsOneWidget);
      }
    });

    test('lists the h2 and h3 headings in order', () {
      expect(tableOfContents(document()), [
        (blockId: 'h1', level: 2, text: 'Heading number 1'),
        (blockId: 'h2', level: 3, text: 'Heading number 2'),
        (blockId: 'h3', level: 2, text: 'Heading number 3'),
      ]);
    });

    testWidgets('a heading far down, not built yet, scrolls to the top of the reader', (tester) async {
      await pumpBody(tester, article(content: document(paragraphsPerSection: 40)));
      final target = find.byKey(const ValueKey('rdoc-heading-h3'), skipOffstage: false);
      expect(target, findsNothing, reason: 'the reader builds blocks lazily');

      await tester.tap(find.text('In this article'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(ArticleToc), matching: find.text('Heading number 3')));
      await tester.pumpAndSettle();

      expect(target, findsOneWidget);
      expect(tester.getTopLeft(target).dy, moreOrLessEquals(0, epsilon: 1));
    });

    testWidgets('and back up to an earlier one', (tester) async {
      await pumpBody(tester, article(content: document(paragraphsPerSection: 40)));
      await tester.tap(find.text('In this article'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(ArticleToc), matching: find.text('Heading number 3')));
      await tester.pumpAndSettle();
      final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      final scrolled = position.pixels;

      // Back at the top, the table of contents is still open.
      position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(ArticleToc), matching: find.text('Heading number 2')));
      await tester.pumpAndSettle();

      final target = find.byKey(const ValueKey('rdoc-heading-h2'));
      expect(tester.getTopLeft(target).dy, moreOrLessEquals(0, epsilon: 1));
      expect(position.pixels, lessThan(scrolled));
    });
  });

  testWidgets('tags show as plain chips under the content (F04)', (tester) async {
    await pumpBody(tester, article(tags: const ['csharp', 'di']), size: const Size(390, 1200));
    expect(find.byType(ArticleTags), findsOneWidget);
    expect(find.text('#csharp'), findsOneWidget);
    expect(find.text('#di'), findsOneWidget);
    expect(find.ancestor(of: find.text('#csharp'), matching: find.byType(InkWell)), findsNothing, reason: 'not tappable');
  });

  testWidgets("an @mention in the content opens that user's profile (F14)", (tester) async {
    final opened = <String>[];
    final content = RDocDocument.fromJson({
      'version': 1,
      'language': 'en',
      'blocks': [
        {
          'type': 'paragraph',
          'id': 'p1',
          'content': [
            {'type': 'text', 'text': 'Thanks to '},
            {'type': 'mention', 'userId': 'u-9', 'text': '@mona_dev'},
            {'type': 'text', 'text': ' for the review.'},
          ],
        },
      ],
    });
    final router = GoRouter(
      initialLocation: '/a/article-1',
      routes: [
        GoRoute(path: '/a/:slug', builder: (_, _) => Scaffold(body: ReaderBody(article: article(content: content), bodyFontSize: 17))),
        GoRoute(
          path: '/u/:username',
          builder: (_, state) {
            opened.add(state.pathParameters['username']!);
            return const Text('profile page');
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      locale: AppLocales.en,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(AppLocales.en),
      routerConfig: router,
    ));
    await tester.pumpAndSettle();

    TextSpan? mention;
    for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
      text.text.visitChildren((span) {
        if (span is TextSpan && span.text == '@mona_dev') mention = span;
        return mention == null;
      });
    }
    expect(mention?.recognizer, isA<TapGestureRecognizer>());
    (mention!.recognizer! as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();

    expect(opened, ['mona_dev']);
    expect(find.text('profile page'), findsOneWidget);
  });
}
