@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/reposts/domain/repositories/reposts_repository.dart';
import 'package:readin/features/reposts/domain/usecases/repost_usecases.dart';
import 'package:readin/features/reposts/presentation/widgets/repost_caption_sheet.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';
import 'package:readin/shared/widgets/app_network_image.dart';

import '../helpers/comment_fixtures.dart';
import '../helpers/fake_media.dart';
import '../helpers/fixtures.dart';
import '../helpers/post_card_fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class _MockRepostsRepository extends Mock implements RepostsRepository {}

/// "Repost with your thoughts" (F29) in ar/light and en/dark (SPEC §27): the caption sheet with mixed text typed, and
/// post cards a repost placed, with the reposter's thoughts under the label (one with line breaks, one cut at four
/// lines with "Read more").
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

  bool isArabic(Variant variant) => variant.locale.languageCode != 'en';

  Future<void> pump(WidgetTester tester, Variant variant, EngagementCubit engagement, Widget body, {double height = 844}) async {
    usePhoneSurface(tester, size: Size(390, height));
    final session = MockSessionCubit();
    whenListen(session, const Stream<SessionState>.empty(),
        initialState: const SessionState(status: SessionStatus.authenticated, me: sampleMe));
    final follows = MockFollowsCubit();
    whenListen(follows, const Stream<FollowsState>.empty(), initialState: const FollowsState());
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<EngagementCubit>.value(value: engagement),
          BlocProvider<FollowsCubit>.value(value: follows),
        ],
        child: Scaffold(body: SafeArea(child: body)),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  for (final variant in Variant.golden) {
    final ar = isArabic(variant);
    final language = ar ? 'ar-EG' : 'en';

    testWidgets('the caption sheet ${variant.name}', (tester) async {
      final engagement = EngagementCubit(
        SetReaction(MockReactionsRepository()),
        SetSaved(MockSavedRepository()),
        SetReposted(_MockRepostsRepository()),
      );
      addTearDown(engagement.close);
      final article = postCard(2, language: language, cover: false, author: omarTitled);
      await pump(
        tester,
        variant,
        engagement,
        Builder(
          builder: (context) => Align(
            alignment: Alignment.topCenter,
            child: TextButton(
              onPressed: () => showRepostCaptionSheet(context, article: article, editing: false),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        ar
            ? 'أحسن شرح قريته للـ Dependency Injection.\nخصوصًا الجزء بتاع Scoped و Transient.'
            : 'The clearest explanation of Dependency Injection I have read.\nThe part on Scoped vs Transient is gold.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byType(RepostCaptionSheet), findsOneWidget);
      await expectLater(find.byType(MaterialApp), matchesVariantGolden(variant, 'goldens/repost_caption_sheet_${variant.name}.png'));
    });

    testWidgets('post cards with the reposter\'s thoughts ${variant.name}', (tester) async {
      final engagement = MockEngagementCubit();
      whenListen(engagement, const Stream<EngagementState>.empty(), initialState: const EngagementState());
      final short = ar ? 'مقال لازم يتقري لو بتشتغل بـ .NET.\nالجزء التاني بالذات.' : 'A must-read if you work with .NET.\nEspecially the second part.';
      final long = ar
          ? 'قريت المقال ده مرتين. أول مرة فهمت الفكرة، وتاني مرة فهمت ليه الـ lifetime مهم. لو انت لسه بتبدأ في '
              'ASP.NET Core ابدأ بيه قبل أي حاجة تانية، وبعدين جرب تكتب container صغير بنفسك عشان تشوف الفرق بين '
              'Transient و Scoped و Singleton بعينك. ده هيوفر عليك ساعات من الـ debugging بعدين.'
          : 'I read this one twice. The first time I got the idea, the second time I understood why lifetimes matter. If '
              "you're starting with ASP.NET Core, read it before anything else, then try writing a tiny container yourself "
              'to see the difference between Transient, Scoped and Singleton with your own eyes. It will save you hours of '
              'debugging later.';
      await pump(
        tester,
        variant,
        engagement,
        ListView(
          padding: const EdgeInsets.symmetric(vertical: postCardGap),
          children: [
            PostCard(
              article: postCard(
                5,
                language: language,
                cover: false,
                author: omarTitled,
                repostedBy: RepostLabel(user: monaTitled, repostedAt: DateTime.utc(2026, 11, 2, 9), caption: short),
                reactions: const ReactionCounts(insightful: 7, fire: 2),
                reactionCount: 9,
                commentCount: 1,
                repostCount: 4,
                tags: const [],
                tagCount: 0,
              ),
            ),
            const SizedBox(height: postCardGap),
            PostCard(
              article: postCard(
                7,
                language: language,
                excerpt: ar ? shortArExcerpt : shortEnExcerpt,
                hasMore: false,
                cover: false,
                author: monaTitled,
                repostedBy: RepostLabel(user: omarTitled, othersCount: 2, repostedAt: DateTime.utc(2026, 11, 2, 8), caption: long),
                repostCount: 3,
                tags: const [],
                tagCount: 0,
              ),
            ),
          ],
        ),
        height: 900,
      );
      await expectLater(find.byType(Scaffold), matchesVariantGolden(variant, 'goldens/post_card_repost_caption_${variant.name}.png'));
    });
  }
}
