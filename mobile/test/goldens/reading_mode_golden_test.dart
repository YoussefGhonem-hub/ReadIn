@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/article_cubit.dart';
import 'package:readin/features/article/presentation/cubit/article_live_cubit.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/pages/article_page.dart';
import 'package:readin/features/article/presentation/widgets/reading_mode.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/paths/presentation/cubit/article_path_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:readin/shared/rdoc/rdoc_document.dart';

import '../helpers/comment_fixtures.dart';
import '../helpers/fixtures.dart';
import '../helpers/path_fakes.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class MockArticleCubit extends MockCubit<ArticleState> implements ArticleCubit {}

class MockArticleLiveCubit extends MockCubit<LiveArticleCounts?> implements ArticleLiveCubit {}

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

/// The reader in reading mode (F04): no top bar and no action bar, the reading progress and the article, and the
/// floating "Exit reading mode" at the bottom end corner (left in Arabic, right in English).
void main() {
  for (final variant in Variant.golden) {
    testWidgets('reader in reading mode ${variant.name}', (tester) async {
      registerNoRelatedArticles();
      registerReaderComments();
      getIt.registerFactory<ArticlePathCubit>(noPathCubit);
      addTearDown(() => getIt.unregister<ArticlePathCubit>());
      usePhoneSurface(tester, size: const Size(390, 640));

      final language = variant.locale.languageCode == 'en' ? 'en' : 'ar-EG';
      final article = ArticleDetails(
        card: engagedCard(1, myReaction: ReactionType.insightful, language: language),
        availableLanguages: [language],
        content: RDocDocument.fromJson(detailsJson(1, language: language)['content'] as Map<String, dynamic>),
        isFollowingAuthor: false,
      );
      final articleCubit = MockArticleCubit();
      final live = MockArticleLiveCubit();
      final settings = MockSettingsCubit();
      final session = MockSessionCubit();
      final engagement = MockEngagementCubit();
      final follows = MockFollowsCubit();
      final collections = MockCollectionsCubit();
      whenListen(articleCubit, const Stream<ArticleState>.empty(), initialState: ArticleState(status: ArticleStatus.ready, article: article));
      whenListen(live, const Stream<LiveArticleCounts?>.empty(), initialState: null);
      whenListen(settings, const Stream<AppSettings>.empty(), initialState: const AppSettings(readingMode: true));
      whenListen(session, const Stream<SessionState>.empty(), initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
      whenListen(engagement, const Stream<EngagementState>.empty(), initialState: const EngagementState());
      whenListen(follows, const Stream<FollowsState>.empty(), initialState: const FollowsState());
      when(() => follows.changes).thenAnswer((_) => const Stream.empty());
      whenListen(collections, const Stream<CollectionsState>.empty(), initialState: const CollectionsState());
      when(() => collections.load(force: any(named: 'force'))).thenAnswer((_) async {});

      await tester.pumpWidget(testApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionCubit>.value(value: session),
            BlocProvider<EngagementCubit>.value(value: engagement),
            BlocProvider<FollowsCubit>.value(value: follows),
            BlocProvider<CollectionsCubit>.value(value: collections),
            BlocProvider<ArticleCubit>.value(value: articleCubit),
            BlocProvider<ArticleLiveCubit>.value(value: live),
            BlocProvider<SettingsCubit>.value(value: settings),
          ],
          child: const ArticleView(),
        ),
        variant: variant,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(ReadingModeExitButton.exitKey), findsOneWidget);
      await expectLater(find.byType(ArticleView), matchesVariantGolden(variant, 'goldens/reading_mode_${variant.name}.png'));
    });
  }
}
