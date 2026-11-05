import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/categories/domain/entities/writer_category.dart';
import 'package:readin/features/categories/domain/usecases/category_usecases.dart';
import 'package:readin/features/categories/presentation/cubit/category_cubits.dart';
import 'package:readin/features/categories/presentation/widgets/categories_tab.dart';
import 'package:readin/shared/widgets/state_views.dart';

import '../../helpers/category_fixtures.dart';
import '../../helpers/fixtures.dart' show sampleMe;
import '../../helpers/path_fakes.dart' show pumpRouted;
import '../../helpers/test_app.dart';

/// A profile's Categories tab (F31): someone else's cards (non-empty, in order, then "مقالات تانية") and the own
/// manage list (empty ones too, create, rename, reorder, delete with the article count).
void main() {
  late AppLocalizations l10n;

  setUpAll(() async => l10n = await AppLocalizations.delegate.load(AppLocales.en));

  Widget leading(BuildContext context) => const SliverToBoxAdapter();

  group('someone else\'s categories', () {
    Future<List<String>> pump(WidgetTester tester, FakeCategoriesRepository repo) async {
      final opened = <String>[];
      final cubit = ProfileCategoriesCubit(GetUserCategories(repo), 'mona_dev');
      addTearDown(cubit.close);
      await cubit.load();
      await pumpRouted(
        tester,
        Scaffold(body: ProfileCategoriesView(username: 'mona_dev', leading: leading)),
        opened: opened,
        providers: [BlocProvider<ProfileCategoriesCubit>.value(value: cubit)],
      );
      return opened;
    }

    testWidgets('one card per non-empty category in the writer\'s order, then "Other articles"', (tester) async {
      final repo = FakeCategoriesRepository(mine: [...enCategories, draftsOnly], uncategorized: 4);
      await pump(tester, repo);

      final names = tester.widgetList<CategoryCard>(find.byType(CategoryCard)).map((c) => c.name).toList();
      expect(names, ['Backend tips', 'EF Core', 'Career & هندسة', l10n.categoriesOther]);
      expect(find.text(l10n.categoryArticleCount(7)), findsOneWidget);
      expect(find.text(l10n.categoryArticleCount(4)), findsOneWidget);
      expect(find.byType(PopupMenuButton<Object>), findsNothing, reason: 'visitors only read');
    });

    testWidgets('a card opens the category page; "Other articles" opens _other', (tester) async {
      final repo = FakeCategoriesRepository(mine: const [backendTips], uncategorized: 2);
      final opened = await pump(tester, repo);

      await tester.tap(find.byKey(ValueKey('category-card-${backendTips.slug}')));
      await tester.pumpAndSettle();
      expect(opened, ['/u/mona_dev/c/${Uri.encodeComponent(backendTips.slug)}']);
      Navigator.of(tester.element(find.textContaining('opened'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('category-card-other')));
      await tester.pumpAndSettle();
      expect(opened.last, '/u/mona_dev/c/_other');
    });

    testWidgets('no category with articles: the empty state, without "Other articles" alone', (tester) async {
      final repo = FakeCategoriesRepository(mine: const [draftsOnly], uncategorized: 5);
      await pump(tester, repo);
      expect(find.text(l10n.categoriesEmptyTitle), findsOneWidget);
      expect(find.byType(CategoryCard), findsNothing);
    });

    testWidgets('a name keeps its own direction in the Arabic UI', (tester) async {
      final cubit = ProfileCategoriesCubit(GetUserCategories(FakeCategoriesRepository(mine: const [efCore, backendTips])), 'mona_dev');
      addTearDown(cubit.close);
      await cubit.load();
      usePhoneSurface(tester);
      await tester.pumpWidget(testApp(
        BlocProvider<ProfileCategoriesCubit>.value(
          value: cubit,
          child: Scaffold(body: ProfileCategoriesView(username: 'mona_dev', leading: leading)),
        ),
      ));
      Text nameOf(String slug) => tester.widget<Text>(
            find.descendant(of: find.byKey(ValueKey('category-card-$slug')), matching: find.byType(Text)).first,
          );
      expect(nameOf(efCore.slug).textDirection, TextDirection.ltr);
      expect(nameOf(backendTips.slug).textDirection, TextDirection.rtl);
    });
  });

  group('the own categories', () {
    late FakeCategoriesRepository repo;
    late MyCategoriesCubit cubit;

    Future<List<String>> pump(WidgetTester tester, {List<WriterCategory>? mine, int uncategorized = 2}) async {
      repo = FakeCategoriesRepository(mine: [...enCategories, draftsOnly], uncategorized: uncategorized);
      if (mine != null) repo.mine = [...mine];
      cubit = MyCategoriesCubit(GetMyCategories(repo), ManageCategories(repo));
      addTearDown(cubit.close);
      await cubit.load();
      final opened = <String>[];
      await pumpRouted(
        tester,
        Scaffold(body: MyCategoriesView(username: 'reader1', leading: leading)),
        opened: opened,
        providers: [BlocProvider<MyCategoriesCubit>.value(value: cubit)],
      );
      return opened;
    }

    Future<void> openMenu(WidgetTester tester, String id) async {
      await tester.tap(find.byKey(ValueKey('my-category-menu-$id')));
      await tester.pumpAndSettle();
    }

    testWidgets('every category, an empty one marked as hidden from visitors, then "Other articles"', (tester) async {
      await pump(tester);
      expect(find.byType(MyCategoryRow), findsNWidgets(4));
      expect(find.text(l10n.categoryEmptyOwn), findsOneWidget);
      expect(find.byKey(const ValueKey('category-card-other')), findsOneWidget);
      expect(find.text(l10n.categoriesOwnHint), findsOneWidget);
    });

    testWidgets('"New category" checks the name inline, then creates it last', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('category-create')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('category-name-submit')));
      await tester.pump();
      expect(find.text(l10n.fieldRequired), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('category-name-input')), '!!!');
      await tester.tap(find.byKey(const ValueKey('category-name-submit')));
      await tester.pump();
      expect(find.text(l10n.categoryNameNoLetter), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('category-name-input')), 'ef core');
      await tester.pump();
      expect(find.text(l10n.errCategoryNameTaken), findsOneWidget, reason: 'the name of another category, shown while typing');

      await tester.enterText(find.byKey(const ValueKey('category-name-input')), '  Rust   tips ');
      await tester.tap(find.byKey(const ValueKey('category-name-submit')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('create Rust tips'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(cubit.state.items.last.name, 'Rust tips');
      expect(find.byType(MyCategoryRow), findsNWidgets(5));
    });

    testWidgets('a refusal stays in the dialog under the field', (tester) async {
      await pump(tester);
      repo.failures['create'] = const Failure(FailureCodes.categoryLimit, statusCode: 400);
      await tester.tap(find.byKey(const ValueKey('category-create')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('category-name-input')), 'Rust');
      await tester.tap(find.byKey(const ValueKey('category-name-submit')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(l10n.errCategoryLimit), findsOneWidget);
    });

    testWidgets('rename fills in the name; another spelling of its own name is fine', (tester) async {
      await pump(tester);
      await openMenu(tester, 'c-2');
      await tester.tap(find.text(l10n.renameAction));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'EF Core'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('category-name-input')), 'ef core');
      await tester.pump();
      expect(find.text(l10n.errCategoryNameTaken), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('category-name-input')), 'EF Core 10');
      await tester.tap(find.byKey(const ValueKey('category-name-submit')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('rename c-2 EF Core 10'));
      expect(find.text('EF Core 10'), findsOneWidget);
    });

    testWidgets('delete asks first, with the article count, then removes it', (tester) async {
      await pump(tester);
      await openMenu(tester, 'c-1');
      await tester.tap(find.text(l10n.deleteAction));
      await tester.pumpAndSettle();
      expect(find.text(l10n.categoryDeleteBody(7)), findsOneWidget);

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(repo.calls.where((c) => c.startsWith('delete')), isEmpty);

      await openMenu(tester, 'c-1');
      await tester.tap(find.text(l10n.deleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category-delete-confirm')));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'delete c-1');
      expect(find.byType(MyCategoryRow), findsNWidgets(3));
      expect(find.text(l10n.categoryDeleted), findsOneWidget);
      expect(cubit.state.uncategorizedCount, 9, reason: 'its 7 articles joined the 2 without a category');
    });

    testWidgets('"Move up / down" in the menu reorders; the first has no "Move up", the last no "Move down"', (tester) async {
      await pump(tester);
      await openMenu(tester, 'c-1');
      expect(find.text(l10n.categoryMoveUp), findsNothing);
      await tester.tap(find.text(l10n.categoryMoveDown));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'reorder c-2,c-1,c-3,c-4');

      await openMenu(tester, 'c-4');
      expect(find.text(l10n.categoryMoveDown), findsNothing);
      await tester.tap(find.text(l10n.categoryMoveUp));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'reorder c-2,c-1,c-4,c-3');
      expect(cubit.state.items.map((c) => c.id), ['c-2', 'c-1', 'c-4', 'c-3']);
    });

    testWidgets('dragging a handle reorders', (tester) async {
      await pump(tester);
      final handle = find.descendant(of: find.byKey(const ValueKey('my-category-c-1')), matching: find.byIcon(Icons.drag_indicator_rounded));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(repo.calls.where((c) => c.startsWith('reorder')), isNotEmpty);
      expect(cubit.state.items.first.id, isNot('c-1'));
    });

    testWidgets('no categories yet: the empty state creates the first one', (tester) async {
      await pump(tester, mine: const [], uncategorized: 0);
      expect(find.text(l10n.categoriesEmptyOwnTitle), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('category-create')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('category-name-input')), 'نصايح Backend');
      await tester.tap(find.byKey(const ValueKey('category-name-submit')));
      await tester.pumpAndSettle();
      expect(find.byType(MyCategoryRow), findsOneWidget);
      expect(find.byType(EmptyView), findsNothing);
    });

    testWidgets('a row opens its category page', (tester) async {
      final opened = await pump(tester);
      await tester.tap(find.text('EF Core'));
      await tester.pumpAndSettle();
      expect(opened, ['/u/reader1/c/ef-core']);
    });
  });

  group('which list the tab shows', () {
    late FakeCategoriesRepository repo;

    setUp(() {
      repo = FakeCategoriesRepository(mine: [...enCategories, draftsOnly], uncategorized: 2);
      getIt
        ..registerFactoryParam<ProfileCategoriesCubit, String, dynamic>((username, _) => ProfileCategoriesCubit(GetUserCategories(repo), username))
        ..registerFactory<MyCategoriesCubit>(() => MyCategoriesCubit(GetMyCategories(repo), ManageCategories(repo)));
    });
    tearDown(getIt.reset);

    Future<void> pump(WidgetTester tester, {required bool isMe, required Me me}) async {
      await pumpRouted(
        tester,
        Scaffold(body: ProfileCategoriesTab(username: 'reader1', isMe: isMe, leading: leading)),
        opened: <String>[],
        me: me,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('your own profile, allowed to write (articles.create): the manage list', (tester) async {
      await pump(tester, isMe: true, me: writerMe);
      expect(find.byType(MyCategoriesView), findsOneWidget);
      expect(find.byType(MyCategoryRow), findsNWidgets(4), reason: 'the empty one too');
    });

    testWidgets('your own profile without articles.create: the public list (GET /me/categories would be refused)', (tester) async {
      await pump(tester, isMe: true, me: sampleMe);
      expect(find.byType(MyCategoriesView), findsNothing);
      expect(find.byType(ProfileCategoriesView), findsOneWidget);
      expect(find.byType(CategoryCard), findsNWidgets(4), reason: 'the three with articles, then "Other articles"');
      expect(repo.calls, ['user reader1']);
    });

    testWidgets("someone else's profile: the public list, even for a writer", (tester) async {
      await pump(tester, isMe: false, me: writerMe);
      expect(find.byType(ProfileCategoriesView), findsOneWidget);
      expect(find.byType(MyCategoryRow), findsNothing);
    });
  });
}
