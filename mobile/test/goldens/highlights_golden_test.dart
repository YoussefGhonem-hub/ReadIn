@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/widgets/article_menu.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/highlights/domain/entities/highlight.dart';
import 'package:readin/features/highlights/domain/usecases/highlight_usecases.dart';
import 'package:readin/features/highlights/presentation/cubit/article_highlights_cubit.dart';
import 'package:readin/features/highlights/presentation/cubit/my_highlights_cubit.dart';
import 'package:readin/features/highlights/presentation/widgets/reader_highlights.dart';
import 'package:readin/features/highlights/presentation/widgets/saved_highlights_list.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/shared/rdoc/rdoc_view.dart';

import '../helpers/fixtures.dart';
import '../helpers/highlight_fakes.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/profile_fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class _MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class _MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

class _MockMyHighlightsCubit extends MockCubit<MyHighlightsState> implements MyHighlightsCubit {}

/// Highlights (F30) in ar/light and en/dark (SPEC §27): yours and popular marks on the mixed-text fixtures, the
/// selection toolbar (Highlight, Remove), the popular count, Remove from a tap on yours, the hidden state with the "⋯"
/// menu, and Saved → Highlights (its list, and the profile's Saved tab).
void main() {
  final fixtures = readSharedJson('rdoc/highlight-fixtures.json');
  final raw = fixtures['documents'] as Map<String, dynamic>;
  final ar = RDocDocument.fromJson(raw['ar'] as Map<String, dynamic>);
  final en = RDocDocument.fromJson(raw['en'] as Map<String, dynamic>);
  // The text blocks of the Arabic fixture (code, table and steps add nothing here).
  final arText = ar.copyWith(blocks: ar.blocks.where((b) => RBlockText.of(b) != null).toList());

  const marks = {
    // Yours across a bold run and a glossary term (mixed text).
    'p1': [RHighlightMark(start: 15, end: 62, mine: true, id: 'h-1')],
    // Popular across the hard break.
    'p2': [RHighlightMark(start: 41, end: 66, count: 3)],
    'h1': [RHighlightMark(start: 12, end: 25, count: 4)],
    's1': [RHighlightMark(start: 36, end: 53, mine: true, id: 'h-2')],
    'q1': [RHighlightMark(start: 24, end: 37, count: 5)],
    // Yours and popular on the same list item.
    'l1': [RHighlightMark(start: 39, end: 63, mine: true, id: 'h-3'), RHighlightMark(start: 39, end: 63, count: 6)],
    'e1': [RHighlightMark(start: 15, end: 43, mine: true, id: 'h-4')],
    'e2': [RHighlightMark(start: 13, end: 26, count: 3)],
    'e3': [RHighlightMark(start: 0, end: 14, mine: true, id: 'h-5')],
    'e4': [RHighlightMark(start: 4, end: 13, count: 8)],
  };

  Widget content(List<RDocDocument> docs, {bool enabled = true, Map<String, List<RHighlightMark>> marks = marks}) => Builder(
        builder: (context) => RDocHighlights(
          enabled: enabled,
          marks: marks,
          onHighlight: (_, _) {},
          onRemove: (_, _) {},
          onCountTap: (context, position, count) => showHighlightCountBubble(context, globalPosition: position, count: count),
          onMineTap: (context, position, _, count) =>
              showHighlightCountBubble(context, globalPosition: position, count: count, onRemove: () {}),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final doc in docs)
                  RDocScope(baseDirection: RDocScope.directionForLanguage(doc.language), child: RDocColumn(doc)),
              ],
            ),
          ),
        ),
      );

  Future<void> pumpApp(WidgetTester tester, Variant variant, Widget child, {Size size = const Size(390, 844)}) async {
    usePhoneSurface(tester, size: size);
    await tester.pumpWidget(testApp(child, variant: variant));
    await tester.pump();
  }

  Future<void> expectGolden(WidgetTester tester, Variant variant, String name) =>
      expectLater(find.byType(MaterialApp), matchesVariantGolden(variant, 'goldens/${name}_${variant.name}.png'));

  Finder unit(String blockId, RDocDocument doc, {int index = 0}) {
    final b = doc.blocks.firstWhere((x) => x.id == blockId);
    return find.descendant(
      of: find.descendant(
        of: find.byKey(ValueKey('rdoc-${b.type}-${b.id}')),
        matching: find.byWidgetPredicate((w) => w is RHighlightUnit && w.unit == index),
      ),
      matching: find.byType(RichText),
    );
  }

  Offset at(WidgetTester tester, Finder rich, int plain) {
    final paragraph = tester.renderObject<RenderParagraph>(rich);
    final offset = renderedOffsetsOf(paragraph.text.toPlainText())[plain];
    final boxes = paragraph.getBoxesForSelection(TextSelection(baseOffset: offset, extentOffset: offset + 1));
    return paragraph.localToGlobal(boxes.first.toRect().center);
  }

  tearDown(getIt.reset);

  for (final variant in Variant.golden) {
    final arabic = variant.locale.languageCode == 'ar';
    final doc = arabic ? arText : en;

    testWidgets('highlights in the reader ${variant.name}', (tester) async {
      await pumpApp(tester, variant, Scaffold(body: content([arText, en])), size: const Size(390, 1280));
      await expectGolden(tester, variant, 'highlights_reader');
    });

    testWidgets('highlight toolbar ${variant.name}', (tester) async {
      await pumpApp(tester, variant, Scaffold(body: content([doc], marks: const {})), size: const Size(390, 640));
      await tester.longPressAt(arabic ? at(tester, unit('p1', doc), 45) : at(tester, unit('e1', doc), 35));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'highlights_toolbar');
    });

    testWidgets('highlight toolbar inside yours ${variant.name}', (tester) async {
      await pumpApp(tester, variant, Scaffold(body: content([doc])), size: const Size(390, 640));
      await tester.longPressAt(arabic ? at(tester, unit('p1', doc), 24) : at(tester, unit('e1', doc), 35));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'highlights_toolbar_remove');
    });

    testWidgets('popular highlight count ${variant.name}', (tester) async {
      await pumpApp(tester, variant, Scaffold(body: content([doc])), size: const Size(390, 640));
      await tester.tapAt(arabic ? at(tester, unit('q1', doc), 28) : at(tester, unit('e2', doc), 18));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'highlights_popular_count');
    });

    // ar: yours and popular on one list item (the count and Remove); en: yours alone (Remove).
    testWidgets('tapping one of yours offers Remove ${variant.name}', (tester) async {
      await pumpApp(tester, variant, Scaffold(body: content([doc])), size: const Size(390, 900));
      await tester.tapAt(arabic ? at(tester, unit('l1', doc, index: 1), 10) : at(tester, unit('e3', doc), 1));
      await tester.pumpAndSettle();
      expect(find.text((await AppLocalizations.delegate.load(variant.locale)).highlightRemove), findsOneWidget);
      await expectGolden(tester, variant, 'highlights_mine_tap');
    });

    testWidgets('highlights hidden, the menu offers to show them ${variant.name}', (tester) async {
      final settings = _MockSettingsCubit();
      whenListen(settings, const Stream<AppSettings>.empty(), initialState: const AppSettings(showHighlights: false));
      final session = MockSessionCubit();
      whenListen(session, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      final article = ArticleDetails(card: sampleCard(1, language: doc.language), availableLanguages: [doc.language], content: doc);
      final articleCubit = _MockArticleCubit();
      whenListen(articleCubit, const Stream<ArticleState>.empty(), initialState: ArticleState(status: ArticleStatus.ready, article: article));
      final repository = FakeHighlightsRepository();
      final highlights = ArticleHighlightsCubit(GetArticleHighlights(repository), EditHighlights(repository));
      addTearDown(highlights.close);
      await pumpApp(
        tester,
        variant,
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: settings),
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<ArticleCubit>.value(value: articleCubit),
            BlocProvider<ArticleHighlightsCubit>.value(value: highlights),
          ],
          child: Scaffold(
            appBar: AppBar(actions: [ArticleMenuButton(article: article)]),
            body: content([doc], enabled: false),
          ),
        ),
        size: const Size(390, 700),
      );
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      await tester.tap(find.byTooltip(l10n.articleMenu));
      await tester.pumpAndSettle();
      expect(find.text(l10n.highlightMenuShow), findsOneWidget);
      await expectGolden(tester, variant, 'highlights_hidden_menu');
    });

    final groups = [
      HighlightGroup(
        article: HighlightArticle(
          id: 'a-1',
          slug: 'di-in-dotnet',
          language: arabic ? 'ar-EG' : 'en',
          title: arabic ? 'إزاي تستخدم DI في .NET 10؟' : 'Using DI in .NET 10',
          author: editorial,
        ),
        highlights: [
          Highlight(
            id: 'h-2',
            blockId: arabic ? 'p1' : 'e1',
            startOffset: 0,
            endOffset: 1,
            text: arabic ? 'ASP.NET Core، أكيد شفت الـ Dependency Injection' : 'Injection (الحقن) everywhere',
            createdAt: DateTime.utc(2026, 11, 5),
          ),
          Highlight(
            id: 'h-1',
            blockId: arabic ? 'q1' : 'e3',
            startOffset: 0,
            endOffset: 1,
            text: arabic ? 'الكود النضيف مش رفاهية، ده احترام للي هيقرا بعدك.' : 'Why it matters',
            createdAt: DateTime.utc(2026, 11, 4),
          ),
        ],
        latestAt: DateTime.utc(2026, 11, 5),
      ),
      HighlightGroup(
        article: HighlightArticle(
          id: 'a-1',
          slug: 'di-in-dotnet',
          language: arabic ? 'en' : 'ar-EG',
          title: arabic ? 'Using DI in .NET 10' : 'إزاي تستخدم DI في .NET 10؟',
        ),
        highlights: [
          Highlight(
            id: 'h-3',
            blockId: 'l1',
            startOffset: 0,
            endOffset: 1,
            text: arabic ? 'Use Dependency Injection (الحقن) everywhere: it makes testing easy 😀.' : 'استخدم constructor injection 💉',
            createdAt: DateTime.utc(2026, 11, 1),
          ),
        ],
        latestAt: DateTime.utc(2026, 11, 1),
      ),
    ];

    _MockMyHighlightsCubit myHighlights() {
      final cubit = _MockMyHighlightsCubit();
      whenListen(cubit, const Stream<MyHighlightsState>.empty(), initialState: MyHighlightsState(status: MyHighlightsStatus.ready, groups: groups));
      when(cubit.load).thenAnswer((_) async {});
      when(cubit.loadMore).thenAnswer((_) async {});
      getIt.registerFactory<MyHighlightsCubit>(() => cubit);
      return cubit;
    }

    // The section's list on its own, whole (the profile's Saved tab below shows it under the profile header). Saved →
    // Highlights lives only in the profile's Saved tab (SPEC F30), as on the web.
    testWidgets('Saved → Highlights, the list ${variant.name}', (tester) async {
      final cubit = myHighlights();
      await pumpApp(
        tester,
        variant,
        BlocProvider<MyHighlightsCubit>.value(
          value: cubit,
          child: const Scaffold(body: SafeArea(child: SavedHighlightsList())),
        ),
      );
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'highlights_saved');
    });

    testWidgets("the profile's Saved tab, Highlights section ${variant.name}", (tester) async {
      myHighlights();
      await pumpApp(tester, variant, provided([...appStores(), ...profileScreen(ownProfile)], const ProfileView(isTab: true)));
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      // The top block and the reading stats run past the screen: scroll the tab bar up, where it stays pinned.
      await tester.scrollUntilVisible(find.text(l10n.profileTabSaved), 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(l10n.profileTabSaved));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.highlightSavedTab));
      await tester.pumpAndSettle();
      await expectGolden(tester, variant, 'highlights_profile_saved');
    });
  }
}
