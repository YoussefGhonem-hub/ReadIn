@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article_pdf/presentation/cubit/article_pdf_cubit.dart';
import 'package:readin/features/comments/presentation/cubit/mention_suggestions_cubit.dart';
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/editor/presentation/cubit/article_editor_cubit.dart';
import 'package:readin/features/editor/presentation/cubit/my_articles_cubit.dart';
import 'package:readin/features/editor/presentation/cubit/revisions_cubit.dart';
import 'package:readin/features/editor/presentation/cubit/tag_suggestions_cubit.dart';
import 'package:readin/features/editor/presentation/pages/article_editor_page.dart';
import 'package:readin/features/editor/presentation/pages/article_preview_page.dart';
import 'package:readin/features/editor/presentation/pages/my_articles_page.dart';
import 'package:readin/features/editor/presentation/pages/revisions_page.dart';
import 'package:readin/features/editor/presentation/widgets/article_settings_sheet.dart';
import 'package:readin/features/editor/presentation/widgets/editor_widgets.dart';
import 'package:readin/features/media/domain/entities/media.dart';
import 'package:readin/features/media/presentation/cubit/attachments_cubit.dart';
import 'package:readin/shared/widgets/app_network_image.dart';

import '../helpers/comment_fixtures.dart';
import '../helpers/editor_fixtures.dart';
import '../helpers/fake_media.dart';
import '../helpers/fixtures.dart';
import '../helpers/media_fixtures.dart';
import '../helpers/test_app.dart';

ArticleEditorState _editorState({AttachmentsState? attachments}) {
  final document = mixedDocument(withTranslation: true).copyWith(coverUrl: () => 'https://api.readin.test/uploads/cover/1200.webp');
  return ArticleEditorState(
    document: document,
    activeLanguage: ArticleLanguages.ar,
    loadStatus: EditorLoadStatus.ready,
    articleId: 'art-1',
    lifecycle: ArticleLifecycle.published,
    slug: 'scoped-vs-transient',
    version: 7,
    hasUnpublishedChanges: true,
    checks: const DraftChecks(readingTime: [
      ReadingTime(language: 'ar-EG', minutes: 6, words: 1080),
      ReadingTime(language: 'en', minutes: 1, words: 9),
    ]),
    checksFresh: true,
    saveStatus: SaveStatus.saved,
    sources: const [SourceDraft(key: 1, title: 'ASP.NET Core docs', url: 'https://learn.microsoft.com/aspnet/core')],
    fields: editorFields,
    topics: editorTopics,
    attachmentAssets: attachments?.assetsById ?? const {},
  );
}

final _imagesState = AttachmentsState(images: [
  ImageDraft(localId: 'l1', file: sampleImageFile, phase: UploadPhase.ready, asset: imageAsset('a1'), altText: 'Program.cs', caption: 'تسجيل الـ services'),
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

final _pdfState = AttachmentsState(
  document: DocumentDraft(
    localId: 'd1',
    file: samplePdfFile,
    title: 'Clean Architecture notes',
    phase: UploadPhase.processing,
    asset: documentAsset(status: MediaStatus.processing, pagesReady: 3),
  ),
);

/// F05 screens in ar/en × light/dark (SPEC §8.2): My articles, the editor with a mixed Arabic/English document,
/// the settings sheet (with the attachment bar), the checks, the preview and the revision history.
void main() {
  late MockMentionSuggestionsCubit mentions;
  late MockTagSuggestionsCubit tags;

  setUpAll(() async {
    registerFallbackValue(ArticleLifecycle.draft);
    await FakeMedia.install();
    AppNetworkImage.providerFactory = FakeImageProvider.new;
  });

  tearDownAll(() => AppNetworkImage.providerFactory = NetworkImage.new);

  setUp(() {
    mentions = MockMentionSuggestionsCubit();
    whenListen(mentions, const Stream<List<Author>>.empty(), initialState: const <Author>[]);
    when(() => mentions.search(any())).thenReturn(null);
    tags = MockTagSuggestionsCubit();
    whenListen(tags, const Stream<List<ArticleTag>>.empty(), initialState: const <ArticleTag>[]);
  });

  MockArticleEditorCubit editorCubit(ArticleEditorState state) {
    final cubit = MockArticleEditorCubit();
    whenListen(cubit, const Stream<ArticleEditorState>.empty(), initialState: state);
    return cubit;
  }

  MockAttachmentsCubit attachmentsCubit(AttachmentsState state) {
    final cubit = MockAttachmentsCubit();
    whenListen(cubit, const Stream<AttachmentsState>.empty(), initialState: state);
    return cubit;
  }

  for (final variant in Variant.golden) {
    testWidgets('my articles ${variant.name}', (tester) async {
      usePhoneSurface(tester);
      final cubit = MockMyArticlesCubit();
      whenListen(
        cubit,
        const Stream<MyArticlesState>.empty(),
        initialState: MyArticlesState(
          drafts: MyArticlesTab(status: MyArticlesStatus.ready, items: sampleMyArticles(ArticleLifecycle.draft)),
          published: MyArticlesTab(status: MyArticlesStatus.ready, items: sampleMyArticles(ArticleLifecycle.published)),
        ),
      );
      when(() => cubit.ensureLoaded(any())).thenAnswer((_) async {});
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<MyArticlesCubit>.value(value: cubit),
            BlocProvider<ArticlePdfCubit>.value(value: articlePdfCubit()),
          ],
          child: const MyArticlesView(),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(MyArticlesView), matchesVariantGolden(variant, 'goldens/editor_my_articles_${variant.name}.png'));
    });

    testWidgets('my articles, published ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 600));
      final cubit = MockMyArticlesCubit();
      whenListen(
        cubit,
        const Stream<MyArticlesState>.empty(),
        initialState: MyArticlesState(
          published: MyArticlesTab(status: MyArticlesStatus.ready, items: sampleMyArticles(ArticleLifecycle.published)),
        ),
      );
      when(() => cubit.ensureLoaded(any())).thenAnswer((_) async {});
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<MyArticlesCubit>.value(value: cubit),
            BlocProvider<ArticlePdfCubit>.value(value: articlePdfCubit()),
          ],
          child: const MyArticlesView(initialTab: 1),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(MyArticlesView), matchesVariantGolden(variant, 'goldens/editor_my_articles_published_${variant.name}.png'));
    });

    testWidgets('editor ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 2300));
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<ArticleEditorCubit>.value(value: editorCubit(_editorState())),
            BlocProvider<AttachmentsCubit>.value(value: attachmentsCubit(const AttachmentsState())),
            BlocProvider<MentionSuggestionsCubit>.value(value: mentions),
            BlocProvider<TagSuggestionsCubit>.value(value: tags),
          ],
          child: const ArticleEditorView(),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(ArticleEditorView), matchesVariantGolden(variant, 'goldens/editor_${variant.name}.png'));
    });

    for (final (name, attachments) in [('images', _imagesState), ('pdf', _pdfState)]) {
      testWidgets('settings sheet with $name ${variant.name}', (tester) async {
        usePhoneSurface(tester, size: const Size(390, 2500));
        await tester.pumpWidget(testApp(
          MultiBlocProvider(
            providers: [
              BlocProvider<ArticleEditorCubit>.value(value: editorCubit(_editorState(attachments: attachments))),
              BlocProvider<AttachmentsCubit>.value(value: attachmentsCubit(attachments)),
              BlocProvider<TagSuggestionsCubit>.value(value: tags),
            ],
            child: const Scaffold(body: SafeArea(child: ArticleSettingsPanel())),
          ),
          variant: variant,
        ));
        await tester.pump();
        await expectLater(find.byType(ArticleSettingsPanel), matchesVariantGolden(variant, 'goldens/editor_settings_${name}_${variant.name}.png'));
      });
    }

    testWidgets('checks ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 640));
      final state = ArticleEditorState(
        document: mixedDocument(withTranslation: true, complete: false),
        activeLanguage: ArticleLanguages.ar,
        loadStatus: EditorLoadStatus.ready,
        dirty: true,
        uploads: 1,
        fields: editorFields,
        checks: const DraftChecks(
          readingTime: [ReadingTime(language: 'ar-EG', minutes: 6), ReadingTime(language: 'en', minutes: 1)],
          problems: [DraftProblem(DraftProblemCodes.contentInvalid, language: 'en')],
        ),
      );
      await tester.pumpWidget(testApp(
        Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ChecksList(state: state, onProblem: (_) {}),
            ),
          ),
          bottomNavigationBar: ChecksStrip(state: state, onOpen: () {}),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/editor_checks_${variant.name}.png'));
    });

    testWidgets('preview ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 2600));
      final document = mixedDocument(withTranslation: true).copyWith(
        coverUrl: () => 'https://api.readin.test/uploads/cover/1200.webp',
        attachments: const [AttachmentItem(mediaAssetId: 'a1', order: 0, altText: 'Program.cs', caption: 'تسجيل الـ services')],
      );
      await tester.pumpWidget(testApp(
        ArticlePreviewPage(
          data: PreviewData(
            document: document,
            author: editorial,
            media: [imageAsset('a1')],
            field: editorFields.first,
            topic: editorTopics.first,
            readingTime: const [ReadingTime(language: 'ar-EG', minutes: 6)],
            publishedAt: DateTime.utc(2026, 10, 20, 9),
          ),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(ArticlePreviewPage), matchesVariantGolden(variant, 'goldens/editor_preview_${variant.name}.png'));
    });

    testWidgets('revisions ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 600));
      final cubit = MockRevisionsCubit();
      whenListen(cubit, const Stream<RevisionsState>.empty(), initialState: RevisionsState(status: RevisionsStatus.ready, revisions: sampleRevisions));
      await tester.pumpWidget(testApp(
        BlocProvider<RevisionsCubit>.value(
          value: cubit,
          child: RevisionsPage(author: editorial, onRestore: (_) async => true),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(RevisionsPage), matchesVariantGolden(variant, 'goldens/editor_revisions_${variant.name}.png'));
    });
  }
}
