import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/platform/share_service.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/widgets/article_menu.dart';
import 'package:readin/features/article_pdf/domain/entities/article_pdf.dart';
import 'package:readin/features/article_pdf/domain/repositories/article_pdf_repository.dart';
import 'package:readin/features/article_pdf/domain/usecases/download_article_pdf.dart';
import 'package:readin/features/article_pdf/presentation/cubit/article_pdf_cubit.dart';
import 'package:readin/features/article_pdf/presentation/widgets/article_pdf_widgets.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/editor/presentation/cubit/my_articles_cubit.dart';
import 'package:readin/features/editor/presentation/pages/my_articles_page.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../../helpers/editor_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/moderation_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class _FakeRepository implements ArticlePdfRepository {
  final calls = <(String, String)>[];
  Completer<Result<ArticlePdf>>? pending;
  Result<ArticlePdf> answer = const Ok(ArticlePdf(path: '/tmp/article-pdf/di-in-dotnet-en.pdf', fileName: 'di-in-dotnet-en.pdf'));

  @override
  Future<Result<ArticlePdf>> download(String articleId, {required String language}) {
    calls.add((articleId, language));
    return pending?.future ?? Future.value(answer);
  }
}

class _MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

class _RecordingShare extends ShareService {
  final files = <({String path, String? fileName})>[];

  @override
  Future<void> shareFile(String path, {required String mimeType, String? fileName, Rect? origin}) async =>
      files.add((path: path, fileName: fileName));
}

const _en = Variant(AppLocales.en, Brightness.light);

/// "Download PDF" in My articles → Published (SPEC F05, F33): one version goes straight on, two ask which, the item
/// shows "Preparing the PDF…" while the API builds it, and failures explain themselves with "Try again". In the
/// reader's "⋯" menu, every member has it on every article they can open; guests get the sign-in prompt.
void main() {
  late _FakeRepository repository;
  late _RecordingShare share;
  late ArticlePdfCubit pdf;

  setUpAll(() => registerFallbackValue(ArticleLifecycle.draft));

  setUp(() {
    repository = _FakeRepository();
    share = _RecordingShare();
    pdf = ArticlePdfCubit(DownloadArticlePdf(repository), share);
  });

  tearDown(() => pdf.close());

  Future<void> pump(WidgetTester tester, {Variant variant = _en, int tab = 1}) async {
    usePhoneSurface(tester);
    final articles = MockMyArticlesCubit();
    whenListen(
      articles,
      const Stream<MyArticlesState>.empty(),
      initialState: MyArticlesState(
        drafts: MyArticlesTab(status: MyArticlesStatus.ready, items: sampleMyArticles(ArticleLifecycle.draft)),
        published: MyArticlesTab(status: MyArticlesStatus.ready, items: sampleMyArticles(ArticleLifecycle.published)),
      ),
    );
    when(() => articles.ensureLoaded(any())).thenAnswer((_) async {});
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<MyArticlesCubit>.value(value: articles),
          BlocProvider<ArticlePdfCubit>.value(value: pdf),
        ],
        child: MyArticlesView(initialTab: tab),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  Finder pdfButton(String id) => find.byKey(ValueKey('my-article-pdf-$id'));

  testWidgets('drafts have no "Download PDF"', (tester) async {
    await pump(tester, tab: 0);
    expect(find.byKey(const ValueKey('my-article-d1')), findsOneWidget);
    expect(find.text('Download PDF'), findsNothing);
    expect(pdfButton('d1'), findsNothing);
  });

  testWidgets('each published article has "Download PDF"', (tester) async {
    await pump(tester);
    expect(pdfButton('p1'), findsOneWidget);
    expect(pdfButton('p2'), findsOneWidget);
    expect(find.text('Download PDF'), findsNWidgets(2));
  });

  testWidgets('one published version: no question, the PDF opens in the share sheet', (tester) async {
    await pump(tester);
    await tester.tap(pdfButton('p2'));
    await tester.pumpAndSettle();
    expect(find.text('Which version?'), findsNothing);
    expect(repository.calls, [('p2', 'ar-EG')]);
    expect(share.files.single, (path: '/tmp/article-pdf/di-in-dotnet-en.pdf', fileName: 'di-in-dotnet-en.pdf'));
  });

  testWidgets('two published versions: asks which one, source language first', (tester) async {
    await pump(tester);
    await tester.tap(pdfButton('p1'));
    await tester.pumpAndSettle();
    expect(find.text('Which version?'), findsOneWidget);
    final arabic = tester.getTopLeft(find.byKey(const ValueKey('pdf-language-ar-EG')));
    final english = tester.getTopLeft(find.byKey(const ValueKey('pdf-language-en')));
    expect(arabic.dy, lessThan(english.dy));
    expect(find.text('Arabic'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(repository.calls, isEmpty);

    await tester.tap(find.byKey(const ValueKey('pdf-language-en')));
    await tester.pumpAndSettle();
    expect(find.text('Which version?'), findsNothing);
    expect(repository.calls, [('p1', 'en')]);
    expect(share.files, hasLength(1));
  });

  testWidgets('closing the question downloads nothing', (tester) async {
    await pump(tester);
    await tester.tap(pdfButton('p1'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 40)); // the barrier
    await tester.pumpAndSettle();
    expect(find.text('Which version?'), findsNothing);
    expect(repository.calls, isEmpty);
  });

  for (final variant in Variant.all) {
    testWidgets('while it builds: "Preparing the PDF…", a spinner, disabled ${variant.name}', (tester) async {
      repository.pending = Completer();
      await pump(tester, variant: variant);
      final l10n = lookupAppLocalizations(variant.locale);
      await tester.tap(pdfButton('p2'));
      await tester.pump();

      final building = find.descendant(of: pdfButton('p2'), matching: find.text(l10n.pdfPreparing));
      expect(building, findsOneWidget);
      expect(find.descendant(of: pdfButton('p2'), matching: find.byType(CircularProgressIndicator)), findsOneWidget);
      expect(tester.widget<TextButton>(find.descendant(of: pdfButton('p2'), matching: find.byType(TextButton))).onPressed, isNull);
      // The other article's item still works.
      expect(find.descendant(of: pdfButton('p1'), matching: find.text(l10n.pdfDownload)), findsOneWidget);

      // A second tap does nothing.
      await tester.tap(pdfButton('p2'), warnIfMissed: false);
      await tester.pump();
      expect(repository.calls, [('p2', 'ar-EG')]);

      repository.pending!.complete(repository.answer);
      await tester.pumpAndSettle();
      expect(find.descendant(of: pdfButton('p2'), matching: find.text(l10n.pdfDownload)), findsOneWidget);
      expect(share.files, hasLength(1));
    });
  }

  for (final (code, message) in [
    (FailureCodes.articlePdfBusy, 'Many PDFs are being prepared right now. Try again in a moment.'),
    (FailureCodes.articlePdfLimit, "You've downloaded many PDFs this hour. Try again later."),
    (FailureCodes.articlePdfFailed, "We couldn't prepare the PDF. Try again."),
    (FailureCodes.networkTimeout, "We couldn't prepare the PDF. Try again."),
    (FailureCodes.networkOffline, 'You need an internet connection to download the PDF.'),
  ]) {
    testWidgets('$code: "$message" with "Try again", which asks for the same version', (tester) async {
      repository.answer = Err(Failure(code));
      await pump(tester);
      await tester.tap(pdfButton('p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pdf-language-en')));
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
      expect(share.files, isEmpty);
      expect(find.descendant(of: pdfButton('p1'), matching: find.text('Download PDF')), findsOneWidget);

      repository.answer = const Ok(ArticlePdf(path: '/tmp/a.pdf', fileName: 'a.pdf'));
      await tester.tap(find.widgetWithText(SnackBarAction, 'Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Which version?'), findsNothing);
      expect(repository.calls, [('p1', 'en'), ('p1', 'en')]);
      expect(share.files.single.fileName, 'a.pdf');
    });
  }

  for (final (code, message) in [
    (FailureCodes.articleNotFound, 'Article not found.'),
    (FailureCodes.articlePdfHidden, "Moderators hid this article, so it can't be downloaded as a PDF."),
  ]) {
    testWidgets('$code: "$message" without "Try again"', (tester) async {
      repository.answer = Err(Failure(code));
      await pump(tester);
      await tester.tap(pdfButton('p2'));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
    });
  }

  testWidgets('Arabic: the error and "حاول تاني"', (tester) async {
    repository.answer = const Err(Failure(FailureCodes.networkOffline));
    await pump(tester, variant: const Variant(AppLocales.ar, Brightness.light));
    await tester.tap(pdfButton('p2'));
    await tester.pumpAndSettle();
    expect(find.text('تحتاج إلى اتصال بالإنترنت لتنزيل ملف PDF.'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'إعادة المحاولة'), findsOneWidget);
  });

  group('the reader\'s "⋯" menu (F28)', () {
    // sampleCard's writer is [editorial]: signed in as them, it is your own article.
    const writer = Me(id: 'a-1', displayName: 'ReadIn Editorial', username: 'editorial');
    final article = ArticleDetails(card: sampleCard(1, language: 'en'), availableLanguages: const ['en'], content: RDocDocument.empty);

    /// The reader's menu with the page's cubits ([ArticlePdfCubit] and its feedback, as ArticlePage provides them), or
    /// a post card's menu without them ([reader] false). A null [me] is a guest; [shown] replaces the article on screen.
    Future<void> pumpMenu(WidgetTester tester, {required Me? me, bool reader = true, ArticleDetails? shown}) async {
      usePhoneSurface(tester);
      final onScreen = shown ?? article;
      final session = MockSessionCubit();
      whenListen(
        session,
        const Stream<SessionState>.empty(),
        initialState: me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me),
      );
      final articleCubit = _MockArticleCubit();
      whenListen(articleCubit, const Stream<ArticleState>.empty(), initialState: ArticleState(status: ArticleStatus.ready, article: onScreen));
      final Widget menu = reader
          ? ArticleMenuButton(article: onScreen)
          : ArticleMenuView(card: onScreen.card, hidden: false, onModerated: (_) {});
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<ArticleCubit>.value(value: articleCubit),
            if (reader) BlocProvider<ArticlePdfCubit>.value(value: pdf),
          ],
          child: reader
              ? ArticlePdfFeedback(child: Scaffold(body: Center(child: menu)))
              : Scaffold(body: Center(child: menu)),
        ),
        variant: _en,
      ));
      await tester.pump();
    }

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Article options'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Finder menuItem(String text) => find.ancestor(of: find.text(text), matching: find.byType(PopupMenuItem<ArticleMenuItem>));

    testWidgets('your own article: "Download PDF" after Mute topics; it shares the version on screen', (tester) async {
      await pumpMenu(tester, me: writer);
      await openMenu(tester);
      expect(find.text('Mute topics'), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Mute topics')).dy, lessThan(tester.getTopLeft(find.text('Download PDF')).dy));

      await tester.tap(find.text('Download PDF'));
      await tester.pumpAndSettle();
      expect(repository.calls, [('art-1', 'en')]);
      expect(share.files.single.fileName, 'di-in-dotnet-en.pdf');
    });

    testWidgets('while it builds: "Preparing the PDF…", disabled, and another tap asks for nothing', (tester) async {
      repository.pending = Completer();
      await pumpMenu(tester, me: writer);
      await openMenu(tester);
      await tester.tap(find.text('Download PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await openMenu(tester);
      expect(find.text('Preparing the PDF…'), findsOneWidget);
      expect(tester.widget<PopupMenuItem<ArticleMenuItem>>(menuItem('Preparing the PDF…')).enabled, isFalse);
      expect(find.descendant(of: menuItem('Preparing the PDF…'), matching: find.byType(CircularProgressIndicator)), findsOneWidget);
      await tester.tap(find.text('Preparing the PDF…'), warnIfMissed: false);
      await tester.pump();
      expect(repository.calls, [('art-1', 'en')]);

      await tester.tapAt(const Offset(10, 10)); // closes the menu
      await tester.pump(const Duration(milliseconds: 400));
      repository.pending!.complete(repository.answer);
      await tester.pumpAndSettle();
      expect(share.files, hasLength(1));
    });

    testWidgets('a failure shows its message with "Try again" on the reader', (tester) async {
      repository.answer = const Err(Failure(FailureCodes.articlePdfBusy, statusCode: 503));
      await pumpMenu(tester, me: writer);
      await openMenu(tester);
      await tester.tap(find.text('Download PDF'));
      await tester.pumpAndSettle();
      expect(find.text('Many PDFs are being prepared right now. Try again in a moment.'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Try again'), findsOneWidget);
    });

    // Any member downloads any article they can open (F33, user decision 2026-11-06).
    testWidgets("someone else's article: \"Download PDF\" right before Report; it shares the version on screen", (tester) async {
      await pumpMenu(tester, me: sampleMe);
      await openMenu(tester);
      expect(find.text('Download PDF'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Mute topics')).dy, lessThan(tester.getTopLeft(find.text('Download PDF')).dy));
      expect(tester.getTopLeft(find.text('Download PDF')).dy, lessThan(tester.getTopLeft(find.text('Report article')).dy));

      await tester.tap(find.text('Download PDF'));
      await tester.pumpAndSettle();
      expect(repository.calls, [('art-1', 'en')]);
      expect(share.files.single, (path: '/tmp/article-pdf/di-in-dotnet-en.pdf', fileName: 'di-in-dotnet-en.pdf'));
    });

    testWidgets("someone else's Arabic version on screen asks for the Arabic file", (tester) async {
      await pumpMenu(
        tester,
        me: sampleMe,
        shown: ArticleDetails(card: sampleCard(1, language: 'ar-EG'), availableLanguages: const ['ar-EG', 'en'], content: RDocDocument.empty),
      );
      await openMenu(tester);
      await tester.tap(find.text('Download PDF'));
      await tester.pumpAndSettle();
      expect(find.text('Which version?'), findsNothing);
      expect(repository.calls, [('art-1', 'ar-EG')]);
    });

    testWidgets('a guest sees "Download PDF" and gets the sign-in prompt, with no request', (tester) async {
      await pumpMenu(tester, me: null);
      await openMenu(tester);
      expect(find.text('Download PDF'), findsOneWidget);

      await tester.tap(find.text('Download PDF'));
      await tester.pumpAndSettle();
      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      expect(find.text(l10n.signInPromptTitle), findsOneWidget);
      expect(repository.calls, isEmpty);
      expect(share.files, isEmpty);
    });

    testWidgets("a moderator reading someone else's hidden article gets no \"Download PDF\" (the API answers 404)", (tester) async {
      await pumpMenu(tester, me: moderatorMe(), shown: article.withModeration(ArticleModeration(hiddenAt: DateTime.utc(2026, 11, 3))));
      await openMenu(tester);
      expect(find.text('Unhide article'), findsOneWidget);
      expect(find.text('Download PDF'), findsNothing);
    });

    testWidgets('your own hidden article keeps "Download PDF": the moderators\' message says why there is no file', (tester) async {
      repository.answer = const Err(Failure(FailureCodes.articlePdfHidden, statusCode: 409));
      await pumpMenu(tester, me: writer, shown: article.withModeration(ArticleModeration(hiddenAt: DateTime.utc(2026, 11, 3))));
      await openMenu(tester);
      await tester.tap(find.text('Download PDF'));
      await tester.pumpAndSettle();
      expect(find.text("Moderators hid this article, so it can't be downloaded as a PDF."), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
    });

    testWidgets('a post card\'s menu has none, even on your own article', (tester) async {
      await pumpMenu(tester, me: writer, reader: false);
      await openMenu(tester);
      expect(find.text('Mute topics'), findsOneWidget);
      expect(find.text('Download PDF'), findsNothing);
    });
  });
}
