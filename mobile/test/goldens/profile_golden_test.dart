@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/auth/presentation/cubit/complete_profile_cubit.dart' show UsernameStatus;
import 'package:readin/features/comments/presentation/widgets/comment_body.dart';
import 'package:readin/features/profile/domain/entities/profile.dart';
import 'package:readin/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/follow_list_cubit.dart';
import 'package:readin/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:readin/features/profile/presentation/pages/follow_lists_page.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';
import 'package:readin/features/reading/presentation/cubit/reading_heatmap_cubit.dart';
import 'package:readin/features/reading/presentation/cubit/reading_stats_cubit.dart';

import '../helpers/fixtures.dart';
import '../helpers/post_card_fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/profile_fixtures.dart';
import '../helpers/reading_fixtures.dart';
import '../helpers/test_app.dart';

class MockReadingStatsCubit extends MockCubit<ReadingStatsState> implements ReadingStatsCubit {}

class MockReadingHeatmapCubit extends MockCubit<ReadingHeatmapState> implements ReadingHeatmapCubit {}

/// Profile (F14) in ar/en × light/dark (SPEC §8.2): own and other profiles, the About tab with public reading stats,
/// the edit page and the follower lists.
void main() {
  String languageOf(Variant variant) => variant.locale.languageCode == 'en' ? 'en' : 'ar-EG';

  Future<void> pump(WidgetTester tester, Variant variant, List<BlocProvider> providers, Widget child, {double height = 844}) async {
    usePhoneSurface(tester, size: Size(390, height));
    await tester.pumpWidget(testApp(provided(providers, child), variant: variant));
    await tester.pump();
  }

  setUp(() => CommentClock.now = () => DateTime.utc(2026, 11, 2, 12)); // post cards: "3 days ago"
  tearDown(() {
    CommentClock.now = DateTime.now;
    getIt.reset();
  });

  for (final variant in Variant.golden) {
    final language = languageOf(variant);
    // The profile's own articles as post cards (F34), by its writer: no Follow on them.
    List<ArticleCard> articlesBy(UserProfile profile) => [
          for (var i = 0; i < 3; i++)
            postCard(
              i,
              language: language,
              cover: false,
              isSaved: i == 1,
              author: Author(id: profile.id, displayName: profile.displayName, username: profile.username, isVerified: profile.isVerified),
              reactions: const ReactionCounts(insightful: 12, love: 3, fire: 1),
              reactionCount: 16,
              commentCount: 4,
            ),
        ];

    testWidgets('own profile ${variant.name}', (tester) async {
      await pump(tester, variant, [...appStores(), ...profileScreen(ownProfile, articles: articlesBy(ownProfile))], const ProfileView(isTab: true));
      await expectLater(find.byType(ProfileView), matchesVariantGolden(variant, 'goldens/profile_own_${variant.name}.png'));
    });

    testWidgets('other profile ${variant.name}', (tester) async {
      await pump(tester, variant, [...appStores(), ...profileScreen(otherProfile, articles: articlesBy(otherProfile))], const ProfileView());
      await expectLater(find.byType(ProfileView), matchesVariantGolden(variant, 'goldens/profile_other_${variant.name}.png'));
    });

    testWidgets('profile about with public reading stats ${variant.name}', (tester) async {
      final stats = MockReadingStatsCubit();
      whenListen(stats, const Stream<ReadingStatsState>.empty(),
          initialState: ReadingStatsState(status: ReadingLoadStatus.ready, stats: sampleStats()));
      when(() => stats.load(username: any(named: 'username'))).thenAnswer((_) async {});
      final heatmap = MockReadingHeatmapCubit();
      whenListen(heatmap, const Stream<ReadingHeatmapState>.empty(),
          initialState: ReadingHeatmapState(status: ReadingLoadStatus.ready, heatmap: sampleHeatmap()));
      when(() => heatmap.load(username: any(named: 'username'))).thenAnswer((_) async {});
      getIt
        ..registerFactory<ReadingStatsCubit>(() => stats)
        ..registerFactory<ReadingHeatmapCubit>(() => heatmap);

      await pump(tester, variant, [...appStores(), ...profileScreen(otherProfile)], const ProfileView(), height: 1700);
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      // The tab bar scrolls: with Reposts (F29) the About tab starts off screen.
      await tester.ensureVisible(find.text(l10n.profileTabAbout));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.profileTabAbout));
      await tester.pumpAndSettle();

      verify(() => stats.load(username: 'mona_dev')).called(1);
      await expectLater(find.byType(ProfileView), matchesVariantGolden(variant, 'goldens/profile_about_${variant.name}.png'));
    });

    EditProfileState editState({Map<String, String> errors = const {}}) => EditProfileState(
          load: EditProfileLoad.ready,
          profile: otherProfile,
          username: otherProfile.username,
          usernameStatus: UsernameStatus.available,
          fields: sampleFields,
          fieldsStatus: EditProfileLoad.ready,
          expertiseIds: const ['f-dotnet', 'f-ai'],
          links: [
            for (final (i, link) in otherProfile.links.indexed)
              LinkDraft(id: i, platform: link.platform, url: link.url, label: link.label ?? ''),
          ],
          errors: errors,
        );

    testWidgets('edit profile ${variant.name}', (tester) async {
      final cubit = MockEditProfileCubit()..hold(editState());
      await pump(tester, variant, [...appStores(), BlocProvider<EditProfileCubit>.value(value: cubit)], const EditProfileView(), height: 1400);
      await expectLater(find.byType(EditProfileView), matchesVariantGolden(variant, 'goldens/profile_edit_${variant.name}.png'));
    });

    testWidgets('edit profile links editor ${variant.name}', (tester) async {
      // Links the server refused, each error under its own field (F14).
      final cubit = MockEditProfileCubit()
        ..hold(editState(errors: const {
          'links[2].url': FailureCodes.linkHostMismatch,
          'links[4].label': FailureCodes.linkLabelInvalid,
        }));
      await pump(tester, variant, [...appStores(), BlocProvider<EditProfileCubit>.value(value: cubit)], const EditProfileView(), height: 1400);
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      await tester.scrollUntilVisible(find.text(l10n.profileLinksSection), 300, scrollable: find.byType(Scrollable).first);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 120));
      await tester.pumpAndSettle();
      await expectLater(find.byType(EditProfileView), matchesVariantGolden(variant, 'goldens/profile_edit_links_${variant.name}.png'));
    });

    testWidgets('profile reposts tab ${variant.name}', (tester) async {
      final owner = Author(id: otherProfile.id, displayName: otherProfile.displayName, username: otherProfile.username, isVerified: true);
      final reposts = [
        for (var i = 0; i < 2; i++)
          postCard(
            i + 3,
            language: language,
            cover: false,
            repostCount: 4 - i,
            reactions: const ReactionCounts(insightful: 5),
            reactionCount: 5,
            repostedBy: RepostLabel(user: owner, repostedAt: DateTime.utc(2026, 11, 1, 9 - i)),
          ),
      ];
      await pump(tester, variant, [...appStores(), ...profileScreen(otherProfile, reposts: reposts)], const ProfileView(), height: 1300);
      final l10n = await AppLocalizations.delegate.load(variant.locale);
      await tester.tap(find.text(l10n.profileTabReposts));
      await tester.pumpAndSettle();
      await expectLater(find.byType(ProfileView), matchesVariantGolden(variant, 'goldens/profile_reposts_${variant.name}.png'));
    });

    testWidgets('followers list ${variant.name}', (tester) async {
      final followers = MockFollowListCubit()..hold(const FollowListState(status: FollowListStatus.ready, items: sampleFollowers));
      when(followers.loadMore).thenAnswer((_) async {});
      final following = MockFollowListCubit()..hold(const FollowListState());
      await pump(
        tester,
        variant,
        appStores(),
        FollowListsView(profile: otherProfile, cubitFor: (kind) => kind == FollowListKind.followers ? followers : following),
      );
      await expectLater(find.byType(FollowListsView), matchesVariantGolden(variant, 'goldens/profile_followers_${variant.name}.png'));
    });
  }
}
