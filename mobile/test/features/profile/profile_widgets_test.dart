import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/article/presentation/widgets/article_card_tile.dart';
import 'package:readin/features/auth/presentation/cubit/complete_profile_cubit.dart' show UsernameStatus;
import 'package:readin/features/auth/presentation/cubit/form_support.dart';
import 'package:readin/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:readin/features/follow/presentation/widgets/follow_button.dart';
import 'package:readin/features/follow/presentation/widgets/suggested_writers.dart';
import 'package:readin/features/profile/domain/entities/profile.dart';
import 'package:readin/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/follow_list_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/privacy_cubit.dart';
import 'package:readin/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:readin/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:readin/features/profile/presentation/pages/follow_lists_page.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';
import 'package:readin/features/profile/presentation/widgets/profile_header.dart';
import 'package:readin/features/profile/presentation/widgets/public_reading_stats_switch.dart';
import 'package:readin/features/reactions/presentation/widgets/who_reacted_sheet.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/profile_fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  final en = Variant.all[2];
  late AppLocalizations l10n;

  setUpAll(() async => l10n = await AppLocalizations.delegate.load(AppLocales.en));

  Future<void> pump(WidgetTester tester, List<BlocProvider> providers, Widget child, {Variant? variant, double height = 844}) async {
    usePhoneSurface(tester, size: Size(390, height));
    await tester.pumpWidget(testApp(provided(providers, child), variant: variant ?? en));
    await tester.pump();
  }

  group('ProfileView', () {
    testWidgets('own profile: edit, settings and the Saved tab; no follow button', (tester) async {
      await pump(tester, [...appStores(), ...profileScreen(ownProfile, articles: [sampleCard(0)])], const ProfileView(isTab: true));

      expect(find.text(l10n.editProfile), findsOneWidget);
      expect(find.byTooltip(l10n.settings), findsOneWidget);
      expect(find.text(l10n.profileTabSaved), findsOneWidget);
      expect(find.byType(FollowButtonView), findsNothing);
      expect(find.byType(ArticleCardTile), findsOneWidget);
      expect(find.text(l10n.followsYou), findsNothing);
    });

    testWidgets('someone else: follow button, "follows you", no Saved tab; @handle stays LTR', (tester) async {
      await pump(tester, [...appStores(), ...profileScreen(otherProfile)], const ProfileView(), variant: Variant.all.first);

      expect(find.byType(FollowButtonView), findsOneWidget);
      expect(find.byType(FollowsYouChip), findsOneWidget);
      final ar = await AppLocalizations.delegate.load(AppLocales.ar);
      expect(find.text(ar.profileTabSaved), findsNothing);
      expect(find.text(ar.editProfile), findsNothing);
      final handle = tester.widget<Text>(find.text('@mona_dev'));
      expect(handle.textDirection, TextDirection.ltr);
      // Counters: exact up to 9,999, then compact.
      expect(find.text('340'), findsOneWidget);
      expect(find.text(formatProfileCount(12500, 'ar')), findsOneWidget);
      expect(find.text(ar.profileArticlesEmptyTitle), findsOneWidget);
    });

    testWidgets('a deleted or unknown user is "not available"; other errors can be retried', (tester) async {
      final cubit = MockProfileCubit()
        ..hold(const ProfileState(status: ProfileStatus.failure, failure: Failure(FailureCodes.userNotFound, statusCode: 404)));
      await pump(tester, [...appStores(), ...profileScreen(otherProfile)..removeAt(0), BlocProvider<ProfileCubit>.value(value: cubit)], const ProfileView());

      expect(find.text(l10n.profileNotFoundTitle), findsOneWidget);
      expect(find.text(l10n.retry), findsNothing);
    });

    testWidgets('the About tab: bio, links, expertise, joined date', (tester) async {
      final quiet = UserProfile(
        id: otherProfile.id,
        displayName: otherProfile.displayName,
        username: otherProfile.username,
        bio: otherProfile.bio,
        links: otherProfile.links,
        expertise: otherProfile.expertise,
        joinedAt: otherProfile.joinedAt,
      );
      await pump(tester, [...appStores(), ...profileScreen(quiet)], const ProfileView(), height: 1400);

      await tester.tap(find.text(l10n.profileTabAbout));
      await tester.pumpAndSettle();

      expect(find.text(l10n.profileAboutBio), findsOneWidget);
      expect(find.text(l10n.profileExpertise), findsOneWidget);
      expect(find.text('.NET'), findsWidgets);
      expect(find.text(l10n.profileJoined('January 2026')), findsOneWidget);
      // Reading stats stay out while they're private.
      expect(find.text(l10n.readingStatsTitle), findsNothing);
    });

    testWidgets('followers and following open the lists; an author name opens their profile', (tester) async {
      usePhoneSurface(tester);
      final opened = <String>[];
      final router = GoRouter(
        initialLocation: '/u/mona_dev',
        routes: [
          GoRoute(
            path: '/u/:username',
            builder: (_, state) {
              opened.add('profile:${state.pathParameters['username']}');
              return provided(profileScreen(otherProfile, articles: [sampleCard(0)]), const ProfileView());
            },
            routes: [
              GoRoute(
                path: 'followers',
                builder: (_, state) {
                  opened.add('followers:${(state.extra! as UserProfile).id}');
                  return const Text('followers page');
                },
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(provided(
        appStores(),
        MaterialApp.router(
          theme: AppTheme.light(AppLocales.en),
          locale: AppLocales.en,
          supportedLocales: AppLocales.supported,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(l10n.profileStatSemantics(l10n.profileStatFollowers, '340')));
      await tester.pumpAndSettle();
      expect(opened, contains('followers:u-mona'));
      expect(find.text('followers page'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(opened, isNot(contains('profile:editorial')));
      await tester.tap(find.text('ReadIn Editorial'));
      await tester.pumpAndSettle();
      expect(opened, contains('profile:editorial'));
    });
  });

  testWidgets('who reacted closes its sheet and opens the profile; writer rows open theirs', (tester) async {
    usePhoneSurface(tester);
    final opened = <String>[];
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                WriterTile(user: sampleFollowers[1]),
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(context: context, builder: (_) => ReactorTile(reactor: sampleReactors.first)),
                  child: const Text('open sheet'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/u/:username',
          builder: (_, state) {
            opened.add(state.pathParameters['username']!);
            return const Text('profile page');
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(provided(
      appStores(),
      MaterialApp.router(
        locale: AppLocales.en,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light(AppLocales.en),
        routerConfig: router,
      ),
    ));

    await tester.tap(find.text('Omar Khaled'));
    await tester.pumpAndSettle();
    expect(opened, ['omar_k']);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('open sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ReactorTile));
    await tester.pumpAndSettle();
    expect(opened.last, 'mona_dev');
    expect(find.byType(ReactorTile), findsNothing); // the sheet closed
    expect(find.text('profile page'), findsOneWidget);
  });

  group('FollowListView', () {
    testWidgets('rows with follow buttons; typing searches; an empty search says so', (tester) async {
      final followers = MockFollowListCubit()..hold(const FollowListState(status: FollowListStatus.ready, items: sampleFollowers));
      when(() => followers.search(any())).thenReturn(null);
      when(followers.loadMore).thenAnswer((_) async {});
      final following = MockFollowListCubit()..hold(const FollowListState(status: FollowListStatus.ready, query: 'zz'));

      await pump(
        tester,
        appStores(),
        FollowListsView(profile: otherProfile, cubitFor: (kind) => kind == FollowListKind.followers ? followers : following),
      );

      expect(find.text('Omar Khaled'), findsOneWidget);
      expect(find.byType(FollowButtonView), findsNWidgets(sampleFollowers.length));
      await tester.enterText(find.byType(TextField), 'omar');
      verify(() => followers.search('omar')).called(1);

      await tester.tap(find.widgetWithText(Tab, l10n.profileStatFollowing));
      await tester.pumpAndSettle();
      expect(find.text(l10n.profileFollowNoResultsTitle), findsOneWidget);
    });

    testWidgets('the own empty lists explain how they fill', (tester) async {
      final empty = MockFollowListCubit()..hold(const FollowListState(status: FollowListStatus.ready));
      await pump(tester, appStores(), FollowListsView(profile: ownProfile, cubitFor: (_) => empty));

      expect(find.text(l10n.profileFollowersEmptyTitle), findsOneWidget);
      expect(find.text(l10n.profileFollowersEmptyOwnBody), findsOneWidget);
    });
  });

  group('EditProfileView', () {
    late MockEditProfileCubit cubit;

    EditProfileState ready({FormStatus status = FormStatus.idle, bool uploading = false, Map<String, String> errors = const {}}) =>
        EditProfileState(
          load: EditProfileLoad.ready,
          profile: otherProfile,
          username: otherProfile.username,
          usernameStatus: UsernameStatus.available,
          fields: sampleFields,
          fieldsStatus: EditProfileLoad.ready,
          expertiseIds: const ['f-dotnet'],
          status: status,
          uploadingAvatar: uploading,
          errors: errors,
        );

    setUp(() {
      cubit = MockEditProfileCubit();
      when(() => cubit.submit(
            displayName: any(named: 'displayName'),
            bio: any(named: 'bio'),
            github: any(named: 'github'),
            linkedin: any(named: 'linkedin'),
            website: any(named: 'website'),
          )).thenAnswer((_) async {});
      when(() => cubit.toggleExpertise(any())).thenReturn(null);
      when(() => cubit.edited(any())).thenReturn(null);
    });

    Future<void> pumpEdit(WidgetTester tester, EditProfileState state) async {
      cubit.hold(state);
      // Tall enough to build the whole form, the expertise picker included.
      await pump(tester, [...appStores(), BlocProvider<EditProfileCubit>.value(value: cubit)], const EditProfileView(), height: 1600);
    }

    void verifyNoSubmit() => verifyNever(() => cubit.submit(
          displayName: any(named: 'displayName'),
          bio: any(named: 'bio'),
          github: any(named: 'github'),
          linkedin: any(named: 'linkedin'),
          website: any(named: 'website'),
        ));

    testWidgets('starts from the profile and saves what was typed', (tester) async {
      await pumpEdit(tester, ready());

      expect(find.text('منى عادل'), findsOneWidget);
      expect(find.text('https://github.com/mona-dev'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, l10n.profileLinkedin), 'linkedin.com/in/mona');
      await tester.tap(find.text(l10n.save));
      await tester.pump();

      verify(() => cubit.submit(
            displayName: 'منى عادل',
            bio: otherProfile.bio!,
            github: 'https://github.com/mona-dev',
            linkedin: 'linkedin.com/in/mona',
            website: 'https://mona.dev/',
          )).called(1);
    });

    testWidgets('while saving: a spinner and no second submit', (tester) async {
      await pumpEdit(tester, ready(status: FormStatus.submitting));

      expect(find.descendant(of: find.byType(SubmitButton), matching: find.byType(CircularProgressIndicator)), findsOneWidget);
      await tester.tap(find.byType(SubmitButton), warnIfMissed: false);
      verifyNoSubmit();
    });

    testWidgets('while a photo uploads: a spinner on the avatar, and save waits', (tester) async {
      await pumpEdit(tester, ready(uploading: true));

      await tester.tap(find.text(l10n.save), warnIfMissed: false);
      verifyNoSubmit();
      expect(find.bySemanticsLabel(l10n.photoUploading), findsOneWidget);
    });

    testWidgets('errors show on their fields; expertise chips toggle', (tester) async {
      await pumpEdit(tester, ready(errors: const {ProfileFields.website: FailureCodes.validationUrl, ProfileFields.avatar: FailureCodes.profileAvatarInvalid}));

      expect(find.text(l10n.profileErrUrl), findsOneWidget);
      expect(find.text(l10n.profileErrAvatarInvalid), findsOneWidget);
      expect(find.text('1/5'), findsOneWidget);
      await tester.ensureVisible(find.text('Frontend'));
      await tester.pump();
      await tester.tap(find.text('Frontend'));
      verify(() => cubit.toggleExpertise('f-frontend')).called(1);
    });

    testWidgets('a full set of five disables the other chips', (tester) async {
      await pumpEdit(
        tester,
        EditProfileState(
          load: EditProfileLoad.ready,
          profile: otherProfile,
          username: 'mona_dev',
          fields: sampleFields,
          fieldsStatus: EditProfileLoad.ready,
          expertiseIds: const ['f-dotnet', 'f-ai', 'a', 'b', 'c'],
        ),
      );
      await tester.ensureVisible(find.text('Frontend'));
      await tester.pump();

      final chip = tester.widget<FilterChip>(find.ancestor(of: find.text('Frontend'), matching: find.byType(FilterChip)));
      expect(chip.onSelected, isNull);
      expect(find.text(l10n.profileExpertiseFull), findsOneWidget);
    });
  });

  testWidgets('the public reading stats switch saves, and ignores taps while saving', (tester) async {
    final privacy = MockPrivacyCubit()..hold(const PrivacyState());
    when(() => privacy.setPublicReadingStats(any())).thenAnswer((_) async => null);
    await pump(tester, [BlocProvider<PrivacyCubit>.value(value: privacy)], const Scaffold(body: PublicReadingStatsSwitch()));

    await tester.tap(find.byType(Switch));
    verify(() => privacy.setPublicReadingStats(true)).called(1);
    expect(find.text(l10n.profilePublicReadingStatsOff), findsOneWidget);

    final saving = MockPrivacyCubit()..hold(const PrivacyState(publicReadingStats: true, pending: true));
    await pump(tester, [BlocProvider<PrivacyCubit>.value(value: saving)], const Scaffold(body: PublicReadingStatsSwitch()));
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged, isNull);
    expect(find.text(l10n.profilePublicReadingStatsOn), findsOneWidget);
  });

  test('profile counters: exact up to 9,999, then compact, Western digits', () {
    expect(formatProfileCount(5120, 'en'), '5,120');
    expect(formatProfileCount(12500, 'en'), '12.5K');
    expect(formatProfileCount(5120, 'ar'), '5,120');
    expect(formatProfileCount(12500, 'ar'), matches(RegExp(r'^12\.5\s?ألف$')));
  });
}
