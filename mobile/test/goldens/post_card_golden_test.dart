@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/shared/widgets/app_network_image.dart';

import '../helpers/fake_media.dart';
import '../helpers/fixtures.dart';
import '../helpers/post_card_fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

/// The post card (F34) in ar/en × light/dark (SPEC §8.2): collapsed with a cover, label and tags; a short article
/// shown whole by a deleted user; images with the viewer's reaction; expanded with its preview; a preview that failed.
void main() {
  setUpAll(FakeMedia.install);
  setUp(() {
    CommentClock.now = () => DateTime.utc(2026, 11, 2, 12);
    AppNetworkImage.providerFactory = FakeImageProvider.new;
  });
  tearDown(() {
    CommentClock.now = DateTime.now;
    AppNetworkImage.providerFactory = NetworkImage.new;
  });

  String languageOf(Variant variant) => variant.locale.languageCode == 'en' ? 'en' : 'ar-EG';

  Future<void> pump(WidgetTester tester, Variant variant, List<Widget> Function(BuildContext context) cards,
      {double height = 844, PostCardsCubit? postCards}) async {
    usePhoneSurface(tester, size: Size(390, height));
    final session = MockSessionCubit();
    whenListen(session, const Stream<SessionState>.empty(),
        initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    final engagement = MockEngagementCubit();
    whenListen(engagement, const Stream<EngagementState>.empty(), initialState: const EngagementState());
    final follows = MockFollowsCubit();
    whenListen(follows, const Stream<FollowsState>.empty(), initialState: const FollowsState());
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<EngagementCubit>.value(value: engagement),
          BlocProvider<FollowsCubit>.value(value: follows),
          if (postCards != null) BlocProvider<PostCardsCubit>.value(value: postCards),
        ],
        child: Scaffold(
          body: SafeArea(
            child: Builder(
              builder: (context) => ListView(
                padding: const EdgeInsets.symmetric(vertical: postCardGap),
                children: [
                  for (final card in cards(context)) Padding(padding: const EdgeInsets.only(bottom: postCardGap), child: card),
                ],
              ),
            ),
          ),
        ),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  for (final variant in Variant.golden) {
    final language = languageOf(variant);

    testWidgets("today's article and a short one by a deleted user ${variant.name}", (tester) async {
      await pump(
        tester,
        variant,
        (context) => [
          PostCard(
            label: context.l10n.todayArticle,
            article: postCard(
              1,
              language: language,
              reactions: const ReactionCounts(insightful: 40, love: 6, fire: 3, mindBlown: 1),
              reactionCount: 50,
              commentCount: 12,
            ),
          ),
          PostCard(article: shortPostCard(language: language, authorDeleted: true)),
        ],
      );
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/post_card_${variant.name}.png'));
    });

    testWidgets('images, mixed text and the viewer reacted ${variant.name}', (tester) async {
      await pump(tester, variant, (_) => [PostCard(article: attachmentsPostCard(language: language))], height: 760);
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/post_card_images_${variant.name}.png'));
    });

    testWidgets('expanded with the preview ${variant.name}', (tester) async {
      final card = postCard(3, language: language, cover: false, reactionCount: 8, reactions: const ReactionCounts(insightful: 8));
      final postCards = PostCardsCubit.withLoader(previewLoader());
      addTearDown(postCards.close);
      await postCards.expand(card);
      await pump(tester, variant, (_) => [PostCard(article: card)], height: 900, postCards: postCards);
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/post_card_expanded_${variant.name}.png'));
    });

    testWidgets('the preview failed ${variant.name}', (tester) async {
      final card = postCard(4, language: language, cover: false, tags: const [], tagCount: 0);
      final postCards = PostCardsCubit.withLoader(previewLoader(failure: const Failure(FailureCodes.networkOffline)));
      addTearDown(postCards.close);
      await postCards.expand(card);
      await pump(tester, variant, (_) => [PostCard(article: card)], height: 640, postCards: postCards);
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/post_card_preview_failed_${variant.name}.png'));
    });
  }
}
