import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/article/data/datasources/article_api.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/article/data/repositories/article_repository_impl.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/domain/repositories/article_repository.dart';
import 'package:readin/features/article/domain/usecases/get_related_articles.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/cubit/related_articles_cubit.dart';
import 'package:readin/features/article/presentation/widgets/related_articles_section.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';
import 'package:readin/features/saved/presentation/widgets/save_button.dart';

import '../../helpers/fake_auth.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockArticleApi extends Mock implements ArticleApi {}

class MockArticleRepository extends Mock implements ArticleRepository {}

/// Related articles at the end of the reader (F04): `GET /articles/{id}/related`, the cubit and the section.
void main() {
  final related = [for (var i = 2; i < 6; i++) engagedCard(i, language: 'en')];

  group('ArticleRepositoryImpl.getRelated', () {
    late MockArticleApi api;
    late ArticleRepositoryImpl repository;

    setUp(() {
      api = MockArticleApi();
      repository = ArticleRepositoryImpl(api, FakeArticleOfflineStore());
    });

    test('asks for the version being read and the limit, and maps the cards', () async {
      when(() => api.getRelated('art-1', 'en', 4)).thenAnswer(
        (_) async => [ArticleCardModel.fromJson(detailsJson(2, language: 'en')), ArticleCardModel.fromJson(detailsJson(3))],
      );

      final cards = (await repository.getRelated('art-1', language: 'en')).valueOrNull!;

      expect(cards.map((c) => (c.id, c.language)), [('art-2', 'en'), ('art-3', 'ar-EG')]);
      expect(cards.first.isSaved, isFalse);
      expect(cards.first.myReaction, ReactionType.love);
    });

    test('an error is a failure', () async {
      when(() => api.getRelated('art-1', 'ar-EG', 4)).thenThrow(httpError('/articles/art-1/related', 404, code: 'article.not_found'));
      expect((await repository.getRelated('art-1', language: 'ar-EG')).failureOrNull!.code, FailureCodes.articleNotFound);
    });
  });

  group('RelatedArticlesCubit', () {
    late MockArticleRepository repository;

    setUp(() => repository = MockArticleRepository());

    RelatedArticlesCubit build() => RelatedArticlesCubit(GetRelatedArticles(repository));

    blocTest<RelatedArticlesCubit, List<ArticleCard>>(
      'loads up to 4 cards for the version being read',
      setUp: () => when(() => repository.getRelated('art-1', language: 'en', limit: 4)).thenAnswer((_) async => Ok(related)),
      build: build,
      act: (cubit) => cubit.load('art-1', language: 'en'),
      expect: () => [related],
    );

    blocTest<RelatedArticlesCubit, List<ArticleCard>>(
      'a failure leaves it empty (the section hides, no error)',
      setUp: () => when(() => repository.getRelated('art-1', language: 'en', limit: 4))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline))),
      build: build,
      seed: () => related,
      act: (cubit) => cubit.load('art-1', language: 'en'),
      expect: () => [const <ArticleCard>[]],
    );

    test('switching the version again: only the newest answer counts', () async {
      final slow = Completer<Result<List<ArticleCard>>>();
      when(() => repository.getRelated('art-1', language: 'en', limit: 4)).thenAnswer((_) => slow.future);
      when(() => repository.getRelated('art-1', language: 'ar-EG', limit: 4)).thenAnswer((_) async => Ok([sampleCard(7)]));
      final cubit = build();
      addTearDown(cubit.close);

      final first = cubit.load('art-1', language: 'en');
      await cubit.load('art-1', language: 'ar-EG');
      slow.complete(Ok(related));
      await first;

      expect(cubit.state, [sampleCard(7)]);
    });
  });

  group('RelatedArticlesSection', () {
    late MockArticleRepository repository;
    late MockSavedRepository saved;
    late EngagementCubit engagement;

    setUp(() {
      repository = MockArticleRepository();
      saved = MockSavedRepository();
      engagement = EngagementCubit(SetReaction(MockReactionsRepository()), SetSaved(saved));
    });

    tearDown(() => engagement.close());

    MockSessionCubit session() {
      final cubit = MockSessionCubit();
      whenListen(cubit, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      return cubit;
    }

    Widget section(ArticleCard article) => CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 40, child: Text('end of the article'))),
            RelatedArticlesSection(article: article, cubit: () => RelatedArticlesCubit(GetRelatedArticles(repository))),
          ],
        );

    Future<void> pump(WidgetTester tester, ArticleCard article) async {
      usePhoneSurface(tester, size: const Size(390, 1000));
      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session()),
            BlocProvider<EngagementCubit>.value(value: engagement),
          ],
          child: Scaffold(body: section(article)),
        ),
        variant: const Variant(AppLocales.en, Brightness.light),
      ));
      await tester.pump();
    }

    testWidgets('shows "Related articles" and the compact cards with a save button each', (tester) async {
      when(() => repository.getRelated('art-1', language: 'en', limit: 4)).thenAnswer((_) async => Ok(related));
      await pump(tester, engagedCard(1, language: 'en'));

      expect(find.text('Related articles'), findsOneWidget);
      expect(find.byType(SaveToggleButton), findsNWidgets(4));
      // The cards' counters and saves now live in the shared engagement state (F10, F13).
      expect(engagement.state.overlays.keys, containsAll(['art-2', 'art-3', 'art-4', 'art-5']));
    });

    testWidgets('nothing related, or a failed request: no section at all', (tester) async {
      when(() => repository.getRelated('art-1', language: 'en', limit: 4)).thenAnswer((_) async => const Ok([]));
      await pump(tester, engagedCard(1, language: 'en'));
      expect(find.text('Related articles'), findsNothing);

      when(() => repository.getRelated('art-9', language: 'en', limit: 4))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.serverError, statusCode: 500)));
      await pump(tester, engagedCard(9, language: 'en'));
      expect(find.text('Related articles'), findsNothing);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('switching the article version loads the cards for it', (tester) async {
      when(() => repository.getRelated('art-1', language: any(named: 'language'), limit: 4)).thenAnswer((_) async => Ok(related));
      await pump(tester, engagedCard(1, language: 'en'));
      await pump(tester, engagedCard(1));

      verifyInOrder([
        () => repository.getRelated('art-1', language: 'en', limit: 4),
        () => repository.getRelated('art-1', language: 'ar-EG', limit: 4),
      ]);
      expect(find.text('Related articles'), findsOneWidget);
    });

    testWidgets('a card opens its article like anywhere else', (tester) async {
      when(() => repository.getRelated('art-1', language: 'en', limit: 4)).thenAnswer((_) async => Ok(related));
      final opened = <String>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => MultiBlocProvider(
              providers: [
                BlocProvider<SessionCubit>.value(value: session()),
                BlocProvider<EngagementCubit>.value(value: engagement),
              ],
              child: Scaffold(body: section(engagedCard(1, language: 'en'))),
            ),
          ),
          GoRoute(
            path: '/a/:slug',
            builder: (_, state) {
              opened.add(state.pathParameters['slug']!);
              return const Text('reader');
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      usePhoneSurface(tester, size: const Size(390, 1000));
      await tester.pumpWidget(MaterialApp.router(
        theme: AppTheme.light(AppLocales.en),
        locale: AppLocales.en,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Transient'));
      await tester.pumpAndSettle();
      expect(opened, ['article-5']);
    });
  });
}
