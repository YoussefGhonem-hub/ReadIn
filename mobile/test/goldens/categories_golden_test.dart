@Tags(['golden'])
library;

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/categories/domain/usecases/category_usecases.dart';
import 'package:readin/features/categories/presentation/cubit/category_cubits.dart';
import 'package:readin/features/categories/presentation/pages/category_page.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/editor/presentation/cubit/article_editor_cubit.dart';
import 'package:readin/features/editor/presentation/cubit/tag_suggestions_cubit.dart';
import 'package:readin/features/editor/presentation/widgets/article_settings_sheet.dart';
import 'package:readin/features/media/presentation/cubit/attachments_cubit.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';

import '../helpers/category_fixtures.dart';
import '../helpers/editor_fixtures.dart';
import '../helpers/fixtures.dart' show sampleMe;
import '../helpers/post_card_fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/profile_fixtures.dart';
import '../helpers/test_app.dart';

/// Writer categories (F31) in ar/light and en/dark (SPEC §27): the Categories tab of someone else's profile and of your
/// own (the manage list), "New category" with an inline message, the category page, and the editor's picker.
void main() {
  bool isEn(Variant variant) => variant.locale.languageCode == 'en';
  String languageOf(Variant variant) => isEn(variant) ? 'en' : 'ar-EG';

  setUp(() => CommentClock.now = () => DateTime.utc(2026, 11, 2, 12)); // post cards: "3 days ago"
  tearDown(() {
    CommentClock.now = DateTime.now;
    getIt.reset();
  });

  /// [ProfileView] on its Categories tab, over [repo].
  Future<void> pumpProfileTab(WidgetTester tester, Variant variant, FakeCategoriesRepository repo, {required bool own}) async {
    getIt
      ..registerFactoryParam<ProfileCategoriesCubit, String, dynamic>((username, _) => ProfileCategoriesCubit(GetUserCategories(repo), username))
      ..registerFactory<MyCategoriesCubit>(() => MyCategoriesCubit(GetMyCategories(repo), ManageCategories(repo)));
    usePhoneSurface(tester, size: const Size(390, 1100));
    final profile = own ? ownProfile : otherProfile;
    await tester.pumpWidget(testApp(
      // Your own tab manages the categories when you may write (`articles.create`).
      provided([...appStores(me: own ? writerMe : sampleMe), ...profileScreen(profile)], ProfileView(isTab: own)),
      variant: variant,
    ));
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(variant.locale);
    await tester.tap(find.text(l10n.profileTabCategories));
    await tester.pumpAndSettle();
  }

  for (final variant in Variant.golden) {
    final language = languageOf(variant);

    testWidgets('profile categories visitor ${variant.name}', (tester) async {
      final repo = FakeCategoriesRepository(mine: ownCategories(language), uncategorized: 4);
      await pumpProfileTab(tester, variant, repo, own: false);
      await expectLater(find.byType(ProfileView), matchesVariantGolden(variant, 'goldens/categories_visitor_${variant.name}.png'));
    });

    testWidgets('profile categories own ${variant.name}', (tester) async {
      final repo = FakeCategoriesRepository(mine: ownCategories(language), uncategorized: 2);
      await pumpProfileTab(tester, variant, repo, own: true);
      await expectLater(find.byType(ProfileView), matchesVariantGolden(variant, 'goldens/categories_own_${variant.name}.png'));
    });

    testWidgets('new category dialog ${variant.name}', (tester) async {
      final repo = FakeCategoriesRepository(mine: ownCategories(language), uncategorized: 2);
      await pumpProfileTab(tester, variant, repo, own: true);
      await tester.tap(find.byKey(const ValueKey('category-create')));
      await tester.pumpAndSettle();
      // Another spelling of an existing name: the message shows while typing.
      await tester.enterText(find.byKey(const ValueKey('category-name-input')), 'ef core');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await expectLater(find.byType(MaterialApp), matchesVariantGolden(variant, 'goldens/categories_new_dialog_${variant.name}.png'));
    });

    testWidgets('category page ${variant.name}', (tester) async {
      final category = visitorCategories(language).first;
      final repo = FakeCategoriesRepository(
        pages: {category.slug: categoryPageOf(category)},
        articles: {category.slug: [categoryCards(language: language)]},
      );
      usePhoneSurface(tester, size: const Size(390, 940));
      final header = CategoryPageCubit(GetCategoryPage(repo));
      final articles = CategoryArticlesCubit(GetCategoryArticles(repo), categoryWriter.username, category.slug);
      final cards = PostCardsCubit.withLoader(previewLoader());
      addTearDown(header.close);
      addTearDown(articles.close);
      addTearDown(cards.close);
      unawaited(header.load(categoryWriter.username, category.slug));
      unawaited(articles.load());
      await tester.pumpWidget(testApp(
        provided(
          [
            ...appStores(),
            BlocProvider<CategoryPageCubit>.value(value: header),
            BlocProvider<CategoryArticlesCubit>.value(value: articles),
            BlocProvider<PostCardsCubit>.value(value: cards),
          ],
          CategoryView(username: categoryWriter.username),
        ),
        variant: variant,
      ));
      await tester.pump();
      await tester.pump();
      await expectLater(find.byType(CategoryView), matchesVariantGolden(variant, 'goldens/category_page_${variant.name}.png'));
    });

    testWidgets('editor category picker ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 760));
      final categories = ownCategories(language);
      final editor = MockArticleEditorCubit();
      whenListen(
        editor,
        const Stream<ArticleEditorState>.empty(),
        initialState: ArticleEditorState(
          document: mixedDocument(),
          activeLanguage: language,
          loadStatus: EditorLoadStatus.ready,
          fields: editorFields,
          topics: editorTopics,
          categories: categories,
          categoriesStatus: EditorLoadStatus.ready,
          categoryId: categories.first.id,
        ),
      );
      final suggestions = MockTagSuggestionsCubit();
      whenListen(suggestions, const Stream<List<ArticleTag>>.empty(), initialState: const <ArticleTag>[]);
      when(() => suggestions.search(any())).thenReturn(null);
      final attachments = MockAttachmentsCubit();
      whenListen(attachments, const Stream<AttachmentsState>.empty(), initialState: const AttachmentsState());
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<ArticleEditorCubit>.value(value: editor),
            BlocProvider<TagSuggestionsCubit>.value(value: suggestions),
            BlocProvider<AttachmentsCubit>.value(value: attachments),
          ],
          child: const Scaffold(body: SafeArea(child: ArticleSettingsPanel())),
        ),
        variant: variant,
      ));
      await tester.pump();
      // The field with the article's category and its hint, under the field and topic.
      await expectLater(find.byType(ArticleSettingsPanel), matchesVariantGolden(variant, 'goldens/editor_category_picker_${variant.name}.png'));

      // Its menu: no category, the writer's categories in their order, then "New category".
      final picker = find.byWidgetPredicate((w) => w is DropdownButtonFormField<String?> && '${w.key}'.contains('settings-category'));
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesVariantGolden(variant, 'goldens/editor_category_menu_${variant.name}.png'));
    });
  }
}
