import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/models/cursor_page.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/cubit/article_live_cubit.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/pages/article_page.dart';
import 'package:readin/features/article/presentation/widgets/reader_action_bar.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/domain/entities/follow.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/follow/presentation/widgets/follow_button.dart';
import 'package:readin/features/reactions/domain/entities/reactions.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/reactions/presentation/cubit/reactors_cubit.dart';
import 'package:readin/features/reactions/presentation/widgets/reaction_button.dart';
import 'package:readin/features/saved/domain/entities/saved.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/saved_list_cubit.dart';
import 'package:readin/features/saved/presentation/pages/saved_page.dart';
import 'package:readin/features/saved/presentation/widgets/add_to_collection_sheet.dart';
import 'package:readin/features/saved/presentation/widgets/save_button.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';
import 'package:readin/shared/widgets/badges.dart';

import '../helpers/fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

const _en = Variant(AppLocales.en, Brightness.light);

void main() {
  late MockReactionsRepository reactions;
  late MockSavedRepository saved;
  late MockFollowRepository followRepository;
  late EngagementCubit engagement;
  late FollowsCubit follows;
  late CollectionsCubit collections;

  final card = engagedCard(1); // not reacted, not saved

  setUpAll(() {
    registerFallbackValue(card);
    registerFallbackValue(ReactionType.insightful);
  });

  setUp(() {
    reactions = MockReactionsRepository();
    saved = MockSavedRepository();
    followRepository = MockFollowRepository();
    engagement = EngagementCubit(SetReaction(reactions), SetSaved(saved));
    follows = FollowsCubit(SetFollowing(followRepository));
    collections = CollectionsCubit(GetCollections(saved), ManageCollections(saved), engagement);
    when(() => saved.getCollections()).thenAnswer((_) async => Ok(sampleCollections));
  });

  tearDown(() async {
    await collections.close();
    await follows.close();
    await engagement.close();
  });

  MockSessionCubit session({bool signedIn = true}) {
    final cubit = MockSessionCubit();
    whenListen(
      cubit,
      const Stream<SessionState>.empty(),
      initialState: signedIn ? const SessionState(status: SessionStatus.authenticated, me: sampleMe) : const SessionState(status: SessionStatus.guest),
    );
    return cubit;
  }

  Future<void> pump(WidgetTester tester, Widget child, {bool signedIn = true, List<BlocProvider> providers = const []}) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session(signedIn: signedIn)),
          BlocProvider<EngagementCubit>.value(value: engagement),
          BlocProvider<FollowsCubit>.value(value: follows),
          BlocProvider<CollectionsCubit>.value(value: collections),
          ...providers,
        ],
        child: Scaffold(body: child),
      ),
      variant: _en,
    ));
    await tester.pump();
  }

  ArticleReactions answer(ReactionType? mine) => ArticleReactions(
        reactions: const ReactionCounts(insightful: 12, love: 3, fire: 1).move(to: mine),
        total: mine == null ? 16 : 17,
        myReaction: mine,
      );

  group('reaction button (F10)', () {
    testWidgets('a tap reacts with 💡; a tap on it again removes it', (tester) async {
      when(() => reactions.react(card.id, ReactionType.insightful)).thenAnswer((_) async => Ok(answer(ReactionType.insightful)));
      when(() => reactions.removeReaction(card.id)).thenAnswer((_) async => Ok(answer(null)));
      await pump(tester, Center(child: ReactionButton(article: card)));

      expect(find.bySemanticsLabel('React with 💡 Insightful'), findsOneWidget);
      await tester.tap(find.byType(ReactionButton));
      await tester.pump();
      expect(find.text('💡'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove your reaction (Insightful)'), findsOneWidget);

      await tester.tap(find.byType(ReactionButton));
      await tester.pump();
      verify(() => reactions.removeReaction(card.id)).called(1);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    });

    testWidgets('a long press opens the picker; choosing changes the reaction', (tester) async {
      when(() => reactions.react(card.id, ReactionType.fire)).thenAnswer((_) async => Ok(answer(ReactionType.fire)));
      await pump(tester, Align(alignment: Alignment.bottomCenter, child: ReactionButton(article: card)));

      await tester.longPress(find.byType(ReactionButton));
      await tester.pumpAndSettle();
      expect(find.text('Mind-blown'), findsOneWidget);

      await tester.tap(find.text('Fire'));
      await tester.pumpAndSettle();
      verify(() => reactions.react(card.id, ReactionType.fire)).called(1);
      expect(find.text('Mind-blown'), findsNothing, reason: 'the picker closed');
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets('a refused reaction rolls back and says why', (tester) async {
      when(() => reactions.react(any(), any())).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      await pump(tester, Center(child: ReactionButton(article: card)));

      await tester.tap(find.byType(ReactionButton));
      await tester.pump();
      await tester.pump();

      expect(find.text("You're offline. Check your connection."), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    });

    testWidgets('guests get the sign-in prompt and nothing is sent', (tester) async {
      await pump(tester, Center(child: ReactionButton(article: card)), signedIn: false);

      await tester.tap(find.byType(ReactionButton));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to continue'), findsOneWidget);

      verifyNever(() => reactions.react(any(), any()));
    });

    testWidgets('the counts open "who reacted", one tab per type', (tester) async {
      getIt.registerFactory<ReactorsCubit>(() => ReactorsCubit(GetReactors(reactions)));
      addTearDown(() => getIt.unregister<ReactorsCubit>());
      when(() => reactions.getReactors(card.id, type: any(named: 'type'), cursor: any(named: 'cursor'), limit: 20))
          .thenAnswer((invocation) async {
        final type = invocation.namedArguments[#type] as ReactionType?;
        return Ok(CursorPage(items: [for (final r in sampleReactors) if (type == null || r.type == type) r]));
      });
      await pump(tester, Align(alignment: Alignment.bottomCenter, child: ReaderActionBar(article: card)));

      await tester.tap(find.text('💡 12'));
      await tester.pumpAndSettle();
      expect(find.text('Reactions'), findsOneWidget);
      expect(find.text('Omar Khaled'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.text('❤️ 3')));
      await tester.pumpAndSettle();
      verify(() => reactions.getReactors(card.id, type: ReactionType.love, cursor: null, limit: 20)).called(1);
      expect(find.text('منى عبد الله'), findsNothing);
    });
  });

  group('save (F13)', () {
    testWidgets('save, then unsave with undo', (tester) async {
      when(() => saved.save(any())).thenAnswer((_) async => const Ok(SaveState(isSaved: true, saveCount: 8)));
      when(() => saved.unsave(card.id)).thenAnswer((_) async => const Ok(SaveState(isSaved: false, saveCount: 7)));
      await pump(tester, Center(child: SaveToggleButton(article: card)));

      await tester.tap(find.byTooltip('Save'));
      await tester.pump();
      expect(find.text('Saved. You can read it offline too.'), findsOneWidget);
      expect(find.byTooltip('Remove from saved'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove from saved'));
      await tester.pump();
      expect(find.text('Removed from saved'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500)); // the snack bar slides in
      await tester.tap(find.text('Undo'));
      await tester.pump();
      verify(() => saved.save(any())).called(2);
      expect(engagement.of(card).isSaved, isTrue);
    });

    testWidgets('a refused save rolls back and says why', (tester) async {
      when(() => saved.save(any())).thenAnswer((_) async => const Err(Failure(FailureCodes.rateLimited)));
      await pump(tester, Center(child: SaveToggleButton(article: card)));

      await tester.tap(find.byTooltip('Save'));
      await tester.pump();

      expect(find.text('Too many requests. Please try again shortly.'), findsOneWidget);
      expect(find.byTooltip('Save'), findsOneWidget);
    });
  });

  group('add to collection (F13)', () {
    testWidgets('ticking a collection saves the article first, then adds it', (tester) async {
      when(() => saved.save(any())).thenAnswer((_) async => const Ok(SaveState(isSaved: true, saveCount: 8)));
      when(() => saved.addToCollection('c-2', card.id)).thenAnswer((_) async => const Ok(null));
      await pump(tester, Builder(builder: (context) => TextButton(onPressed: () => showAddToCollectionSheet(context, card), child: const Text('open'))));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekend reads'));
      await tester.pumpAndSettle();

      verifyInOrder([() => saved.save(any()), () => saved.addToCollection('c-2', card.id)]);
      expect(collections.state.collectionsOf(card.id), {'c-2'});
      expect(tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Weekend reads')).value, isTrue);
    });

    testWidgets('a new collection: a taken name stays in the dialog; then it is created and filled', (tester) async {
      final mine = engagedCard(1, isSaved: true);
      when(() => saved.createCollection('Weekend reads')).thenAnswer((_) async => const Err(Failure(FailureCodes.collectionNameTaken)));
      when(() => saved.createCollection('Backend')).thenAnswer(
        (_) async => Ok(ArticleCollection(id: 'c-9', name: 'Backend', articleCount: 0, createdAt: DateTime.utc(2026))),
      );
      when(() => saved.addToCollection('c-9', mine.id)).thenAnswer((_) async => const Ok(null));
      await pump(tester, Builder(builder: (context) => TextButton(onPressed: () => showAddToCollectionSheet(context, mine), child: const Text('open'))));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New collection'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Weekend reads');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(find.text('You already have a collection with this name.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Backend');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      verify(() => saved.addToCollection('c-9', mine.id)).called(1);
      verifyNever(() => saved.save(any()));
      expect(find.widgetWithText(CheckboxListTile, 'Backend'), findsOneWidget);
    });

    testWidgets('guests get the sign-in prompt', (tester) async {
      await pump(
        tester,
        Builder(builder: (context) => TextButton(onPressed: () => showAddToCollectionSheet(context, card), child: const Text('open'))),
        signedIn: false,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to continue'), findsOneWidget);
      verifyNever(() => saved.getCollections());
    });
  });

  group('follow (F12)', () {
    testWidgets('hidden on your own articles', (tester) async {
      await pump(tester, const FollowButton(userId: 'u-1', name: 'Youssef'));
      expect(find.byType(FollowButtonView), findsNothing);
    });

    testWidgets('follow applies at once; a refusal rolls back and says why', (tester) async {
      final answer = Completer<Result<FollowState>>();
      when(() => followRepository.follow('w-2')).thenAnswer((_) => answer.future);
      await pump(tester, const Center(child: FollowButton(userId: 'w-2', name: 'Omar')));

      await tester.tap(find.text('Follow'));
      await tester.pump();
      expect(find.text('Following'), findsOneWidget);
      expect(find.bySemanticsLabel('Unfollow Omar'), findsOneWidget);

      answer.complete(const Err(Failure(FailureCodes.followSelf)));
      await tester.pump();
      await tester.pump();
      expect(find.text('Follow'), findsOneWidget);
      expect(find.text("You can't follow yourself."), findsOneWidget);
    });

    testWidgets('guests see "Follow" and get the sign-in prompt', (tester) async {
      await pump(tester, const Center(child: FollowButton(userId: 'w-2', name: 'Omar', initiallyFollowing: true)), signedIn: false);
      expect(find.text('Follow'), findsOneWidget);
      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to continue'), findsOneWidget);
    });
  });

  group('Saved tab (F13)', () {
    late MockSavedListCubit list;

    setUp(() {
      list = MockSavedListCubit();
      whenListen(
        list,
        const Stream<SavedListState>.empty(),
        initialState: SavedListState(status: SavedListStatus.ready, items: sampleSaved(language: 'en'), fields: sampleFields),
      );
      when(() => list.selectCollection(any())).thenAnswer((_) async {});
    });

    testWidgets('typing searches; a collection opens its articles', (tester) async {
      await pump(tester, const SavedView(), providers: [BlocProvider<SavedListCubit>.value(value: list)]);

      await tester.enterText(find.byType(TextField), 'DI');
      verify(() => list.search('DI')).called(1);

      await tester.tap(find.text('Collections'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekend reads'));
      await tester.pumpAndSettle();
      verify(() => list.selectCollection('c-2')).called(1);
      expect(find.text('Search your saved articles'), findsOneWidget, reason: 'back on the articles tab');
    });

    testWidgets('deleting a collection asks first', (tester) async {
      when(() => saved.deleteCollection('c-3')).thenAnswer((_) async => const Ok(null));
      await pump(tester, const SavedView(initialTab: 1), providers: [BlocProvider<SavedListCubit>.value(value: list)]);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More actions').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete “AI agents”?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      verify(() => saved.deleteCollection('c-3')).called(1);
      expect(find.text('AI agents'), findsNothing);
    });
  });

  group('reader (F04, F25, F27)', () {
    setUp(registerNoRelatedArticles);

    Future<StreamController<LiveArticleCounts?>> pumpReader(
      WidgetTester tester, {
      bool offline = false,
      List<String> collectionIds = const [],
      bool authorDeleted = false,
    }) async {
      final article = ArticleDetails(
        card: engagedCard(1, language: 'en', isSaved: collectionIds.isNotEmpty, authorDeleted: authorDeleted),
        availableLanguages: const ['en'],
        content: RDocDocument.fromJson(detailsJson(1, language: 'en')['content'] as Map<String, dynamic>),
        isFollowingAuthor: !authorDeleted,
        collectionIds: collectionIds,
        isOfflineCopy: offline,
      );
      final articleCubit = MockArticleCubit();
      final settings = MockSettingsCubit();
      final live = StreamController<LiveArticleCounts?>.broadcast();
      final liveCubit = _StreamLiveCubit(live.stream);
      whenListen(articleCubit, const Stream<ArticleState>.empty(), initialState: ArticleState(status: ArticleStatus.ready, article: article));
      whenListen(settings, const Stream<AppSettings>.empty(), initialState: const AppSettings());
      await pump(
        tester,
        const ArticleView(),
        providers: [
          BlocProvider<ArticleCubit>.value(value: articleCubit),
          BlocProvider<ArticleLiveCubit>.value(value: liveCubit),
          BlocProvider<SettingsCubit>.value(value: settings),
        ],
      );
      addTearDown(live.close);
      return live;
    }

    testWidgets('a loaded article seeds the follow state and starts live counters, which replace the counts', (tester) async {
      final live = await pumpReader(tester);
      expect(follows.state.isFollowing('a-1'), isTrue);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('💡 12'), findsOneWidget);

      live.add(const LiveArticleCounts(reactions: {ReactionType.insightful: 30}, commentCount: 9));
      await tester.pump();
      await tester.pump();
      expect(find.text('💡 30'), findsOneWidget);
      expect(find.text('❤️ 3'), findsNothing, reason: 'replaced, not added');
      expect(find.bySemanticsLabel('9 comments'), findsOneWidget);
    });

    testWidgets('a deleted author reads as "Deleted user", with nobody to follow; the rest still works (SPEC §9.6)',
        (tester) async {
      final live = await pumpReader(tester, authorDeleted: true);
      expect(find.text('Deleted user'), findsOneWidget);
      expect(find.byType(GenericAvatar), findsOneWidget);
      expect(find.byType(FollowButton), findsNothing);
      expect(follows.state.users, isEmpty, reason: 'no follow to seed');
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('null'), findsNothing);
      expect(engagement.state.overlays, isNotEmpty, reason: 'counters are seeded as usual');

      live.add(const LiveArticleCounts(reactions: {ReactionType.insightful: 30}, commentCount: 9));
      await tester.pump();
      await tester.pump();
      expect(find.text('💡 30'), findsOneWidget);
    });

    testWidgets('an offline copy says so and seeds nothing', (tester) async {
      await pumpReader(tester, offline: true, collectionIds: const ['c-1']);
      expect(find.text('Offline copy, saved on this device'), findsOneWidget);
      expect(engagement.state.overlays, isEmpty);
      expect(collections.state.membership, isEmpty);
    });

    testWidgets("add to collection opens with the article's collections ticked and keeps them in step", (tester) async {
      // textContaining: in the English UI the Arabic name is wrapped in bidi isolates.
      bool ticked(String name) => tester
          .widget<CheckboxListTile>(find.ancestor(of: find.textContaining(name), matching: find.byType(CheckboxListTile)))
          .value!;
      await pumpReader(tester, collectionIds: const ['c-2', 'c-1']);

      await tester.tap(find.byTooltip('Add to collection'));
      await tester.pumpAndSettle();
      expect(ticked('تحضير الإنترفيو'), isTrue);
      expect(ticked('Weekend reads'), isTrue);
      expect(ticked('AI agents'), isFalse);

      // Taking it out is refused: the tick comes back and the sheet says why.
      when(() => saved.removeFromCollection('c-2', 'art-1')).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      await tester.tap(find.text('Weekend reads'));
      await tester.pumpAndSettle();
      expect(ticked('Weekend reads'), isTrue);
      expect(find.text("You're offline. Check your connection."), findsOneWidget);

      // Putting it in: already saved, so no save request; the new collection goes last.
      when(() => saved.addToCollection('c-3', 'art-1')).thenAnswer((_) async => const Ok(null));
      await tester.tap(find.text('AI agents'));
      await tester.pumpAndSettle();
      expect(ticked('AI agents'), isTrue);
      expect(collections.state.collectionsOf('art-1').toList(), ['c-2', 'c-1', 'c-3']);
      verifyNever(() => saved.save(any()));
    });
  });

  // SPEC §26: font scaling up to 200% without broken layouts (an overflow fails the test).
  testWidgets('the action bar, a reacted card and the follow button hold at 200% text', (tester) async {
    usePhoneSurface(tester, size: const Size(360, 640));
    final mine = engagedCard(2, myReaction: ReactionType.mindBlown, isSaved: true);
    await tester.pumpWidget(testApp(
      MediaQuery.withClampedTextScaling(
        minScaleFactor: 2,
        maxScaleFactor: 2,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session()),
            BlocProvider<EngagementCubit>.value(value: engagement),
            BlocProvider<FollowsCubit>.value(value: follows),
          ],
          child: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Padding(padding: EdgeInsets.all(16), child: FollowButton(userId: 'w-2', name: 'Omar')),
                ReaderActionBar(article: mine),
              ],
            ),
          ),
        ),
      ),
      variant: const Variant(AppLocales.ar, Brightness.light),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

/// [ArticleLiveCubit] whose values come from a test stream.
class _StreamLiveCubit extends Cubit<LiveArticleCounts?> implements ArticleLiveCubit {
  _StreamLiveCubit(Stream<LiveArticleCounts?> values) : super(null) {
    _subscription = values.listen(emit);
  }

  late final StreamSubscription<LiveArticleCounts?> _subscription;
  final watched = <String>[];

  @override
  void watch(String articleId) => watched.add(articleId);

  @override
  Future<void> pause() async {}

  @override
  void resume() {}

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
