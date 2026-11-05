@Tags(['golden'])
library;

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart' show CommentClock;
import 'package:readin/features/editor/domain/entities/editor_entities.dart';
import 'package:readin/features/editor/presentation/cubit/article_editor_cubit.dart';
import 'package:readin/features/editor/presentation/cubit/tag_suggestions_cubit.dart';
import 'package:readin/features/editor/presentation/widgets/article_settings_sheet.dart';
import 'package:readin/features/media/presentation/cubit/attachments_cubit.dart';
import 'package:readin/features/tags/domain/usecases/tag_usecases.dart';
import 'package:readin/features/tags/presentation/cubit/tag_cubits.dart';
import 'package:readin/features/tags/presentation/pages/tag_page.dart';

import '../helpers/editor_fixtures.dart';
import '../helpers/post_card_fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/tag_fixtures.dart';
import '../helpers/test_app.dart';

/// Tags (F32) in ar/light and en/dark (SPEC §27): a tag page with its post cards, an empty tag page, and the editor's
/// tag field with chips, suggestions and "Create new tag".
void main() {
  bool isEn(Variant variant) => variant.locale.languageCode == 'en';
  String languageOf(Variant variant) => isEn(variant) ? 'en' : 'ar-EG';
  // Post cards say how long ago they were published: a fixed "now" keeps the images from changing day by day.
  setUp(() => CommentClock.now = () => DateTime.utc(2026, 11, 4, 18)); // "5 days ago"
  tearDown(() => CommentClock.now = DateTime.now);

  Future<void> pumpTagPage(WidgetTester tester, Variant variant, FakeTagsRepository repo, String slug, {double height = 1400}) async {
    usePhoneSurface(tester, size: Size(390, height));
    final header = TagCubit(GetTag(repo));
    final articles = TagArticlesCubit(GetTagArticles(repo), slug);
    final cards = PostCardsCubit.withLoader(previewLoader());
    addTearDown(header.close);
    addTearDown(articles.close);
    addTearDown(cards.close);
    unawaited(header.load(slug));
    unawaited(articles.load());
    await tester.pumpWidget(testApp(
      provided(
        [
          ...appStores(),
          BlocProvider<TagCubit>.value(value: header),
          BlocProvider<TagArticlesCubit>.value(value: articles),
          BlocProvider<PostCardsCubit>.value(value: cards),
        ],
        const TagView(),
      ),
      variant: variant,
    ));
    await tester.pump();
    await tester.pump();
  }

  for (final variant in Variant.golden) {
    testWidgets('tag page ${variant.name}', (tester) async {
      final tag = pageTagFor(languageOf(variant));
      final repo = FakeTagsRepository(tags: [tag], pages: {tag.slug: [tagPageCards(tag, language: languageOf(variant))]});
      await pumpTagPage(tester, variant, repo, tag.slug, height: 940);
      await expectLater(find.byType(TagView), matchesVariantGolden(variant, 'goldens/tag_page_${variant.name}.png'));
    });

    testWidgets('tag page empty ${variant.name}', (tester) async {
      final repo = FakeTagsRepository(tags: const [emptyTag], pages: {'zig': const [[]]});
      await pumpTagPage(tester, variant, repo, 'zig', height: 700);
      await expectLater(find.byType(TagView), matchesVariantGolden(variant, 'goldens/tag_page_empty_${variant.name}.png'));
    });

    testWidgets('editor tag field ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 560));
      final en = isEn(variant);
      // A tag moderators hid since it was added: its chip and a message say so.
      final hidden = en ? 'jQuery' : 'قديم';
      final editor = MockArticleEditorCubit();
      whenListen(
        editor,
        const Stream<ArticleEditorState>.empty(),
        initialState: ArticleEditorState(
          document: mixedDocument().copyWith(tags: [...en ? const ['C#', '.NET'] : const ['C#', 'الذكاء الاصطناعي'], hidden]),
          activeLanguage: languageOf(variant),
          loadStatus: EditorLoadStatus.ready,
          fields: editorFields,
          topics: editorTopics,
          checks: DraftChecks(problems: [DraftProblem(DraftProblemCodes.tagHidden, tag: hidden)]),
          checksFresh: true,
        ),
      );
      final suggestions = MockTagSuggestionsCubit();
      whenListen(
        suggestions,
        const Stream<List<ArticleTag>>.empty(),
        initialState: en
            ? const [ArticleTag(slug: 'ai-agents', name: 'AI Agents', articleCount: 12), ArticleTag(slug: 'agentic-ai', name: 'Agentic AI', articleCount: 4)]
            : const [ArticleTag(slug: 'تعلم-الالة', name: 'تعلم الآلة', articleCount: 18), ArticleTag(slug: 'تعلم-عميق', name: 'تعلم عميق', articleCount: 6)],
      );
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
      await tester.enterText(find.byKey(const ValueKey('settings-tag-input')), en ? 'Agents' : 'تعلم');
      await tester.pump();
      // The sheet scrolled to its tag section.
      final section = find.ancestor(
        of: find.byKey(const ValueKey('settings-tag-input')),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_TagsSection'),
      );
      await tester.ensureVisible(section);
      await tester.pump();
      await expectLater(find.byType(ArticleSettingsPanel), matchesVariantGolden(variant, 'goldens/editor_tag_field_${variant.name}.png'));
    });
  }
}
