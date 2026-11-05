import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/app_theme.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
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
import 'package:readin/features/profile/presentation/cubit/profile_reposts_cubit.dart';
import 'package:readin/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:readin/features/profile/presentation/pages/follow_lists_page.dart';
import 'package:readin/features/profile/presentation/pages/profile_page.dart';
import 'package:readin/features/profile/presentation/widgets/headline_field.dart';
import 'package:readin/features/profile/presentation/widgets/profile_header.dart';
import 'package:readin/features/profile/presentation/widgets/profile_links_editor.dart';
import 'package:readin/features/profile/presentation/widgets/public_reading_stats_switch.dart';
import 'package:readin/features/reactions/presentation/widgets/who_reacted_sheet.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/post_card_fixtures.dart';
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
      // Their own article, as a post card (F34): no Follow on it either.
      const me = Author(id: 'u-1', displayName: 'Youssef Hassan', username: 'reader1');
      await pump(tester, [...appStores(), ...profileScreen(ownProfile, articles: [postCard(0, author: me, cover: false)])], const ProfileView(isTab: true));

      expect(find.text(l10n.editProfile), findsOneWidget);
      expect(find.byTooltip(l10n.settings), findsOneWidget);
      expect(find.text(l10n.profileTabSaved), findsOneWidget);
      expect(find.byType(FollowButtonView), findsNothing);
      expect(find.byType(PostCard), findsOneWidget);
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

    testWidgets('the title shows in full under the name, in its own direction; none, no line', (tester) async {
      await pump(tester, [...appStores(), ...profileScreen(otherProfile)], const ProfileView(), variant: Variant.all.first);

      final headline = tester.widget<Text>(find.descendant(of: find.byKey(ProfileHeader.headlineKey), matching: find.byType(Text)));
      expect(headline.data, contains('Senior Backend Engineer'));
      // Mixed text starting in English: laid out left to right inside the Arabic screen, never cut.
      expect(headline.textDirection, TextDirection.ltr);
      expect(headline.maxLines, isNull);
      expect(headline.overflow, isNull);

      await pump(tester, [...appStores(), ...profileScreen(ownProfile)], const ProfileView(isTab: true));
      expect(find.byKey(ProfileHeader.headlineKey), findsNothing);
    });

    testWidgets('links: icons under the bio in their order, each a link named after its platform, for guests too', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final variant in Variant.all) {
        await pump(tester, [...appStores(me: null), ...profileScreen(otherProfile)], const ProfileView(), variant: variant);
        final names = ['LinkedIn', 'GitHub', 'X', variant.locale == AppLocales.ar ? 'الموقع' : 'Website', 'بودكاست منى'];
        for (final (i, name) in names.indexed) {
          final node = tester.getSemantics(find.byKey(ProfileLinksRow.keyOf(i)));
          expect(node.label, name, reason: '${variant.name} $i');
          expect(node.flagsCollection.isLink, isTrue);
        }
        // In order, start to end: RTL lays them out from the right.
        final first = tester.getCenter(find.byKey(ProfileLinksRow.keyOf(0))).dx;
        final last = tester.getCenter(find.byKey(ProfileLinksRow.keyOf(4))).dx;
        expect(variant.locale == AppLocales.ar ? first > last : first < last, isTrue, reason: variant.name);
      }
      semantics.dispose();
    });

    testWidgets('no links: no row', (tester) async {
      const plain = UserProfile(id: 'u-9', displayName: 'Plain', username: 'plain');
      await pump(tester, [...appStores(), ...profileScreen(plain)], const ProfileView());

      expect(find.byType(ProfileLinksRow), findsNothing);
    });

    testWidgets('a link icon opens its address outside the app (the system browser or the platform app)', (tester) async {
      final opened = <String>[];
      await pump(
        tester,
        appStores(),
        Scaffold(
          body: ProfileLinksRow(
            links: otherProfile.links,
            onOpen: (url) async {
              opened.add(url);
              return true;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(ProfileLinksRow.keyOf(2)));
      await tester.tap(find.byKey(ProfileLinksRow.keyOf(4)));

      expect(opened, ['https://x.com/mona_dev', 'https://mona.dev/podcast']);
    });

    testWidgets('by default a link icon goes through url_launcher, outside the app (no in-app web view)', (tester) async {
      final calls = <MethodCall>[];
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
      await pump(tester, appStores(), Scaffold(body: ProfileLinksRow(links: otherProfile.links)));

      await tester.tap(find.byKey(ProfileLinksRow.keyOf(1)));
      await tester.pump();

      final launch = calls.singleWhere((c) => c.method == 'launch');
      final args = launch.arguments as Map<Object?, Object?>;
      expect(args['url'], 'https://github.com/mona-dev');
      expect(args['useWebView'], isFalse);
      expect(args['useSafariVC'], isFalse);
    });

    testWidgets('the Reposts tab: post cards newest first, or the empty state, on every profile', (tester) async {
      await pump(
        tester,
        [...appStores(), ...profileScreen(otherProfile, reposts: [postCard(1, cover: false), postCard(2, cover: false)])],
        const ProfileView(),
        height: 2400,
      );

      // Articles · Categories · Reposts · Paths · About (no Saved on someone else's profile).
      final tabs = tester.widgetList<Tab>(find.byType(Tab)).map((t) => t.text).toList();
      expect(tabs, [l10n.profileTabArticles, l10n.profileTabCategories, l10n.profileTabReposts, l10n.profileTabPaths, l10n.profileTabAbout]);

      await tester.tap(find.text(l10n.profileTabReposts));
      await tester.pumpAndSettle();
      expect(find.byType(PostCard), findsNWidgets(2));
      final reposts = BlocProvider.of<ProfileRepostsCubit>(tester.element(find.byType(PostCard).first));
      verify(reposts.ensureLoaded).called(1);

      // The own profile: Reposts before Saved, and its own empty state.
      await pump(tester, [...appStores(), ...profileScreen(ownProfile)], const ProfileView(isTab: true));
      final own = tester.widgetList<Tab>(find.byType(Tab)).map((t) => t.text).toList();
      expect(own.indexOf(l10n.profileTabReposts), own.indexOf(l10n.profileTabSaved) - 1);
      await tester.tap(find.text(l10n.profileTabReposts));
      await tester.pumpAndSettle();
      expect(find.text(l10n.profileRepostsEmptyOwnTitle), findsOneWidget);
    });

    testWidgets("someone else's empty Reposts tab says so", (tester) async {
      await pump(tester, [...appStores(), ...profileScreen(otherProfile)], const ProfileView());

      await tester.tap(find.text(l10n.profileTabReposts));
      await tester.pumpAndSettle();
      expect(find.text(l10n.profileRepostsEmptyTitle), findsOneWidget);
      expect(find.text(l10n.profileRepostsEmptyBody), findsOneWidget);
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

      // The tab bar scrolls: with Reposts (F29) the About tab starts off screen.
      await tester.ensureVisible(find.text(l10n.profileTabAbout));
      await tester.pumpAndSettle();
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

    /// The links of [profile] as the cubit starts them.
    List<LinkDraft> draftsOf(UserProfile profile) => [
          for (final (i, link) in profile.links.indexed)
            LinkDraft(id: i, platform: link.platform, url: link.url, label: link.label ?? ''),
        ];

    EditProfileState ready({
      FormStatus status = FormStatus.idle,
      bool uploading = false,
      Map<String, String> errors = const {},
      List<LinkDraft>? links,
    }) =>
        EditProfileState(
          load: EditProfileLoad.ready,
          profile: otherProfile,
          username: otherProfile.username,
          usernameStatus: UsernameStatus.available,
          fields: sampleFields,
          fieldsStatus: EditProfileLoad.ready,
          expertiseIds: const ['f-dotnet'],
          links: links ?? draftsOf(otherProfile),
          status: status,
          uploadingAvatar: uploading,
          errors: errors,
        );

    setUpAll(() => registerFallbackValue(LinkPlatform.other));

    setUp(() {
      cubit = MockEditProfileCubit();
      when(() => cubit.submit(
            displayName: any(named: 'displayName'),
            bio: any(named: 'bio'),
            headline: any(named: 'headline'),
          )).thenAnswer((_) async {});
      when(() => cubit.toggleExpertise(any())).thenReturn(null);
      when(() => cubit.edited(any())).thenReturn(null);
      when(() => cubit.addLink(any())).thenReturn(null);
      when(() => cubit.removeLink(any())).thenReturn(null);
      when(() => cubit.moveLink(any(), any())).thenReturn(null);
      when(() => cubit.reorderLinks(any(), any())).thenReturn(null);
      when(() => cubit.linkUrlChanged(any(), any())).thenReturn(null);
      when(() => cubit.linkLabelChanged(any(), any())).thenReturn(null);
      when(() => cubit.changeLinkPlatform(any(), any())).thenReturn(null);
    });

    Future<void> pumpEdit(WidgetTester tester, EditProfileState state, {Variant? variant}) async {
      cubit.hold(state);
      // Tall enough to build the whole form, the links and the expertise picker included.
      await pump(tester, [...appStores(), BlocProvider<EditProfileCubit>.value(value: cubit)], const EditProfileView(), height: 2600, variant: variant);
    }

    void verifyNoSubmit() => verifyNever(() => cubit.submit(
          displayName: any(named: 'displayName'),
          bio: any(named: 'bio'),
          headline: any(named: 'headline'),
        ));

    Finder urlField(int id) => find.byKey(ValueKey('profile-link-url-$id'));

    testWidgets('starts from the profile and saves what was typed, the title included', (tester) async {
      await pumpEdit(tester, ready());

      expect(find.text('منى عادل'), findsOneWidget);
      expect(find.text(otherProfile.headline!), findsOneWidget);
      expect(find.text('https://github.com/mona-dev'), findsOneWidget);
      await tester.enterText(find.byKey(HeadlineField.fieldKey), 'Staff Engineer | .NET');
      await tester.tap(find.text(l10n.save));
      await tester.pump();

      verify(() => cubit.submit(displayName: 'منى عادل', bio: otherProfile.bio!, headline: 'Staff Engineer | .NET')).called(1);
    });

    testWidgets("the title is one line: a line break can't be typed; the counter shows near 120", (tester) async {
      await pumpEdit(tester, ready());
      final field = find.byKey(HeadlineField.fieldKey);

      await tester.enterText(field, 'Line one\nline two');
      await tester.pump();
      expect(find.text('Line oneline two'), findsOneWidget);
      expect(find.textContaining('/120'), findsNothing);
      await tester.enterText(field, 'x' * 105);
      await tester.pump();
      expect(find.text('105/120'), findsOneWidget);
      await tester.enterText(field, 'x' * 130);
      await tester.pump();
      expect(find.text('120/120'), findsOneWidget);
    });

    testWidgets('the links editor: each link with its platform, address and (for Other) name, in order', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpEdit(tester, ready());

      expect(find.text(l10n.profileLinksSection), findsOneWidget);
      expect(find.text('5/8'), findsOneWidget);
      final urls = [for (var id = 0; id < 5; id++) tester.widget<TextField>(urlField(id))];
      expect(urls.map((f) => f.controller!.text), [
        'https://www.linkedin.com/in/mona-dev',
        'https://github.com/mona-dev',
        'https://x.com/mona_dev',
        'https://mona.dev/',
        'https://mona.dev/podcast',
      ]);
      // Addresses are always left to right.
      expect(urls.every((f) => f.textDirection == TextDirection.ltr), isTrue);
      expect(find.text('بودكاست منى'), findsOneWidget);
      // One name field, for the Other link only.
      expect(find.byKey(const ValueKey('profile-link-label-4')), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-link-label-1')), findsNothing);
      for (final name in ['LinkedIn', 'GitHub', 'X', l10n.profileWebsite, l10n.profileLinkOther]) {
        expect(find.bySemanticsLabel('$name, ${l10n.profileLinkChangePlatform}'), findsOneWidget, reason: name);
      }

      await tester.enterText(urlField(1), 'github.com/mona');
      verify(() => cubit.linkUrlChanged(1, 'github.com/mona')).called(1);
      await tester.enterText(find.byKey(const ValueKey('profile-link-label-4')), 'Podcast');
      verify(() => cubit.linkLabelChanged(4, 'Podcast')).called(1);
      semantics.dispose();
    });

    testWidgets('"Add link" picks a platform; one that already has a link can\'t be picked again', (tester) async {
      await pumpEdit(tester, ready());

      await tester.ensureVisible(find.byKey(ProfileLinksEditor.addKey));
      await tester.tap(find.byKey(ProfileLinksEditor.addKey));
      await tester.pumpAndSettle();

      expect(find.text(l10n.profileLinkPickPlatform), findsOneWidget);
      expect(tester.widget<ListTile>(find.byKey(const ValueKey('link-platform-github'))).enabled, isFalse);
      expect(find.text(l10n.profileLinkPlatformAdded), findsNWidgets(4)); // LinkedIn, GitHub, X, Website
      expect(tester.widget<ListTile>(find.byKey(const ValueKey('link-platform-other'))).enabled, isTrue);

      await tester.tap(find.byKey(const ValueKey('link-platform-instagram')));
      await tester.pumpAndSettle();
      verify(() => cubit.addLink(LinkPlatform.instagram)).called(1);
    });

    testWidgets("each link's menu moves it up or down and removes it", (tester) async {
      await pumpEdit(tester, ready());

      await tester.tap(find.byKey(const ValueKey('profile-link-menu-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.profileLinkMoveUp));
      await tester.pumpAndSettle();
      verify(() => cubit.moveLink(1, -1)).called(1);

      // The first link has no "Move up".
      await tester.tap(find.byKey(const ValueKey('profile-link-menu-0')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.profileLinkMoveUp), findsNothing);
      expect(find.text(l10n.profileLinkMoveDown), findsOneWidget);
      await tester.tap(find.text(l10n.profileLinkRemove));
      await tester.pumpAndSettle();
      verify(() => cubit.removeLink(0)).called(1);
    });

    testWidgets('at 8 links "Add link" is off and says why', (tester) async {
      final eight = [for (var i = 0; i < 8; i++) LinkDraft(id: i, platform: LinkPlatform.other, url: 'https://a$i.dev', label: 'Site $i')];
      await pumpEdit(tester, ready(links: eight));

      expect(find.text('8/8'), findsOneWidget);
      expect(find.text(l10n.profileLinksFull), findsOneWidget);
      expect(tester.widget<OutlinedButton>(find.byKey(ProfileLinksEditor.addKey)).onPressed, isNull);
    });

    testWidgets("each link error shows under its own field, in the screen's language", (tester) async {
      final ar = await AppLocalizations.delegate.load(AppLocales.ar);
      await pumpEdit(
        tester,
        ready(errors: const {
          'links[1].url': FailureCodes.linkHostMismatch,
          'links[4].label': FailureCodes.linkLabelInvalid,
          'links[2].platform': FailureCodes.linkDuplicatePlatform,
          ProfileFields.links: FailureCodes.linkTooMany,
          ProfileFields.headline: FailureCodes.profileHeadlineTooLong,
        }),
        variant: Variant.all.first,
      );

      expect(find.text(ar.profileErrLinkHostMismatch), findsOneWidget);
      expect(find.text(ar.profileErrLinkLabelInvalid), findsOneWidget);
      expect(find.text(ar.profileErrLinkDuplicatePlatform), findsOneWidget);
      expect(find.text(ar.profileErrLinkTooMany), findsOneWidget);
      expect(find.text(ar.profileErrHeadlineTooLong), findsOneWidget);
      // Under the GitHub link's address, not another one.
      expect(find.descendant(of: urlField(1), matching: find.text(ar.profileErrLinkHostMismatch)), findsOneWidget);
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
      await pumpEdit(tester, ready(errors: const {'links[3].url': FailureCodes.linkHttpsRequired, ProfileFields.avatar: FailureCodes.profileAvatarInvalid}));

      expect(find.text(l10n.profileErrLinkHttpsRequired), findsOneWidget);
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
