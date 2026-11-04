@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/article/presentation/cubit/attachment_viewer_cubit.dart';
import 'package:readin/features/article/presentation/widgets/article_card_tile.dart';
import 'package:readin/features/article/presentation/widgets/attachment_viewers.dart';

import '../helpers/fake_media.dart';
import '../helpers/media_fixtures.dart';
import '../helpers/test_app.dart';

class MockAttachmentViewerCubit extends MockCubit<AttachmentViewerState> implements AttachmentViewerCubit {}

/// Feed cards and the full-screen viewer in ar/en × light/dark (SPEC §8.2). Images come from [FakeMedia] so the
/// pixels are deterministic. The attachment bar is covered by the editor's settings sheet goldens (F05).
void main() {
  setUpAll(FakeMedia.install);

  Future<void> pumpCard(WidgetTester tester, Variant variant, Widget card, {double height = 760}) async {
    usePhoneSurface(tester, size: Size(390, height));
    await tester.pumpWidget(testApp(
      Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [card]),
          ),
        ),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  for (final variant in Variant.golden) {
    final language = variant.locale.languageCode == 'en' ? 'en' : 'ar-EG';

    testWidgets('feed card with an image carousel ${variant.name}', (tester) async {
      await pumpCard(tester, variant, ArticleCardTile(article: cardWithImages(3, language: language), onTap: () {}), height: 600);
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/feed_card_images_${variant.name}.png'));
    });

    testWidgets('feed card with a PDF ${variant.name}', (tester) async {
      await pumpCard(tester, variant, ArticleCardTile(article: cardWithDocument(language: language), onTap: () {}));
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/feed_card_pdf_${variant.name}.png'));
    });

    testWidgets('full-screen document viewer ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      final document = sampleDocument(pages: 12);
      final viewer = MockAttachmentViewerCubit();
      whenListen(viewer, const Stream<AttachmentViewerState>.empty(), initialState: AttachmentViewerState(document: document));
      await tester.pumpWidget(testApp(
        BlocProvider<AttachmentViewerCubit>.value(
          value: viewer,
          child: DocumentViewerView(document: document, initialIndex: 4),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(DocumentViewerView), matchesVariantGolden(variant, 'goldens/viewer_document_${variant.name}.png'));
    });
  }
}
