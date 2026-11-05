import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart' show addTearDown;
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/di/injection.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/home/presentation/cubit/feed_cubit.dart';
import 'package:readin/features/profile/domain/entities/profile.dart';
import 'package:readin/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/follow_list_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/privacy_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/profile_articles_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/profile_reposts_cubit.dart';
import 'package:readin/features/reading/presentation/cubit/reading_heatmap_cubit.dart';
import 'package:readin/features/reading/presentation/cubit/reading_stats_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';
import 'package:readin/features/saved/presentation/cubit/saved_list_cubit.dart';

import 'fixtures.dart';
import 'social_fakes.dart';

class MockProfileCubit extends MockCubit<ProfileState> implements ProfileCubit {}

class MockProfileArticlesCubit extends MockCubit<FeedState> implements ProfileArticlesCubit {}

class MockProfileRepostsCubit extends MockCubit<FeedState> implements ProfileRepostsCubit {}

class MockEditProfileCubit extends MockCubit<EditProfileState> implements EditProfileCubit {}

class MockFollowListCubit extends MockCubit<FollowListState> implements FollowListCubit {}

class MockPrivacyCubit extends MockCubit<PrivacyState> implements PrivacyCubit {}

class _LoadingReadingStatsCubit extends MockCubit<ReadingStatsState> implements ReadingStatsCubit {}

class _LoadingReadingHeatmapCubit extends MockCubit<ReadingHeatmapState> implements ReadingHeatmapCubit {}

extension SeedCubit<S> on MockCubit<S> {
  /// A cubit that stays in [state].
  void hold(S state) => whenListen(this, Stream<S>.empty(), initialState: state);
}

MockProfileCubit profileCubit(UserProfile profile) => MockProfileCubit()..hold(ProfileState(status: ProfileStatus.ready, profile: profile));

MockProfileArticlesCubit articlesCubit(List<ArticleCard> items, {String? nextCursor}) {
  final cubit = MockProfileArticlesCubit()..hold(FeedState(status: FeedStatus.ready, items: items, nextCursor: nextCursor));
  when(cubit.loadMore).thenAnswer((_) async {});
  return cubit;
}

/// The Reposts tab (F29) holding [items] (an empty list shows the empty state).
MockProfileRepostsCubit repostsCubit(List<ArticleCard> items, {String? nextCursor}) {
  final cubit = MockProfileRepostsCubit()..hold(FeedState(status: FeedStatus.ready, items: items, nextCursor: nextCursor));
  when(cubit.loadMore).thenAnswer((_) async {});
  when(cubit.ensureLoaded).thenAnswer((_) async {});
  when(cubit.refresh).thenAnswer((_) async {});
  return cubit;
}

/// The app-wide stores a profile screen reads: session (signed in as [me]), engagement, follows, collections.
List<BlocProvider> appStores({Me? me = sampleMe, FollowsState follows = const FollowsState()}) {
  final session = MockSessionCubit()
    ..hold(me == null ? const SessionState(status: SessionStatus.guest) : SessionState(status: SessionStatus.authenticated, me: me));
  final engagement = MockEngagementCubit()..hold(const EngagementState());
  final followsCubit = MockFollowsCubit()..hold(follows);
  when(() => followsCubit.changes).thenAnswer((_) => const Stream.empty());
  final collections = MockCollectionsCubit()..hold(const CollectionsState());
  when(() => collections.load(force: any(named: 'force'))).thenAnswer((_) async {});
  return [
    BlocProvider<SessionCubit>.value(value: session),
    BlocProvider<EngagementCubit>.value(value: engagement),
    BlocProvider<FollowsCubit>.value(value: followsCubit),
    BlocProvider<CollectionsCubit>.value(value: collections),
  ];
}

/// The reading stats block above the profile's tabs builds its cubits with `getIt` (F08): unless the test registered
/// its own, registers ones that stay loading, for the current test.
void registerLoadingReadingStats() {
  if (!getIt.isRegistered<ReadingStatsCubit>()) {
    getIt.registerFactory<ReadingStatsCubit>(() {
      final cubit = _LoadingReadingStatsCubit()..hold(const ReadingStatsState());
      when(() => cubit.load(username: any(named: 'username'))).thenAnswer((_) async {});
      return cubit;
    });
    addTearDown(() {
      if (getIt.isRegistered<ReadingStatsCubit>()) getIt.unregister<ReadingStatsCubit>();
    });
  }
  if (!getIt.isRegistered<ReadingHeatmapCubit>()) {
    getIt.registerFactory<ReadingHeatmapCubit>(() {
      final cubit = _LoadingReadingHeatmapCubit()..hold(const ReadingHeatmapState());
      when(() => cubit.load(username: any(named: 'username'))).thenAnswer((_) async {});
      return cubit;
    });
    addTearDown(() {
      if (getIt.isRegistered<ReadingHeatmapCubit>()) getIt.unregister<ReadingHeatmapCubit>();
    });
  }
}

/// What [ProfileView] needs above it, besides [appStores] (and the reading stats' cubits, [registerLoadingReadingStats]).
List<BlocProvider> profileScreen(
  UserProfile profile, {
  List<ArticleCard> articles = const [],
  List<ArticleCard> reposts = const [],
  PrivacyState privacy = const PrivacyState(),
}) {
  registerLoadingReadingStats();
  final saved = MockSavedListCubit()..hold(const SavedListState(status: SavedListStatus.ready));
  return [
    BlocProvider<ProfileCubit>.value(value: profileCubit(profile)),
    BlocProvider<ProfileArticlesCubit>.value(value: articlesCubit(articles)),
    BlocProvider<ProfileRepostsCubit>.value(value: repostsCubit(reposts)),
    BlocProvider<SavedListCubit>.value(value: saved),
    BlocProvider<PrivacyCubit>.value(value: MockPrivacyCubit()..hold(privacy)),
  ];
}

/// [child] under [providers].
Widget provided(List<BlocProvider> providers, Widget child) => MultiBlocProvider(providers: providers, child: child);
