@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/explore/domain/entities/explore.dart';
import 'package:readin/features/explore/domain/usecases/explore_usecases.dart';
import 'package:readin/features/explore/presentation/cubit/explore_cubit.dart';
import 'package:readin/features/explore/presentation/cubit/field_cubits.dart';
import 'package:readin/features/explore/presentation/pages/explore_page.dart';
import 'package:readin/features/explore/presentation/pages/explore_ranking_page.dart';
import 'package:readin/features/explore/presentation/pages/field_page.dart';
import 'package:readin/features/explore/presentation/widgets/explore_widgets.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/onboarding/domain/repositories/interests_repository.dart';
import 'package:readin/shared/widgets/app_network_image.dart';

import '../helpers/explore_fixtures.dart';
import '../helpers/fake_media.dart';
import '../helpers/post_card_fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

/// Explore and field pages (F15) in ar/light and en/dark (SPEC §27): Explore with every section, a ranking in full
/// ("See all") as post cards, a field page with its chips, top writers and post cards, and a sensitive field on a
/// followed topic with the health note. Images come from [FakeMedia].
void main() {
  setUpAll(() async {
    registerFallbackValue(InterestKind.field);
    await FakeMedia.install();
    AppNetworkImage.providerFactory = FakeImageProvider.new;
  });
  tearDownAll(() => AppNetworkImage.providerFactory = NetworkImage.new);

  bool isEn(Variant variant) => variant.locale.languageCode == 'en';
  String langOf(Variant variant) => isEn(variant) ? 'en' : 'ar';
  String languageOf(Variant variant) => isEn(variant) ? 'en' : 'ar-EG';

  FollowsCubit followStore() {
    final store = FollowsCubit(SetFollowing(MockFollowRepository()));
    addTearDown(store.close);
    return store;
  }

  Future<void> pumpField(WidgetTester tester, Variant variant, FakeExploreRepository repo, String slug, {String? topic, required double height}) async {
    usePhoneSurface(tester, size: Size(390, height));
    final setInterest = MockSetInterest();
    when(() => setInterest(any(), any(), followed: any(named: 'followed'))).thenAnswer((_) async => const Ok(null));
    final me = readerWith(6);
    final header = FieldCubit(GetFieldDetails(repo), setInterest, sessionOf(me));
    final articles = FieldArticlesCubit(GetFieldArticles(repo), slug);
    final writers = FieldWritersCubit(GetFieldWriters(repo), followStore(), slug);
    final cards = PostCardsCubit.withLoader(previewLoader());
    for (final c in [header, articles, writers, cards]) {
      addTearDown(c.close);
    }
    unawaited(header.load(slug));
    unawaited(articles.load(fieldSlug: topic));
    unawaited(writers.load());
    await tester.pumpWidget(testApp(
      provided(
        [
          ...appStores(me: me),
          BlocProvider<FieldCubit>.value(value: header),
          BlocProvider<FieldArticlesCubit>.value(value: articles),
          BlocProvider<FieldWritersCubit>.value(value: writers),
          BlocProvider<PostCardsCubit>.value(value: cards),
        ],
        const FieldView(),
      ),
      variant: variant,
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  for (final variant in Variant.golden) {
    testWidgets('explore ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 2240));
      final explore = ExploreCubit(GetExplore(FakeExploreRepository(explore: sampleExplore(lang: langOf(variant)))), followStore());
      addTearDown(explore.close);
      unawaited(explore.load());
      await tester.pumpWidget(testApp(
        provided([...appStores(), BlocProvider<ExploreCubit>.value(value: explore)], const ExploreView()),
        variant: variant,
      ));
      await tester.pump();
      await tester.pump();
      expect(find.byType(WriterCard), findsNWidgets(5));
      await expectLater(find.byType(ExploreView), matchesVariantGolden(variant, 'goldens/explore_${variant.name}.png'));
    });

    testWidgets('explore see all ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 1100));
      final repo = FakeExploreRepository(rankings: {
        ExploreRanking.trending: [exploreCards(count: 2, language: languageOf(variant))],
      });
      final ranking = ExploreRankingCubit(GetExploreRanking(repo), ExploreRanking.trending);
      final cards = PostCardsCubit.withLoader(previewLoader());
      addTearDown(ranking.close);
      addTearDown(cards.close);
      unawaited(ranking.load());
      await tester.pumpWidget(testApp(
        provided(
          [...appStores(), BlocProvider<ExploreRankingCubit>.value(value: ranking), BlocProvider<PostCardsCubit>.value(value: cards)],
          const ExploreRankingView(),
        ),
        variant: variant,
      ));
      await tester.pump();
      await tester.pump();
      await expectLater(find.byType(ExploreRankingView), matchesVariantGolden(variant, 'goldens/explore_see_all_${variant.name}.png'));
    });

    testWidgets('field page ${variant.name}', (tester) async {
      final lang = langOf(variant);
      final repo = FakeExploreRepository(
        fields: [dotnetDetails(lang: lang, isFollowing: true, followerCount: 130)],
        articlePages: {'dotnet': [exploreCards(count: 2, language: languageOf(variant))]},
        writers: {'dotnet': exploreWriters()},
      );
      await pumpField(tester, variant, repo, 'dotnet', height: 1700);
      await expectLater(find.byType(FieldView), matchesVariantGolden(variant, 'goldens/field_page_${variant.name}.png'));
    });

    testWidgets('field page sensitive topic ${variant.name}', (tester) async {
      final lang = langOf(variant);
      final medicine = medicineDetails(lang: lang);
      final repo = FakeExploreRepository(
        fields: [
          medicine.copyWith(topics: [for (final t in medicine.topics) t.slug == 'nutrition' ? t.withFollowing(true) : t]),
        ],
        articlePages: {'medicine?nutrition': const [[]]},
        writers: {'medicine': const []},
      );
      await pumpField(tester, variant, repo, 'medicine', topic: 'nutrition', height: 844);
      await expectLater(
        find.byType(FieldView),
        matchesVariantGolden(variant, 'goldens/field_page_sensitive_topic_${variant.name}.png'),
      );
    });
  }
}
