import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/widgets/reader_action_bar.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/reposts/data/datasources/reposts_api.dart';
import 'package:readin/features/reposts/data/models/repost_models.dart';
import 'package:readin/features/reposts/data/repositories/reposts_repository_impl.dart';
import 'package:readin/features/reposts/domain/entities/repost_state.dart';
import 'package:readin/features/reposts/domain/repositories/reposts_repository.dart';
import 'package:readin/features/reposts/domain/usecases/repost_usecases.dart';
import 'package:readin/features/reposts/presentation/widgets/repost_button.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockRepostsRepository extends Mock implements RepostsRepository {}

class MockRepostsApi extends Mock implements RepostsApi {}

/// Repost (F29): the optimistic toggle with rollback, the live counter, the button on cards and in the reader (own
/// article, guests, the count in its accessible name), the API mapping and the new card fields.
void main() {
  late MockRepostsRepository reposts;
  late EngagementCubit engagement;

  /// Someone else's article, reposted 3 times, not by the viewer.
  final card = engagedCard(1).copyWithEngagement(repostCount: 3);

  setUp(() {
    reposts = MockRepostsRepository();
    engagement = EngagementCubit(SetReaction(MockReactionsRepository()), SetSaved(MockSavedRepository()), SetReposted(reposts));
  });
  tearDown(() => engagement.close());

  group('the engagement store', () {
    test('a repost shows at once, then takes the API count', () async {
      final answer = Completer<Result<RepostState>>();
      when(() => reposts.repost(card.id)).thenAnswer((_) => answer.future);

      final done = engagement.toggleRepost(card);
      expect(engagement.of(card).isReposted, isTrue);
      expect(engagement.of(card).repostCount, 4);
      expect(engagement.of(card).reposting, isTrue);

      answer.complete(const Ok(RepostState(repostCount: 9, isReposted: true)));
      expect(await done, isNull);
      expect(engagement.of(card).repostCount, 9, reason: 'the API answer replaces the optimistic count');
      expect(engagement.of(card).reposting, isFalse);
    });

    test('undoing takes one off; a second tap while one is in flight is ignored', () async {
      final mine = card.copyWithEngagement(isReposted: true);
      final answer = Completer<Result<RepostState>>();
      when(() => reposts.undoRepost(mine.id)).thenAnswer((_) => answer.future);

      final done = engagement.toggleRepost(mine);
      expect(engagement.of(mine).isReposted, isFalse);
      expect(engagement.of(mine).repostCount, 2);
      expect(await engagement.toggleRepost(mine), isNull);
      verifyNever(() => reposts.repost(any()));

      answer.complete(const Ok(RepostState(repostCount: 2, isReposted: false)));
      await done;
      verify(() => reposts.undoRepost(mine.id)).called(1);
    });

    test('a refused repost rolls back and returns the failure (repost.own_article)', () async {
      when(() => reposts.repost(card.id)).thenAnswer((_) async => const Err(Failure(FailureCodes.repostOwnArticle)));

      final failure = await engagement.toggleRepost(card);
      expect(failure?.code, FailureCodes.repostOwnArticle);
      expect(engagement.of(card).isReposted, isFalse);
      expect(engagement.of(card).repostCount, 3);
      expect(engagement.of(card).reposting, isFalse);
    });

    test('a rollback keeps a reaction made meanwhile', () async {
      final answer = Completer<Result<RepostState>>();
      when(() => reposts.repost(card.id)).thenAnswer((_) => answer.future);
      final done = engagement.toggleRepost(card);
      engagement.applyLive(card.id, const LiveArticleCounts(commentCount: 40));
      answer.complete(const Err(Failure(FailureCodes.networkOffline)));
      await done;
      expect(engagement.of(card).commentCount, 40);
      expect(engagement.of(card).repostCount, 3);
    });

    test('live repostCount replaces the number, except while your own repost is in flight', () async {
      engagement.applyLive(card.id, const LiveArticleCounts(repostCount: 12));
      expect(engagement.of(card).repostCount, 12);

      final answer = Completer<Result<RepostState>>();
      when(() => reposts.repost(card.id)).thenAnswer((_) => answer.future);
      final done = engagement.toggleRepost(card);
      expect(engagement.of(card).repostCount, 13);
      engagement.applyLive(card.id, const LiveArticleCounts(repostCount: 12));
      expect(engagement.of(card).repostCount, 13, reason: 'the optimistic count stays until the API answers');
      answer.complete(const Ok(RepostState(repostCount: 13, isReposted: true)));
      await done;
      engagement.applyLive(card.id, const LiveArticleCounts(repostCount: 14));
      expect(engagement.of(card).repostCount, 14);
      expect(engagement.of(card).isReposted, isTrue, reason: 'live counters say nothing about the viewer');
    });

    test('seeded cards carry their repost count and state; applyTo copies them back', () {
      engagement.seed([card.copyWithEngagement(repostCount: 5, isReposted: true)]);
      expect(engagement.of(card).repostCount, 5);
      expect(engagement.of(card).isReposted, isTrue);
      final applied = engagement.of(card).applyTo(card);
      expect(applied.repostCount, 5);
      expect(applied.isReposted, isTrue);
    });
  });

  group('the Repost button', () {
    Future<void> pump(WidgetTester tester, Widget child, {bool signedIn = true, Variant variant = const Variant(AppLocales.en, Brightness.light)}) async {
      usePhoneSurface(tester);
      final session = MockSessionCubit();
      whenListen(
        session,
        const Stream<SessionState>.empty(),
        initialState:
            signedIn ? const SessionState(status: SessionStatus.authenticated, me: sampleMe) : const SessionState(status: SessionStatus.guest),
      );
      final follows = MockFollowsCubit();
      whenListen(follows, const Stream<FollowsState>.empty(), initialState: const FollowsState());
      final collections = MockCollectionsCubit();
      whenListen(collections, const Stream<CollectionsState>.empty(), initialState: const CollectionsState());
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<EngagementCubit>.value(value: engagement),
            BlocProvider<FollowsCubit>.value(value: follows),
            BlocProvider<CollectionsCubit>.value(value: collections),
          ],
          child: Scaffold(body: Center(child: child)),
        ),
        variant: variant,
      ));
      await tester.pump();
    }

    testWidgets("the count beside the icon (none at 0) and in its accessible name; the menu's Repost reposts", (tester) async {
      final semantics = tester.ensureSemantics();
      when(() => reposts.repost(card.id)).thenAnswer((_) async => const Ok(RepostState(repostCount: 4, isReposted: true)));
      await pump(tester, RepostButton(article: card));
      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsLabel('Repost, 3'), findsOneWidget);
      expect(tester.getSemantics(find.byType(RepostButton)), isSemantics(isButton: true, hasToggledState: true, isToggled: false));

      await tester.tap(find.byType(RepostButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('repost-menu-repost')));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
      final colors = tester.element(find.byType(RepostButton)).colors;
      expect(tester.widget<Icon>(find.byIcon(Icons.repeat_rounded)).color, colors.primary, reason: 'drawn in the primary color once reposted');
      expect(tester.getSemantics(find.byType(RepostButton)), isSemantics(isButton: true, hasToggledState: true, isToggled: true));
      verify(() => reposts.repost(card.id)).called(1);

      await pump(tester, RepostButton(article: engagedCard(2)));
      expect(find.text('0'), findsNothing);
      expect(find.bySemanticsLabel('Repost'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('Arabic: "إعادة نشر، 3"', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, RepostButton(article: card), variant: const Variant(AppLocales.ar, Brightness.light));
      expect(find.bySemanticsLabel('إعادة نشر، 3'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a refused repost rolls back and says why', (tester) async {
      when(() => reposts.repost(card.id)).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      await pump(tester, RepostButton(article: card));
      await tester.tap(find.byType(RepostButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('repost-menu-repost')));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
      expect(find.text("You're offline. Check your connection."), findsOneWidget);
    });

    testWidgets('your own article: faded, a tap says why, nothing is sent', (tester) async {
      final semantics = tester.ensureSemantics();
      final own = card.copyWithEngagement();
      final mine = ArticleCard(
        id: own.id,
        slug: own.slug,
        language: own.language,
        title: own.title,
        field: own.field,
        author: const Author(id: 'u-1', displayName: 'Youssef Hassan', username: 'reader1'),
        readingTimeMinutes: own.readingTimeMinutes,
        publishedAt: own.publishedAt,
        repostCount: 2,
      );
      await pump(tester, RepostButton(article: mine));
      expect(tester.widget<Opacity>(find.descendant(of: find.byType(RepostButton), matching: find.byType(Opacity))).opacity, lessThan(1));
      expect(tester.getSemantics(find.byType(RepostButton)), isSemantics(isButton: true, hasEnabledState: true, isEnabled: false, hint: "You can't repost your own article"));

      await tester.tap(find.byType(RepostButton));
      await tester.pump();
      expect(find.text("You can't repost your own article"), findsOneWidget);
      verifyNever(() => reposts.repost(any()));
      semantics.dispose();
    });

    testWidgets('guests get the sign-in prompt and nothing is sent', (tester) async {
      await pump(tester, RepostButton(article: card), signedIn: false);
      await tester.tap(find.byType(RepostButton));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to continue'), findsOneWidget);
      verifyNever(() => reposts.repost(any()));
    });

    testWidgets("the reader's action bar has Repost with its count next to the comments", (tester) async {
      await pump(tester, Align(alignment: Alignment.bottomCenter, child: ReaderActionBar(article: card)));
      expect(find.byType(RepostButton), findsOneWidget);
      final comments = tester.getCenter(find.byType(CommentCount)).dx;
      final repost = tester.getCenter(find.byType(RepostButton)).dx;
      expect(repost, greaterThan(comments), reason: 'right after the comments in English');
      expect(find.descendant(of: find.byType(RepostButton), matching: find.text('3')), findsOneWidget);
    });
  });

  group('API', () {
    test('PUT and DELETE /articles/{id}/repost map to the state', () async {
      final api = MockRepostsApi();
      final repository = RepostsRepositoryImpl(api);
      when(() => api.repost('a1')).thenAnswer((_) async => const RepostStateModel(repostCount: 4, isReposted: true));
      when(() => api.undoRepost('a1')).thenAnswer((_) async => const RepostStateModel(repostCount: 3));

      expect((await repository.repost('a1')).valueOrNull, const RepostState(repostCount: 4, isReposted: true));
      expect((await repository.undoRepost('a1')).valueOrNull, const RepostState(repostCount: 3, isReposted: false));
    });

    test('repost.own_article comes back as its code', () async {
      final api = MockRepostsApi();
      final options = RequestOptions(path: '/articles/a1/repost');
      when(() => api.repost('a1')).thenThrow(DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {'type': 'about:blank', 'title': 'x', 'status': 400, 'code': 'repost.own_article'},
        ),
      ));
      final result = await RepostsRepositoryImpl(api).repost('a1');
      expect(result.fold((failure) => failure.code, (_) => null), FailureCodes.repostOwnArticle);
    });

    test('cards and details read repostCount, isReposted, repostedBy and the author headline', () {
      final json = {
        'id': 'a1',
        'slug': 's',
        'language': 'en',
        'title': 'T',
        'field': {'id': 'f', 'slug': 'f', 'nameAr': 'ف', 'nameEn': 'F'},
        'author': {'id': 'w', 'displayName': 'W', 'username': 'w', 'headline': '  Senior .NET Engineer  '},
        'publishedAt': '2026-11-01T10:00:00Z',
        'repostCount': 7,
        'isReposted': true,
        'repostedBy': {
          'user': {'id': 'r', 'displayName': 'Mona', 'username': 'mona', 'headline': ' '},
          'othersCount': 2,
          'repostedAt': '2026-11-02T09:00:00Z',
        },
      };
      final card = ArticleCardModel.fromJson(json).toEntity();
      expect(card.repostCount, 7);
      expect(card.isReposted, isTrue);
      expect(card.author!.headline, 'Senior .NET Engineer');
      expect(card.repostedBy!.user.username, 'mona');
      expect(card.repostedBy!.user.headline, isNull, reason: 'a blank title is none');
      expect(card.repostedBy!.othersCount, 2);
      expect(card.repostedBy!.repostedAt, DateTime.utc(2026, 11, 2, 9));

      final old = ArticleCardModel.fromJson({...json}..remove('repostCount')..remove('isReposted')..remove('repostedBy')).toEntity();
      expect(old.repostCount, 0);
      expect(old.isReposted, isFalse);
      expect(old.repostedBy, isNull);

      final details = ArticleDetailsModel.fromJson({...json, 'content': <String, dynamic>{}}).toEntity();
      expect(details.card.repostCount, 7);
      expect(details.card.isReposted, isTrue);
      expect(details.card.repostedBy, isNull, reason: 'the reader never shows the label');
    });
  });
}
