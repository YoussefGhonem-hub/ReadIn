import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/pages/article_page.dart';
import 'package:readin/features/article/presentation/widgets/article_menu.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/highlights/domain/entities/highlight.dart';
import 'package:readin/features/highlights/domain/usecases/highlight_usecases.dart';
import 'package:readin/features/highlights/presentation/cubit/article_highlights_cubit.dart';
import 'package:readin/features/highlights/presentation/widgets/reader_highlights.dart';
import 'package:readin/features/highlights/presentation/widgets/show_highlights_switch.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/highlight_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class _MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class _MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

const _member = Me(
  id: 'u-1',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  onboardingCompleted: true,
  permissions: ['highlights.create'],
);

void main() {
  final fixtures = readSharedJson('rdoc/highlight-fixtures.json');
  final document = RDocDocument.fromJson((fixtures['documents'] as Map<String, dynamic>)['ar'] as Map<String, dynamic>);
  final article = ArticleDetails(card: sampleCard(1), availableLanguages: const ['ar-EG'], content: document);

  late FakeHighlightsRepository repository;
  late ArticleHighlightsCubit cubit;
  late _MockSettingsCubit settings;
  late StreamController<AppSettings> settingsChanges;
  late MockSessionCubit session;
  late int textChanged;

  setUpAll(() => registerFallbackValue(true));

  setUp(() {
    repository = FakeHighlightsRepository();
    cubit = ArticleHighlightsCubit(GetArticleHighlights(repository), EditHighlights(repository));
    settingsChanges = StreamController<AppSettings>.broadcast();
    settings = _MockSettingsCubit();
    session = MockSessionCubit();
    textChanged = 0;
  });

  tearDown(() async {
    await settingsChanges.close();
  });

  void useSettings(AppSettings initial) {
    whenListen(settings, settingsChanges.stream, initialState: initial);
    when(() => settings.setShowHighlights(any())).thenAnswer((invocation) async {
      final show = invocation.positionalArguments.single as bool;
      settingsChanges.add(settings.state.copyWith(showHighlights: show));
      return null;
    });
  }

  void signIn(Me? me, {Stream<SessionState>? changes}) => whenListen(
        session,
        changes ?? const Stream<SessionState>.empty(),
        initialState: me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me),
      );

  Future<void> pumpReader(
    WidgetTester tester, {
    Me? me = _member,
    AppSettings initial = const AppSettings(),
    ArticleDetails? details,
    Stream<SessionState>? sessionChanges,
  }) async {
    useSettings(initial);
    signIn(me, changes: sessionChanges);
    final a = details ?? article;
    usePhoneSurface(tester, size: const Size(390, 2400));
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<SettingsCubit>.value(value: settings),
          BlocProvider<ArticleHighlightsCubit>.value(value: cubit),
        ],
        child: Scaffold(
          body: ReaderHighlights(
            article: a,
            onTextChanged: () => textChanged++,
            child: ReaderBody(article: a, bodyFontSize: 17),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  Finder unit(String blockId) => find.descendant(
        of: find.descendant(of: find.byKey(ValueKey(_keyOf(document, blockId))), matching: find.byType(RHighlightUnit)),
        matching: find.byType(RichText),
      );

  Offset at(WidgetTester tester, Finder rich, int plain) {
    final paragraph = tester.renderObject<RenderParagraph>(rich.first);
    final offset = renderedOffsetsOf(paragraph.text.toPlainText())[plain];
    final boxes = paragraph.getBoxesForSelection(TextSelection(baseOffset: offset, extentOffset: offset + 1));
    return paragraph.localToGlobal(boxes.first.toRect().center);
  }

  Future<void> highlightWordAt(WidgetTester tester, String blockId, int plain) async {
    await tester.longPressAt(at(tester, unit(blockId), plain));
    await tester.pumpAndSettle();
    await tester.tap(find.text('علّم'));
    await tester.pumpAndSettle();
  }

  group('reader', () {
    testWidgets('a member highlights a word: POST with the version and range, then the mark is drawn', (tester) async {
      await pumpReader(tester);
      expect(repository.loads, [('art-1', 'ar-EG')]);
      await highlightWordAt(tester, 'p1', 45);
      expect(repository.creates.single, ('art-1', 'ar-EG', const HighlightRange(blockId: 'p1', startOffset: 42, endOffset: 52, text: 'Dependency')));
      final colors = tester.element(unit('p1')).colors;
      final spans = <TextSpan>[];
      tester.widget<RichText>(unit('p1')).text.visitChildren((s) {
        if (s is TextSpan && s.style?.backgroundColor == colors.accentContainer) spans.add(s);
        return true;
      });
      // The term's opening isolate may ride along in the marked span: it is zero-width and never moves the text.
      expect(String.fromCharCodes(spans.map((s) => s.text).join().codeUnits.where((c) => !isBidiControl(c))), 'Dependency');
      expect(cubit.state.mine.single.id, 'h-1');
    });

    testWidgets('a guest gets the sign-in prompt instead of a highlight', (tester) async {
      await pumpReader(tester, me: null);
      // Guests see popular highlights: the GET still runs.
      expect(repository.loads, hasLength(1));
      await highlightWordAt(tester, 'p1', 45);
      final l10n = tester.element(find.byType(Scaffold).first).l10n;
      expect(find.text(l10n.signInPromptTitle), findsOneWidget);
      expect(repository.creates, isEmpty);
    });

    testWidgets('signing in from the reader brings yours', (tester) async {
      final sessions = StreamController<SessionState>.broadcast();
      addTearDown(sessions.close);
      await pumpReader(tester, me: null, sessionChanges: sessions.stream);
      expect(repository.loads, hasLength(1));
      sessions.add(const SessionState(status: SessionStatus.authenticated, me: _member));
      await tester.pumpAndSettle();
      expect(repository.loads, [('art-1', 'ar-EG'), ('art-1', 'ar-EG')]);
    });

    testWidgets('inside one of yours: Remove deletes it and the mark goes', (tester) async {
      repository.answer = (id, language) => ArticleHighlights(
            articleId: id,
            language: language,
            mine: [Highlight(id: 'h-7', blockId: 'p1', startOffset: 15, endOffset: 27, text: 'ASP.NET Core', createdAt: DateTime.utc(2026))],
          );
      await pumpReader(tester);
      await tester.longPressAt(at(tester, unit('p1'), 24));
      await tester.pumpAndSettle();
      await tester.tap(find.text('شيل العلامة'));
      await tester.pumpAndSettle();
      expect(repository.removes, ['h-7']);
      expect(cubit.state.mine, isEmpty);
    });

    testWidgets('tapping one of yours offers Remove in a small bubble, which deletes it', (tester) async {
      repository.answer = (id, language) => ArticleHighlights(
            articleId: id,
            language: language,
            mine: [Highlight(id: 'h-7', blockId: 'p1', startOffset: 15, endOffset: 27, text: 'ASP.NET Core', createdAt: DateTime.utc(2026))],
          );
      await pumpReader(tester);
      await tester.tapAt(at(tester, unit('p1'), 20));
      await tester.pumpAndSettle();
      expect(find.byType(HighlightCountBubble), findsOneWidget);
      await tester.tap(find.text('شيل العلامة'));
      await tester.pumpAndSettle();
      expect(find.byType(HighlightCountBubble), findsNothing);
      expect(repository.removes, ['h-7']);
      expect(cubit.state.mine, isEmpty);
    });

    testWidgets('the article changed under the selection: the message, then the article and highlights load again', (tester) async {
      repository.createFailure = const Failure(FailureCodes.highlightTextMismatch);
      await pumpReader(tester);
      await highlightWordAt(tester, 'p1', 45);
      expect(find.text('النص ده اتغيّر في المقال. حدّث الصفحة وجرّب تاني.'), findsOneWidget);
      expect(textChanged, 1);
      expect(repository.loads, hasLength(2));
      expect(cubit.state.mine, isEmpty);
    });

    testWidgets('more than 1,000 characters: the too_long message, and nothing is sent', (tester) async {
      await pumpReader(tester);
      final highlights = tester.widget<RDocHighlights>(find.byType(RDocHighlights));
      final range = HighlightRange(blockId: 'p1', startOffset: 0, endOffset: 1001, text: 'x' * 1001);
      highlights.onHighlight(tester.element(find.byType(RDocHighlights)), HighlightSelection(HighlightSelectionStatus.tooLong, range));
      await tester.pump();
      expect(find.text('الـ Highlight لازم يكون 1000 حرف أو أقل.'), findsOneWidget);
      expect(repository.creates, isEmpty);
    });

    testWidgets('tapping a popular range shows "N قارئ علّموا الجملة دي"; a tap anywhere closes it', (tester) async {
      repository.answer = (id, language) => ArticleHighlights(
            articleId: id,
            language: language,
            popular: const [PopularHighlight(blockId: 'q1', startOffset: 24, endOffset: 37, text: 'ده احترام للي', count: 5)],
          );
      await pumpReader(tester);
      await tester.tapAt(at(tester, unit('q1'), 28));
      await tester.pumpAndSettle();
      expect(find.text('5 قارئ علّموا الجملة دي'), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('5 قارئ علّموا الجملة دي'), findsNothing);
    });

    testWidgets('hidden: no GET, no marks, no selection; shown again from the menu, it loads', (tester) async {
      await pumpReader(tester, initial: const AppSettings(showHighlights: false));
      expect(repository.loads, isEmpty);
      expect(find.byType(SelectionArea), findsNothing);

      settingsChanges.add(const AppSettings());
      await tester.pumpAndSettle();
      expect(repository.loads, [('art-1', 'ar-EG')]);
      expect(find.byType(SelectionArea), findsWidgets);
    });

    testWidgets('a device copy (offline) has no highlights', (tester) async {
      await pumpReader(
        tester,
        details: ArticleDetails(card: sampleCard(1), availableLanguages: const ['ar-EG'], content: document, isOfflineCopy: true),
      );
      expect(repository.loads, isEmpty);
      expect(find.byType(SelectionArea), findsNothing);
    });

    testWidgets('a link to a block opens the reader there', (tester) async {
      useSettings(const AppSettings());
      signIn(_member);
      usePhoneSurface(tester);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(testApp(
        Scaffold(body: ReaderBody(article: article, bodyFontSize: 17, controller: controller, initialBlockId: 'p4')),
      ));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      // The last block can't reach the top: it is on screen, the reader scrolled to the end.
      final top = tester.getTopLeft(find.byKey(ValueKey(_keyOf(document, 'p4')))).dy;
      expect(top, inInclusiveRange(0, 844 - 60));
      expect(controller.offset, controller.position.maxScrollExtent);
    });
  });

  group('"⋯" menu and Settings', () {
    Future<void> pumpMenu(WidgetTester tester, {Me? me, bool reader = true, AppSettings initial = const AppSettings()}) async {
      useSettings(initial);
      signIn(me);
      usePhoneSurface(tester);
      final articleCubit = _MockArticleCubit();
      whenListen(articleCubit, const Stream<ArticleState>.empty(), initialState: ArticleState(status: ArticleStatus.ready, article: article));
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<SettingsCubit>.value(value: settings),
            BlocProvider<ArticleCubit>.value(value: articleCubit),
            if (reader) BlocProvider<ArticleHighlightsCubit>.value(value: cubit),
          ],
          child: Scaffold(
            body: Center(
              child: reader
                  ? ArticleMenuButton(article: article)
                  : ArticleMenuView(card: article.card, hidden: false, onModerated: (_) {}),
            ),
          ),
        ),
        variant: const Variant(AppLocales.en, Brightness.light),
      ));
      await tester.pump();
    }

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Article options'));
      await tester.pumpAndSettle();
    }

    testWidgets('right after Show less; a guest hides highlights with no sign-in prompt', (tester) async {
      await pumpMenu(tester);
      await openMenu(tester);
      expect(tester.getTopLeft(find.text('Show less like this')).dy, lessThan(tester.getTopLeft(find.text('Hide highlights')).dy));
      expect(tester.getTopLeft(find.text('Hide highlights')).dy, lessThan(tester.getTopLeft(find.text('Follow author')).dy));
      await tester.tap(find.text('Hide highlights'));
      await tester.pumpAndSettle();
      verify(() => settings.setShowHighlights(false)).called(1);
      expect(find.text(tester.element(find.byType(Scaffold)).l10n.signInPromptTitle), findsNothing);

      await openMenu(tester);
      expect(find.text('Show highlights'), findsOneWidget);
    });

    testWidgets('on your own article too; not on a post card', (tester) async {
      await pumpMenu(tester, me: const Me(id: 'a-1', displayName: 'ReadIn Editorial', username: 'editorial'));
      await openMenu(tester);
      expect(find.text('Hide highlights'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await pumpMenu(tester, me: _member, reader: false);
      await openMenu(tester);
      expect(find.text('Hide highlights'), findsNothing);
      expect(find.text('Show less like this'), findsOneWidget);
    });

    testWidgets('a refused change says why', (tester) async {
      await pumpMenu(tester, me: _member);
      when(() => settings.setShowHighlights(any())).thenAnswer((_) async => const Failure(FailureCodes.networkOffline));
      await openMenu(tester);
      await tester.tap(find.text('Hide highlights'));
      await tester.pumpAndSettle();
      final l10n = tester.element(find.byType(Scaffold)).l10n;
      expect(find.text(l10n.errOffline), findsOneWidget);
    });

    testWidgets('Settings → Show highlights flips the same setting', (tester) async {
      useSettings(const AppSettings());
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(
        BlocProvider<SettingsCubit>.value(value: settings, child: const Scaffold(body: ShowHighlightsSwitch())),
        variant: const Variant(AppLocales.en, Brightness.light),
      ));
      expect(find.text('Show highlights'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      verify(() => settings.setShowHighlights(false)).called(1);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    });
  });
}

String _keyOf(RDocDocument document, String blockId) {
  final b = document.blocks.firstWhere((b) => b.id == blockId);
  return 'rdoc-${b.type}-${b.id}';
}
