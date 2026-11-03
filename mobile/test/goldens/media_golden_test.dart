@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/article/presentation/cubit/attachment_viewer_cubit.dart';
import 'package:readin/features/article/presentation/widgets/article_card_tile.dart';
import 'package:readin/features/article/presentation/widgets/attachment_viewers.dart';
import 'package:readin/features/editor/presentation/cubit/composer_cubit.dart';
import 'package:readin/features/editor/presentation/pages/editor_page.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/media/presentation/cubit/attachments_cubit.dart';
import 'package:readin/features/taxonomy/domain/entities/field.dart';

import '../helpers/fake_media.dart';
import '../helpers/media_fixtures.dart';
import '../helpers/test_app.dart';

class MockComposerCubit extends MockCubit<ComposerState> implements ComposerCubit {}

class MockAttachmentsCubit extends MockCubit<AttachmentsState> implements AttachmentsCubit {}

class MockAttachmentViewerCubit extends MockCubit<AttachmentViewerState> implements AttachmentViewerCubit {}

const _fields = [
  Field(id: 'f-sw', slug: 'software', nameAr: 'برمجة', nameEn: 'Software', requiresSources: true),
  Field(id: 'f-ai', slug: 'ai', nameAr: 'الذكاء الاصطناعي', nameEn: 'AI'),
];

ComposerState _composer(String language) => ComposerState(
      fieldsLoading: false,
      fields: _fields,
      fieldId: 'f-sw',
      language: language,
      title: 'إزاي تختار بين Transient و Scoped في ASP.NET Core؟',
      body: 'لو انت شغال بـ ASP.NET Core، أكيد شفت الـ lifetimes التلاتة.\n\nفي المنشور ده هنقارن بينهم بأمثلة من مشروع حقيقي.',
      sources: const [SourceDraft(key: 1, title: 'ASP.NET Core docs', url: 'https://learn.microsoft.com/aspnet/core')],
    );

final _imagesState = AttachmentsState(images: [
  ImageDraft(
    localId: 'l1',
    file: sampleImageFile,
    phase: UploadPhase.ready,
    asset: imageAsset('a1'),
    altText: 'Program.cs',
    caption: 'تسجيل الـ services',
  ),
  ImageDraft(localId: 'l2', file: sampleImageFile2, phase: UploadPhase.ready, asset: imageAsset('a2')),
  const ImageDraft(localId: 'l3', file: PickedMediaFile(path: '/tmp/photo-3.jpg', name: 'photo-3.jpg'), phase: UploadPhase.uploading, progress: 0.42, altText: 'Swagger'),
  const ImageDraft(
    localId: 'l4',
    file: PickedMediaFile(path: '/tmp/photo-4.png', name: 'photo-4.png'),
    phase: UploadPhase.failed,
    failure: Failure(FailureCodes.networkOffline),
    altText: 'diagram',
  ),
]);

AttachmentsState _pdfState({required bool ready}) => AttachmentsState(
      document: DocumentDraft(
        localId: 'd1',
        file: samplePdfFile,
        title: 'Clean Architecture notes',
        allowDownload: ready,
        phase: ready ? UploadPhase.ready : UploadPhase.processing,
        asset: documentAsset(status: ready ? MediaStatus.ready : MediaStatus.processing, pagesReady: ready ? 12 : 3),
      ),
    );

/// Composer, feed cards and the full-screen viewer in ar/en × light/dark
/// (SPEC §8.2). Images come from [FakeMedia] so the pixels are deterministic.
void main() {
  setUpAll(FakeMedia.install);

  Future<void> pumpComposer(WidgetTester tester, Variant variant, AttachmentsState attachments) async {
    usePhoneSurface(tester, size: const Size(390, 1640));
    final composer = MockComposerCubit();
    final attachmentsCubit = MockAttachmentsCubit();
    whenListen(composer, const Stream<ComposerState>.empty(), initialState: _composer(variant.locale.languageCode == 'en' ? 'en' : 'ar-EG'));
    whenListen(attachmentsCubit, const Stream<AttachmentsState>.empty(), initialState: attachments);
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<ComposerCubit>.value(value: composer),
          BlocProvider<AttachmentsCubit>.value(value: attachmentsCubit),
        ],
        child: const EditorView(),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

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

  for (final variant in Variant.all) {
    final language = variant.locale.languageCode == 'en' ? 'en' : 'ar-EG';

    testWidgets('composer with images ${variant.name}', (tester) async {
      await pumpComposer(tester, variant, _imagesState);
      await expectLater(find.byType(EditorView), matchesGoldenFile('goldens/composer_images_${variant.name}.png'));
    });

    testWidgets('composer with a processing PDF ${variant.name}', (tester) async {
      await pumpComposer(tester, variant, _pdfState(ready: false));
      await expectLater(find.byType(EditorView), matchesGoldenFile('goldens/composer_pdf_processing_${variant.name}.png'));
    });

    testWidgets('composer with a ready PDF ${variant.name}', (tester) async {
      await pumpComposer(tester, variant, _pdfState(ready: true));
      await expectLater(find.byType(EditorView), matchesGoldenFile('goldens/composer_pdf_ready_${variant.name}.png'));
    });

    testWidgets('feed card with an image carousel ${variant.name}', (tester) async {
      await pumpCard(tester, variant, ArticleCardTile(article: cardWithImages(3, language: language), onTap: () {}), height: 600);
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/feed_card_images_${variant.name}.png'));
    });

    testWidgets('feed card with a PDF ${variant.name}', (tester) async {
      await pumpCard(tester, variant, ArticleCardTile(article: cardWithDocument(language: language), onTap: () {}));
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/feed_card_pdf_${variant.name}.png'));
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
      await expectLater(find.byType(DocumentViewerView), matchesGoldenFile('goldens/viewer_document_${variant.name}.png'));
    });
  }
}
