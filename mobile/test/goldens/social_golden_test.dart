@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/cubit/article_live_cubit.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/pages/article_page.dart';
import 'package:readin/features/article/presentation/widgets/article_card_tile.dart';
import 'package:readin/features/article/presentation/widgets/reader_action_bar.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/suggested_writers_cubit.dart';
import 'package:readin/features/follow/presentation/widgets/follow_button.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/home/presentation/cubit/home_cubit.dart';
import 'package:readin/features/home/presentation/cubit/live_feed_cubit.dart';
import 'package:readin/features/home/presentation/pages/home_page.dart';
import 'package:readin/features/home/presentation/widgets/today_hero_card.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/reactions/presentation/cubit/reactors_cubit.dart';
import 'package:readin/features/reactions/presentation/widgets/reaction_picker.dart';
import 'package:readin/features/reactions/presentation/widgets/who_reacted_sheet.dart';
import 'package:readin/features/reading/domain/entities/reading.dart';
import 'package:readin/features/reading/presentation/cubit/streak_cubit.dart';
import 'package:readin/features/saved/domain/entities/saved.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/saved_list_cubit.dart';
import 'package:readin/features/saved/presentation/pages/saved_page.dart';
import 'package:readin/features/saved/presentation/widgets/save_button.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../helpers/fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class MockReactorsCubit extends MockCubit<ReactorsState> implements ReactorsCubit {}

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockFeedCubit extends MockCubit<FeedState> implements FeedCubit {}

class MockFollowingFeedCubit extends MockCubit<FeedState> implements FollowingFeedCubit {}

class MockSuggestedWritersCubit extends MockCubit<SuggestedWritersState> implements SuggestedWritersCubit {}

class MockLiveFeedCubit extends MockCubit<LiveFeedState> implements LiveFeedCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

class MockStreakCubit extends MockCubit<Streak?> implements StreakCubit {}

class MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

class MockArticleLiveCubit extends MockCubit<LiveArticleCounts?> implements ArticleLiveCubit {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

/// Reactions, follow and Saved (wave 1: F10, F12, F13) in ar/en × light/dark (SPEC §8.2).
void main() {
  setUp(() => HomeView.clock = () => DateTime(2026, 11, 2, 9));
  tearDown(() => HomeView.clock = DateTime.now);

  String languageOf(Variant variant) => variant.locale.languageCode == 'en' ? 'en' : 'ar-EG';

  MockSessionCubit session({bool signedIn = true}) {
    final cubit = MockSessionCubit();
    whenListen(
      cubit,
      const Stream<SessionState>.empty(),
      initialState: signedIn ? const SessionState(status: SessionStatus.authenticated, me: sampleMe) : const SessionState(status: SessionStatus.guest),
    );
    return cubit;
  }

  MockEngagementCubit engagement([EngagementState state = const EngagementState()]) {
    final cubit = MockEngagementCubit();
    whenListen(cubit, const Stream<EngagementState>.empty(), initialState: state);
    return cubit;
  }

  MockFollowsCubit follows([FollowsState state = const FollowsState()]) {
    final cubit = MockFollowsCubit();
    whenListen(cubit, const Stream<FollowsState>.empty(), initialState: state);
    when(() => cubit.changes).thenAnswer((_) => const Stream.empty());
    return cubit;
  }

  MockCollectionsCubit collections(CollectionsState state) {
    final cubit = MockCollectionsCubit();
    whenListen(cubit, const Stream<CollectionsState>.empty(), initialState: state);
    when(() => cubit.load(force: any(named: 'force'))).thenAnswer((_) async {});
    return cubit;
  }

  Future<void> pump(WidgetTester tester, Variant variant, Widget child, {Size size = const Size(390, 844), List<BlocProvider> providers = const []}) async {
    usePhoneSurface(tester, size: size);
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session()),
          BlocProvider<EngagementCubit>.value(value: engagement()),
          BlocProvider<FollowsCubit>.value(value: follows()),
          ...providers,
        ],
        child: child,
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  for (final variant in Variant.all) {
    final language = languageOf(variant);

    testWidgets('reader action bar ${variant.name}', (tester) async {
      await pump(
        tester,
        variant,
        Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ReaderActionBar(article: engagedCard(0, language: language)),
              const SizedBox(height: 24),
              ReaderActionBar(article: engagedCard(1, myReaction: ReactionType.love, isSaved: true, language: language)),
              const SizedBox(height: 24),
              ReaderActionBar(article: sampleCard(2, language: language).copyWithEngagement(reactionCount: 0, commentCount: 0)),
            ],
          ),
        ),
        size: const Size(390, 300),
      );
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/reader_action_bar_${variant.name}.png'));
    });

    testWidgets('reaction picker ${variant.name}', (tester) async {
      await pump(
        tester,
        variant,
        Scaffold(body: Center(child: ReactionPicker(selected: ReactionType.love, onSelected: (_) {}))),
        size: const Size(390, 160),
      );
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/reaction_picker_${variant.name}.png'));
    });

    testWidgets('who reacted ${variant.name}', (tester) async {
      ReactorsCubit cubitFor(ReactionType? type) {
        final cubit = MockReactorsCubit();
        whenListen(
          cubit,
          const Stream<ReactorsState>.empty(),
          initialState: ReactorsState(
            status: ReactorsStatus.ready,
            items: [for (final r in sampleReactors) if (type == null || r.type == type) r],
            nextCursor: 'more',
          ),
        );
        when(cubit.loadMore).thenAnswer((_) async {});
        return cubit;
      }

      await pump(
        tester,
        variant,
        Scaffold(
          body: SafeArea(
            child: WhoReactedView(reactions: const ReactionCounts(insightful: 12, love: 3, fire: 1), total: 16, cubitFor: cubitFor),
          ),
        ),
        size: const Size(390, 560),
      );
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/who_reacted_${variant.name}.png'));
    });

    testWidgets('follow button states ${variant.name}', (tester) async {
      await pump(
        tester,
        variant,
        Scaffold(
          body: Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FollowButtonView(following: false, name: 'Omar', onPressed: () {}),
                FollowButtonView(following: true, name: 'Omar', onPressed: () {}),
                FollowButtonView(following: true, pending: true, name: 'Omar', onPressed: () {}),
                FollowButtonView(following: false, pending: true, name: 'Omar', onPressed: () {}),
                FollowButtonView(following: false, dense: true, name: 'Omar', onPressed: () {}),
                FollowButtonView(following: true, dense: true, name: 'Omar', onPressed: () {}),
              ],
            ),
          ),
        ),
        size: const Size(390, 220),
      );
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/follow_button_states_${variant.name}.png'));
    });

    Future<void> pumpSaved(WidgetTester tester, SavedListState list, {int tab = 0, CollectionsState? collectionsState}) async {
      final listCubit = MockSavedListCubit();
      whenListen(listCubit, const Stream<SavedListState>.empty(), initialState: list);
      await pump(
        tester,
        variant,
        SavedView(initialTab: tab),
        providers: [
          BlocProvider<SavedListCubit>.value(value: listCubit),
          BlocProvider<CollectionsCubit>.value(
            value: collections(collectionsState ?? CollectionsState(status: CollectionsStatus.ready, items: sampleCollections)),
          ),
        ],
      );
    }

    testWidgets('saved list ${variant.name}', (tester) async {
      await pumpSaved(
        tester,
        SavedListState(status: SavedListStatus.ready, items: sampleSaved(language: language), fields: sampleFields),
      );
      await expectLater(find.byType(SavedView), matchesGoldenFile('goldens/saved_list_${variant.name}.png'));
    });

    testWidgets('saved list offline, one collection ${variant.name}', (tester) async {
      await pumpSaved(
        tester,
        SavedListState(
          status: SavedListStatus.ready,
          items: sampleSaved(language: language).take(1).toList(),
          fields: sampleFields,
          offline: true,
          filter: const SavedFilter(collectionId: 'c-1'),
        ),
      );
      await expectLater(find.byType(SavedView), matchesGoldenFile('goldens/saved_list_offline_${variant.name}.png'));
    });

    testWidgets('saved empty ${variant.name}', (tester) async {
      await pumpSaved(tester, const SavedListState(status: SavedListStatus.ready, fields: sampleFields));
      await expectLater(find.byType(SavedView), matchesGoldenFile('goldens/saved_empty_${variant.name}.png'));
    });

    testWidgets('saved collections ${variant.name}', (tester) async {
      await pumpSaved(tester, const SavedListState(status: SavedListStatus.ready), tab: 1);
      await tester.pumpAndSettle();
      await expectLater(find.byType(SavedView), matchesGoldenFile('goldens/saved_collections_${variant.name}.png'));
    });

    testWidgets('saved collections empty ${variant.name}', (tester) async {
      await pumpSaved(
        tester,
        const SavedListState(status: SavedListStatus.ready),
        tab: 1,
        collectionsState: const CollectionsState(status: CollectionsStatus.ready),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(SavedView), matchesGoldenFile('goldens/saved_collections_empty_${variant.name}.png'));
    });

    testWidgets('following tab, nobody followed yet ${variant.name}', (tester) async {
      final home = MockHomeCubit();
      final feed = MockFeedCubit();
      final following = MockFollowingFeedCubit();
      final suggested = MockSuggestedWritersCubit();
      final live = MockLiveFeedCubit();
      final badge = MockUnreadBadgeCubit();
      whenListen(home, const Stream<HomeState>.empty(), initialState: const HomeState(loading: false, fields: sampleFields));
      whenListen(feed, const Stream<FeedState>.empty(), initialState: const FeedState(status: FeedStatus.ready));
      whenListen(following, const Stream<FeedState>.empty(), initialState: const FeedState(status: FeedStatus.ready));
      whenListen(
        suggested,
        const Stream<SuggestedWritersState>.empty(),
        initialState: const SuggestedWritersState(status: SuggestedWritersStatus.ready, users: sampleWriters),
      );
      whenListen(live, const Stream<LiveFeedState>.empty(), initialState: const LiveFeedState());
      whenListen(badge, const Stream<int>.empty(), initialState: 0);
      final streak = MockStreakCubit(); // not loaded yet (F08)
      whenListen(streak, const Stream<Streak?>.empty(), initialState: null);
      when(following.ensureLoaded).thenAnswer((_) async {});
      when(suggested.ensureLoaded).thenAnswer((_) async {});

      await pump(
        tester,
        variant,
        const HomeView(initialTab: HomeFeedTab.following),
        size: const Size(390, 900),
        providers: [
          BlocProvider<HomeCubit>.value(value: home),
          BlocProvider<FeedCubit>.value(value: feed),
          BlocProvider<FollowingFeedCubit>.value(value: following),
          BlocProvider<SuggestedWritersCubit>.value(value: suggested),
          BlocProvider<LiveFeedCubit>.value(value: live),
          BlocProvider<UnreadBadgeCubit>.value(value: badge),
          BlocProvider<StreakCubit>.value(value: streak),
        ],
      );
      await expectLater(find.byType(HomeView), matchesGoldenFile('goldens/home_following_empty_${variant.name}.png'));
    });

    Future<void> pumpReader(WidgetTester tester, ArticleCard card) async {
      registerNoRelatedArticles();
      final article = ArticleDetails(
        card: card,
        availableLanguages: [language],
        content: RDocDocument.fromJson(detailsJson(1, language: language)['content'] as Map<String, dynamic>),
        isFollowingAuthor: false,
      );
      final articleCubit = MockArticleCubit();
      final liveCubit = MockArticleLiveCubit();
      final settings = MockSettingsCubit();
      whenListen(articleCubit, const Stream<ArticleState>.empty(), initialState: ArticleState(status: ArticleStatus.ready, article: article));
      whenListen(liveCubit, const Stream<LiveArticleCounts?>.empty(), initialState: null);
      whenListen(settings, const Stream<AppSettings>.empty(), initialState: const AppSettings());

      await pump(
        tester,
        variant,
        const ArticleView(),
        size: const Size(390, 640),
        providers: [
          BlocProvider<ArticleCubit>.value(value: articleCubit),
          BlocProvider<ArticleLiveCubit>.value(value: liveCubit),
          BlocProvider<SettingsCubit>.value(value: settings),
          BlocProvider<CollectionsCubit>.value(value: collections(const CollectionsState())),
        ],
      );
    }

    testWidgets('reader with follow and actions ${variant.name}', (tester) async {
      await pumpReader(tester, engagedCard(1, myReaction: ReactionType.insightful, language: language));
      await expectLater(find.byType(ArticleView), matchesGoldenFile('goldens/reader_social_${variant.name}.png'));
    });

    // SPEC §9.6: a deleted account's published articles stay up under "Deleted user".
    testWidgets('reader by a deleted user ${variant.name}', (tester) async {
      await pumpReader(tester, engagedCard(1, myReaction: ReactionType.insightful, language: language, authorDeleted: true));
      expect(find.byType(FollowButton), findsNothing);
      await expectLater(find.byType(ArticleView), matchesGoldenFile('goldens/reader_deleted_author_${variant.name}.png'));
    });

    testWidgets("today's article and a feed card by a deleted user ${variant.name}", (tester) async {
      await pump(
        tester,
        variant,
        Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TodayHeroCard(article: sampleCard(0, language: language, authorDeleted: true), onTap: () {}),
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final card = engagedCard(1, language: language, authorDeleted: true);
                    return ArticleCardTile(article: card, onTap: () {}, actions: [SaveToggleButton(article: card)]);
                  }),
                ],
              ),
            ),
          ),
        ),
        size: const Size(390, 560),
      );
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/feed_cards_deleted_author_${variant.name}.png'));
    });
  }
}
