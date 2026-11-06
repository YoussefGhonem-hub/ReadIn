import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/highlights/domain/entities/highlight.dart';
import 'package:readin/features/highlights/presentation/cubit/my_highlights_cubit.dart';
import 'package:readin/features/highlights/presentation/widgets/saved_highlights_list.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

class _MockMyHighlightsCubit extends MockCubit<MyHighlightsState> implements MyHighlightsCubit {}

Highlight _h(String id, String block, String text) =>
    Highlight(id: id, blockId: block, startOffset: 0, endOffset: text.length, text: text, createdAt: DateTime.utc(2026, 11, 5));

final sampleGroups = [
  HighlightGroup(
    article: const HighlightArticle(id: 'a-1', slug: 'di-in-dotnet', language: 'ar-EG', title: 'إزاي تستخدم DI في .NET 10؟', author: editorial),
    highlights: [_h('h-2', 'p1', 'ASP.NET Core، أكيد شفت الـ Dependency Injection'), _h('h-1', 'q1', 'الكود النضيف مش رفاهية')],
    latestAt: DateTime.utc(2026, 11, 5),
  ),
  HighlightGroup(
    article: const HighlightArticle(id: 'a-1', slug: 'di-in-dotnet', language: 'en', title: 'Using DI in .NET 10'),
    highlights: [_h('h-3', 'e1', 'Injection (الحقن) everywhere')],
    latestAt: DateTime.utc(2026, 11, 4),
  ),
];

void main() {
  late _MockMyHighlightsCubit cubit;

  setUp(() {
    cubit = _MockMyHighlightsCubit();
    when(cubit.loadMore).thenAnswer((_) async {});
    when(cubit.refresh).thenAnswer((_) async {});
    when(cubit.load).thenAnswer((_) async {});
  });

  void hold(MyHighlightsState state) => whenListen(cubit, const Stream<MyHighlightsState>.empty(), initialState: state);

  Future<void> pump(WidgetTester tester, {Variant variant = const Variant(AppLocales.ar, Brightness.light)}) async {
    usePhoneSurface(tester);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => BlocProvider<MyHighlightsCubit>.value(value: cubit, child: const Scaffold(body: SavedHighlightsList())),
      ),
      GoRoute(
        path: '/a/:slug',
        builder: (_, state) => Scaffold(body: Text('opened ${state.pathParameters['slug']} ${state.uri.queryParameters['lang']} #${state.uri.fragment}')),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(variant.locale),
      darkTheme: AppTheme.dark(variant.locale),
      themeMode: variant.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      locale: variant.locale,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ));
    await tester.pump();
  }

  testWidgets('one card per article version: its title, author or "Deleted user", version, highlights', (tester) async {
    hold(MyHighlightsState(status: MyHighlightsStatus.ready, groups: sampleGroups));
    await pump(tester);
    expect(find.byType(HighlightGroupCard), findsNWidgets(2));
    expect(find.textContaining('ReadIn Editorial'), findsOneWidget); // isolated in the Arabic UI
    expect(find.text('مستخدم محذوف'), findsOneWidget);
    // Which version each group is, worded as on the web.
    expect(find.text('النسخة العربية'), findsOneWidget);
    expect(find.text('النسخة الإنجليزية'), findsOneWidget);
    expect(find.byType(SavedHighlightTile), findsNWidgets(3));
    // The highlight's text in the article's own direction.
    final en = tester.widget<Directionality>(
      find.ancestor(of: find.textContaining('everywhere'), matching: find.byType(Directionality)).first,
    );
    expect(en.textDirection, TextDirection.ltr);
  });

  testWidgets('tapping a highlight opens that version of the article at its block', (tester) async {
    hold(MyHighlightsState(status: MyHighlightsStatus.ready, groups: sampleGroups));
    await pump(tester);
    await tester.tap(find.textContaining('everywhere'));
    await tester.pumpAndSettle();
    expect(find.text('opened di-in-dotnet en #e1'), findsOneWidget);
    expect(highlightLink(sampleGroups.first.article, 'q1'), '/a/di-in-dotnet?lang=ar-EG#q1');
  });

  testWidgets('empty, and failed with Try again', (tester) async {
    hold(const MyHighlightsState(status: MyHighlightsStatus.ready));
    await pump(tester, variant: const Variant(AppLocales.en, Brightness.light));
    expect(find.text('No highlights yet'), findsOneWidget);

    hold(const MyHighlightsState(status: MyHighlightsStatus.failure, failure: Failure(FailureCodes.networkOffline)));
    await pump(tester, variant: const Variant(AppLocales.en, Brightness.light));
    await tester.tap(find.text('Try again'));
    verify(cubit.load).called(1);
  });

  testWidgets('scrolling near the end asks for the next page', (tester) async {
    hold(MyHighlightsState(
      status: MyHighlightsStatus.ready,
      groups: [
        for (var i = 0; i < 8; i++)
          HighlightGroup(
            article: HighlightArticle(id: 'a-$i', slug: 's-$i', language: 'en', title: 'Article $i', author: editorial),
            highlights: [_h('h-$i', 'p1', 'A sentence worth keeping, number $i.')],
            latestAt: DateTime.utc(2026, 11, 5),
          ),
      ],
      nextCursor: 'c2',
    ));
    await pump(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();
    verify(cubit.loadMore).called(greaterThan(0));
  });

  test('a group per version: the same article in two languages is two groups', () {
    expect(sampleGroups.first.key, 'a-1|ar-EG');
    expect(sampleGroups.last.key, 'a-1|en');
  });
}
