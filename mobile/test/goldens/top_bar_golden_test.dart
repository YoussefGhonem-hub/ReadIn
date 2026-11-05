@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/domain/entities/permissions.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/suggested_writers_cubit.dart';
import 'package:readin/features/follow/presentation/widgets/suggested_writers_carousel.dart';
import 'package:readin/features/home/presentation/widgets/app_top_bar.dart';
import 'package:readin/features/home/presentation/widgets/start_post_card.dart';
import 'package:readin/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:readin/features/paths/presentation/widgets/suggested_path_card.dart';
import 'package:readin/features/reading/presentation/cubit/reading_stats_cubit.dart';
import 'package:readin/features/settings/domain/entities/app_settings.dart';
import 'package:readin/features/settings/presentation/cubit/settings_cubit.dart';

import '../helpers/path_fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/reading_fixtures.dart';
import '../helpers/social_fakes.dart';
import '../helpers/test_app.dart';

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit {}

class MockUnreadBadgeCubit extends MockCubit<int> implements UnreadBadgeCubit {}

class MockReadingStatsCubit extends MockCubit<ReadingStatsState> implements ReadingStatsCubit {}

class MockSuggestedWritersCubit extends MockCubit<SuggestedWritersState> implements SuggestedWritersCubit {}

/// A moderator who writes and isn't verified yet: every item of the Me sheet shows.
const _me = Me(
  id: 'u-1',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  bio: 'بكتب عن Flutter و ASP.NET Core',
  onboardingCompleted: true,
  permissions: [Permissions.articlesCreate, Permissions.moderationManage],
);

/// The LinkedIn-style pieces of the main tabs in ar/light and en/dark (SPEC §27): the top bar (signed in and guest),
/// the Me sheet, and Home's additions (Start a post, the suggested path, "Add to your feed").
void main() {
  late MockReadingStatsCubit stats;

  setUp(() {
    stats = MockReadingStatsCubit()..hold(ReadingStatsState(status: ReadingLoadStatus.ready, stats: sampleStats()));
    when(() => stats.load(username: any(named: 'username'))).thenAnswer((_) async {});
    getIt.registerFactory<ReadingStatsCubit>(() => stats);
  });

  tearDown(() => getIt.unregister<ReadingStatsCubit>());

  Future<void> pump(WidgetTester tester, Variant variant, Widget child, {Me? me = _me, int unread = 0, double height = 844}) async {
    usePhoneSurface(tester, size: Size(390, height));
    final settings = MockSettingsCubit()
      ..hold(AppSettings(theme: variant.brightness == Brightness.dark ? ThemePreference.dark : ThemePreference.light));
    final follows = MockFollowsCubit()..hold(const FollowsState());
    when(() => follows.changes).thenAnswer((_) => const Stream.empty());
    final suggested = MockSuggestedWritersCubit()
      ..hold(const SuggestedWritersState(status: SuggestedWritersStatus.ready, users: sampleWriters));
    when(suggested.ensureLoaded).thenAnswer((_) async {});
    await tester.pumpWidget(testApp(
      provided(
        [
          BlocProvider<SessionCubit>.value(
            value: MockSessionCubit()
              ..hold(me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me)),
          ),
          BlocProvider<SettingsCubit>.value(value: settings),
          BlocProvider<UnreadBadgeCubit>.value(value: MockUnreadBadgeCubit()..hold(unread)),
          BlocProvider<FollowsCubit>.value(value: follows),
          BlocProvider<SuggestedWritersCubit>.value(value: suggested),
        ],
        child,
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  const screen = Scaffold(appBar: AppTopBar(), body: SizedBox.expand());

  for (final variant in Variant.golden) {
    testWidgets('top bar ${variant.name}', (tester) async {
      await pump(tester, variant, screen, unread: 3, height: 120);
      await expectLater(find.byType(AppTopBar), matchesVariantGolden(variant, 'goldens/top_bar_${variant.name}.png'));
    });

    testWidgets('top bar guest ${variant.name}', (tester) async {
      await pump(tester, variant, screen, me: null, height: 120);
      await expectLater(find.byType(AppTopBar), matchesVariantGolden(variant, 'goldens/top_bar_guest_${variant.name}.png'));
    });

    testWidgets('me sheet ${variant.name}', (tester) async {
      await pump(tester, variant, screen, height: 900);
      await tester.tap(find.byKey(const ValueKey('me-button')));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesVariantGolden(variant, 'goldens/me_sheet_${variant.name}.png'));
    });

    testWidgets('home additions ${variant.name}', (tester) async {
      final en = variant.locale.languageCode == 'en';
      await pump(
        tester,
        variant,
        Scaffold(
          body: SingleChildScrollView(
            key: const ValueKey('home-additions'),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: StartPostCard(me: _me)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SuggestedPathCard(
                    path: samplePath(title: en ? 'Flutter from scratch' : 'Flutter من الصفر', readCount: 0),
                    onOpenPath: () {},
                    onSeeAll: () {},
                  ),
                ),
                const SizedBox(height: 16),
                SuggestedWritersCarousel(onSeeAll: () {}),
              ],
            ),
          ),
        ),
        height: 760,
      );
      await expectLater(find.byKey(const ValueKey('home-additions')), matchesVariantGolden(variant, 'goldens/home_additions_${variant.name}.png'));
    });
  }
}
