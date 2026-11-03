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
import 'package:readin/features/auth/presentation/cubit/complete_profile_cubit.dart' show UsernameStatus;
import 'package:readin/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/follow_list_cubit.dart';
import 'package:readin/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:readin/features/profile/presentation/pages/follow_lists_page.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';
import 'package:readin/features/reading/presentation/cubit/reading_heatmap_cubit.dart';
import 'package:readin/features/reading/presentation/cubit/reading_stats_cubit.dart';

import '../helpers/fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/profile_fixtures.dart';
import '../helpers/reading_fixtures.dart';
import '../helpers/social_fakes.dart';
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

  tearDown(() => getIt.reset());

  for (final variant in Variant.all) {
    final language = languageOf(variant);
    final articles = [for (var i = 0; i < 3; i++) engagedCard(i, isSaved: i == 1, language: language)];

    testWidgets('own profile ${variant.name}', (tester) async {
      await pump(tester, variant, [...appStores(), ...profileScreen(ownProfile, articles: articles)], const ProfileView(isTab: true));
      await expectLater(find.byType(ProfileView), matchesGoldenFile('goldens/profile_own_${variant.name}.png'));
    });

    testWidgets('other profile ${variant.name}', (tester) async {
      await pump(tester, variant, [...appStores(), ...profileScreen(otherProfile, articles: articles)], const ProfileView());
      await expectLater(find.byType(ProfileView), matchesGoldenFile('goldens/profile_other_${variant.name}.png'));
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
      await tester.tap(find.text(l10n.profileTabAbout));
      await tester.pumpAndSettle();

      verify(() => stats.load(username: 'mona_dev')).called(1);
      await expectLater(find.byType(ProfileView), matchesGoldenFile('goldens/profile_about_${variant.name}.png'));
    });

    testWidgets('edit profile ${variant.name}', (tester) async {
      final cubit = MockEditProfileCubit()
        ..hold(EditProfileState(
          load: EditProfileLoad.ready,
          profile: otherProfile,
          username: otherProfile.username,
          usernameStatus: UsernameStatus.available,
          fields: sampleFields,
          fieldsStatus: EditProfileLoad.ready,
          expertiseIds: const ['f-dotnet', 'f-ai'],
          // A link the server refused (`validation.url` on `links.website`).
          errors: const {ProfileFields.website: FailureCodes.validationUrl},
        ));
      await pump(tester, variant, [...appStores(), BlocProvider<EditProfileCubit>.value(value: cubit)], const EditProfileView(), height: 1400);
      await expectLater(find.byType(EditProfileView), matchesGoldenFile('goldens/profile_edit_${variant.name}.png'));
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
      await expectLater(find.byType(FollowListsView), matchesGoldenFile('goldens/profile_followers_${variant.name}.png'));
    });
  }
}
