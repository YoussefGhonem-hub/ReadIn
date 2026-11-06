@Tags(['golden'])
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/quote_card/domain/entities/quote_card.dart';
import 'package:readin/features/quote_card/presentation/cubit/quote_card_cubit.dart';
import 'package:readin/features/quote_card/presentation/widgets/quote_card_sheet.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../helpers/fixtures.dart';
import '../helpers/quote_card_fakes.dart';
import '../helpers/test_app.dart';

/// The quote card (F24) in ar/light and en/dark (SPEC §27): Share quote in the selection toolbar, and the sheet with
/// the card the API drew (the backend's own baselines: Arabic light square, English dark landscape), while it is drawn,
/// and offline with "Try again".
void main() {
  final fixtures = readSharedJson('rdoc/highlight-fixtures.json');
  final raw = fixtures['documents'] as Map<String, dynamic>;
  final ar = RDocDocument.fromJson(raw['ar'] as Map<String, dynamic>);
  final en = RDocDocument.fromJson(raw['en'] as Map<String, dynamic>);
  final arText = ar.copyWith(blocks: ar.blocks.where((b) => RBlockText.of(b) != null).toList());

  final arCard = quoteCardFixture('card-ar-light-square.png');
  final enCard = quoteCardFixture('card-en-dark-landscape.png');

  late FakeQuoteCardRepository repository;

  setUp(() {
    repository = FakeQuoteCardRepository();
    getIt.registerFactory<QuoteCardCubit>(() => quoteCardCubit(repository));
  });

  tearDown(getIt.reset);

  Future<void> expectGolden(WidgetTester tester, Variant variant, String name) =>
      expectLater(find.byType(MaterialApp), matchesVariantGolden(variant, 'goldens/${name}_${variant.name}.png'));

  Finder unit(String blockId, RDocDocument doc) {
    final b = doc.blocks.firstWhere((x) => x.id == blockId);
    return find.descendant(
      of: find.descendant(of: find.byKey(ValueKey('rdoc-${b.type}-${b.id}')), matching: find.byType(RHighlightUnit)),
      matching: find.byType(RichText),
    );
  }

  Offset at(WidgetTester tester, Finder rich, int plain) {
    final paragraph = tester.renderObject<RenderParagraph>(rich.first);
    final offset = renderedOffsetsOf(paragraph.text.toPlainText())[plain];
    final boxes = paragraph.getBoxesForSelection(TextSelection(baseOffset: offset, extentOffset: offset + 1));
    return paragraph.localToGlobal(boxes.first.toRect().center);
  }

  /// A page with a button that opens the sheet on the fixture selection, in the article language of [variant].
  Future<void> pumpOpener(WidgetTester tester, Variant variant) async {
    usePhoneSurface(tester);
    final arabic = variant.locale.languageCode == 'ar';
    final article = sampleCard(1, language: arabic ? 'ar-EG' : 'en');
    const range = HighlightRange(blockId: 'p1', startOffset: 42, endOffset: 52, text: 'Dependency');
    await tester.pumpWidget(testApp(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => unawaited(showQuoteCardSheet(context, article: article, range: range)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      variant: variant,
    ));
  }

  /// Decodes [bytes] for real once, so the sheet draws it in its first frame.
  Future<void> precache(WidgetTester tester, Uint8List bytes) async {
    final context = tester.element(find.byType(Scaffold));
    await tester.runAsync(() => precacheImage(MemoryImage(bytes), context));
  }

  for (final variant in Variant.golden) {
    final arabic = variant.locale.languageCode == 'ar';

    testWidgets('Share quote in the selection toolbar ${variant.name}', (tester) async {
      final doc = arabic ? arText : en;
      usePhoneSurface(tester, size: const Size(390, 640));
      await tester.pumpWidget(testApp(
        Scaffold(
          body: RDocHighlights(
            onHighlight: (_, _) {},
            onRemove: (_, _) {},
            onShareQuote: (_, _) {},
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: RDocScope(baseDirection: RDocScope.directionForLanguage(doc.language), child: RDocColumn(doc)),
            ),
          ),
        ),
        variant: variant,
      ));
      await tester.pump();
      await tester.longPressAt(arabic ? at(tester, unit('p1', doc), 45) : at(tester, unit('e1', doc), 35));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      expect(find.text(l10n.quoteCardAction), findsOneWidget);
      await expectGolden(tester, variant, 'quote_card_toolbar');
    });

    // ar/light opens on the light square card; en/dark opens dark and switches to landscape.
    testWidgets('the sheet with the card ${variant.name}', (tester) async {
      repository.answer = (r) => Ok(QuoteCardImage(
            bytes: r.format == QuoteCardFormat.landscape || !arabic ? enCard : arCard,
            fileName: 'readin-quote-article-1.png',
          ));
      await pumpOpener(tester, variant);
      await precache(tester, arabic ? arCard : enCard);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      if (!arabic) {
        final l10n = await AppLocalizations.delegate.load(variant.locale);
        await tester.tap(find.text(l10n.quoteCardLandscape));
        await tester.pumpAndSettle();
      }
      expect(repository.requests.last.theme, arabic ? QuoteCardTheme.light : QuoteCardTheme.dark);
      await expectGolden(tester, variant, 'quote_card_sheet');
    });

    testWidgets('the sheet while the card is drawn ${variant.name}', (tester) async {
      repository.gate = Completer<void>();
      await pumpOpener(tester, variant);
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await expectGolden(tester, variant, 'quote_card_sheet_loading');
    });

    testWidgets('the sheet offline ${variant.name}', (tester) async {
      repository.answer = (_) => const Err(Failure(FailureCodes.networkOffline));
      await pumpOpener(tester, variant);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'quote_card_sheet_offline');
    });
  }
}
