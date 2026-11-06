@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/widgets/article_menu.dart';
import 'package:readin/features/article_pdf/presentation/cubit/article_pdf_cubit.dart';
import 'package:readin/features/article_pdf/presentation/widgets/article_pdf_widgets.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/editor/presentation/cubit/my_articles_cubit.dart';
import 'package:readin/features/editor/presentation/pages/my_articles_page.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../helpers/editor_fixtures.dart';
import '../helpers/fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class _MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

/// "Download PDF" (SPEC F33), ar/light and en/dark: in My articles → Published, the language question for an article
/// with two published versions and an article whose PDF is being prepared; in the reader, the "⋯" menu (F28) on your
/// own article with "تنزيل PDF".
void main() {
  setUpAll(() => registerFallbackValue(ArticleLifecycle.draft));

  Future<void> pumpPublished(WidgetTester tester, Variant variant, {ArticlePdfState pdf = const ArticlePdfState(), Size? size}) async {
    usePhoneSurface(tester, size: size ?? const Size(390, 844));
    final articles = MockMyArticlesCubit();
    whenListen(
      articles,
      const Stream<MyArticlesState>.empty(),
      initialState: MyArticlesState(
        published: MyArticlesTab(status: MyArticlesStatus.ready, items: sampleMyArticles(ArticleLifecycle.published)),
      ),
    );
    when(() => articles.ensureLoaded(any())).thenAnswer((_) async {});
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<MyArticlesCubit>.value(value: articles),
          BlocProvider<ArticlePdfCubit>.value(value: articlePdfCubit(pdf)),
        ],
        child: const MyArticlesView(initialTab: 1),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  for (final variant in Variant.golden) {
    testWidgets('which version? ${variant.name}', (tester) async {
      await pumpPublished(tester, variant);
      await tester.tap(find.byKey(const ValueKey('my-article-pdf-p1')));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesVariantGolden(variant, 'goldens/article_pdf_language_${variant.name}.png'));
    });

    testWidgets("the reader's menu on your own article ${variant.name}", (tester) async {
      usePhoneSurface(tester, size: const Size(390, 360));
      // sampleCard's writer is editorial: signed in as them.
      const writer = Me(id: 'a-1', displayName: 'ReadIn Editorial', username: 'editorial');
      final article = ArticleDetails(
        card: sampleCard(1, language: variant.locale.languageCode == 'en' ? 'en' : 'ar-EG'),
        availableLanguages: const ['ar-EG', 'en'],
        content: RDocDocument.empty,
      );
      final session = MockSessionCubit();
      whenListen(session, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: writer));
      final articleCubit = _MockArticleCubit();
      whenListen(articleCubit, const Stream<ArticleState>.empty(), initialState: ArticleState(status: ArticleStatus.ready, article: article));
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<ArticleCubit>.value(value: articleCubit),
            BlocProvider<ArticlePdfCubit>.value(value: articlePdfCubit()),
          ],
          child: ArticlePdfFeedback(
            child: Scaffold(body: Align(alignment: AlignmentDirectional.topEnd, child: ArticleMenuButton(article: article))),
          ),
        ),
        variant: variant,
      ));
      await tester.pump();
      await tester.tap(find.byType(PopupMenuButton<ArticleMenuItem>));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesVariantGolden(variant, 'goldens/article_pdf_menu_${variant.name}.png'));
    });

    testWidgets('preparing the PDF ${variant.name}', (tester) async {
      await pumpPublished(tester, variant, pdf: const ArticlePdfState(building: {'p1'}), size: const Size(390, 600));
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(find.byType(MyArticlesView), matchesVariantGolden(variant, 'goldens/article_pdf_building_${variant.name}.png'));
    });
  }
}
