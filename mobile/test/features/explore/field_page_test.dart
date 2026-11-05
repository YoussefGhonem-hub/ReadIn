import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/bidi/bidi.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/features/article/presentation/cubit/post_cards_cubit.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/article/presentation/widgets/reader_widgets.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/explore/domain/entities/explore.dart';
import 'package:readin/features/explore/domain/usecases/explore_usecases.dart';
import 'package:readin/features/explore/presentation/cubit/field_cubits.dart';
import 'package:readin/features/explore/presentation/explore_routes.dart';
import 'package:readin/features/explore/presentation/pages/field_page.dart';
import 'package:readin/features/explore/presentation/widgets/explore_widgets.dart';
import 'package:readin/features/follow/domain/usecases/follow_usecases.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/onboarding/domain/repositories/interests_repository.dart';
import 'package:readin/shared/widgets/state_views.dart';

import '../../helpers/explore_fixtures.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/path_fakes.dart' show pumpRouted;
import '../../helpers/post_card_fixtures.dart';
import '../../helpers/profile_fakes.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

/// A field page (F15): the header with Follow (and the 3-interest rule), the health note, the topic chips with
/// `?topic=`, their ✓ when followed and their own Follow, the top writers' rail, the post cards with infinite scroll,
/// names in the app's language, and the not-found states. The words are the web's (F15 fix).
void main() {
  const en = Variant(AppLocales.en, Brightness.light);
  const ar = Variant(AppLocales.ar, Brightness.light);
  late AppLocalizations l10n;
  late MockSetInterest setInterest;

  setUpAll(() async {
    registerFallbackValue(InterestKind.field);
    l10n = await AppLocalizations.delegate.load(AppLocales.en);
  });

  setUp(() {
    setInterest = MockSetInterest();
    when(() => setInterest(any(), any(), followed: any(named: 'followed'))).thenAnswer((_) async => const Ok(null));
  });

  FakeExploreRepository dotnetRepo({FieldDetails? field, List<List<int>> pages = const [[1, 2]]}) => FakeExploreRepository(
        fields: [field ?? dotnetDetails(lang: 'en'), medicineDetails(lang: 'en'), emptyFieldDetails(lang: 'en')],
        articlePages: {
          'dotnet': [for (final page in pages) [for (final i in page) exploreCard(i, language: 'en')]],
          'dotnet?ef-core': [[exploreCard(5, language: 'en')]],
          'medicine': [[exploreCard(7, language: 'en')]],
        },
        writers: {'dotnet': exploreWriters(), 'medicine': exploreWriters().take(1).toList()},
      );

  /// The page's cubits over [repo], for [slug] on [topic], signed in as [me] (a guest for null).
  List<BlocProvider> fieldProviders(FakeExploreRepository repo, String slug, {String? topic, Me? me}) {
    final header = FieldCubit(GetFieldDetails(repo), setInterest, sessionOf(me));
    final articles = FieldArticlesCubit(GetFieldArticles(repo), slug);
    final store = FollowsCubit(SetFollowing(MockFollowRepository()));
    final writers = FieldWritersCubit(GetFieldWriters(repo), store, slug);
    final cards = PostCardsCubit.withLoader(previewLoader());
    for (final c in [header, articles, store, writers, cards]) {
      addTearDown(c.close);
    }
    unawaited(header.load(slug));
    unawaited(articles.load(fieldSlug: topic));
    unawaited(writers.load());
    return [
      BlocProvider<FieldCubit>.value(value: header),
      BlocProvider<FieldArticlesCubit>.value(value: articles),
      BlocProvider<FieldWritersCubit>.value(value: writers),
      BlocProvider<PostCardsCubit>.value(value: cards),
    ];
  }

  Future<void> pumpField(
    WidgetTester tester,
    FakeExploreRepository repo,
    String slug, {
    String? topic,
    Me? me = sampleMe,
    Variant variant = en,
    bool settle = true,
  }) async {
    usePhoneSurface(tester, size: const Size(390, 1600));
    await tester.pumpWidget(testApp(
      provided([...appStores(me: me), ...fieldProviders(repo, slug, topic: topic, me: me)], const FieldView()),
      variant: variant,
    ));
    if (settle) {
      await tester.pump();
      await tester.pump();
    }
  }

  Finder followField() => find.byKey(const ValueKey('field-follow'));

  testWidgets('the header, the topic chips, the top writers and the articles as post cards', (tester) async {
    final repo = dotnetRepo();
    await pumpField(tester, repo, 'dotnet');

    expect(find.byKey(const ValueKey('field-page-name')), findsOneWidget);
    expect(find.text('${l10n.fieldArticleCount(64)} · ${l10n.fieldFollowerCount(129)}'), findsOneWidget);
    expect(find.descendant(of: followField(), matching: find.text(l10n.fieldFollow)), findsOneWidget, reason: '"Follow field", as on the web');
    expect(find.byType(HealthDisclaimer), findsNothing);
    expect(find.byKey(const ValueKey('field-topic-all')), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('field-topic-all'))).selected, isTrue);
    for (final slug in ['csharp', 'aspnet-core', 'ef-core', 'dotnet-testing', 'mapster']) {
      expect(find.byKey(ValueKey('field-topic-$slug')), findsOneWidget, reason: 'empty topics too: $slug');
    }
    expect(find.text(l10n.fieldTopWriters), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('field-writers')), matching: find.byType(WriterCard)), findsNWidgets(5),
        reason: 'every top writer the API sends (≤ 10), in a rail like Explore and the web');
    expect(find.text(l10n.fieldArticles), findsOneWidget);
    expect(find.byType(PostCard), findsNWidgets(2));
    expect(repo.calls, containsAll(['field dotnet', 'articles dotnet', 'writers dotnet']));
  });

  testWidgets('a sensitive field shows the health note', (tester) async {
    await pumpField(tester, dotnetRepo(), 'medicine');
    expect(find.byType(HealthDisclaimer), findsOneWidget);
    expect(find.text(l10n.healthDisclaimer), findsOneWidget);
    expect(find.text('${l10n.fieldArticleCount(9)} · ${l10n.fieldFollowerCount(1)}'), findsOneWidget);
  });

  testWidgets('Follow: at once, one more follower, through the interests endpoint', (tester) async {
    await pumpField(tester, dotnetRepo(), 'dotnet', me: readerWith(5));
    await tester.tap(followField());
    await tester.pump();

    expect(find.descendant(of: followField(), matching: find.text(l10n.followingState)), findsOneWidget);
    expect(find.text('${l10n.fieldArticleCount(64)} · ${l10n.fieldFollowerCount(130)}'), findsOneWidget);
    verify(() => setInterest(InterestKind.field, 'f-dotnet', followed: true)).called(1);

    await tester.tap(followField());
    await tester.pump();
    expect(find.text('${l10n.fieldArticleCount(64)} · ${l10n.fieldFollowerCount(129)}'), findsOneWidget);
    verify(() => setInterest(InterestKind.field, 'f-dotnet', followed: false)).called(1);
  });

  testWidgets('a guest gets the sign-in prompt and nothing is sent', (tester) async {
    await pumpField(tester, dotnetRepo(), 'dotnet', me: null);
    await tester.tap(followField());
    await tester.pumpAndSettle();
    expect(find.text(l10n.signInPromptTitle), findsOneWidget);
    verifyNever(() => setInterest(any(), any(), followed: any(named: 'followed')));
  });

  testWidgets('one of the last 3 interests: the toggle stays on and says why', (tester) async {
    await pumpField(tester, dotnetRepo(field: dotnetDetails(lang: 'en', isFollowing: true, followerCount: 130)), 'dotnet', me: readerWith(3));
    await tester.tap(followField());
    await tester.pump();
    expect(find.text(l10n.fieldKeepThree), findsOneWidget);
    expect(find.descendant(of: followField(), matching: find.text(l10n.followingState)), findsOneWidget);
    expect(find.text('${l10n.fieldArticleCount(64)} · ${l10n.fieldFollowerCount(130)}'), findsOneWidget);
    verifyNever(() => setInterest(any(), any(), followed: any(named: 'followed')));
  });

  testWidgets('the API refusing it (min_three) also keeps the toggle on', (tester) async {
    when(() => setInterest(InterestKind.field, 'f-dotnet', followed: false))
        .thenAnswer((_) async => const Err(Failure(FailureCodes.interestsMinThree, statusCode: 400)));
    await pumpField(tester, dotnetRepo(field: dotnetDetails(lang: 'en', isFollowing: true, followerCount: 130)), 'dotnet', me: readerWith(6));
    await tester.tap(followField());
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.fieldKeepThree), findsOneWidget);
    expect(find.descendant(of: followField(), matching: find.text(l10n.followingState)), findsOneWidget);
  });

  testWidgets('a topic chip filters the articles and offers Follow for the topic', (tester) async {
    final repo = dotnetRepo();
    await pumpField(tester, repo, 'dotnet');
    await tester.tap(find.byKey(const ValueKey('field-topic-ef-core')));
    await tester.pump();
    await tester.pump();

    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('field-topic-ef-core'))).selected, isTrue);
    expect(find.byType(PostCard), findsOneWidget);
    expect(repo.calls, contains('articles dotnet?ef-core'));
    final follow = find.byKey(const ValueKey('field-topic-follow-ef-core'));
    expect(follow, findsOneWidget);
    expect(find.descendant(of: follow, matching: find.text(l10n.fieldFollowTopic)), findsOneWidget, reason: '"Follow topic", as on the web');
    expect(find.text(l10n.fieldArticleCount(12)), findsOneWidget);

    await tester.tap(follow);
    await tester.pump();
    verify(() => setInterest(InterestKind.topic, 't-ef-core', followed: true)).called(1);
    expect(find.descendant(of: follow, matching: find.text(l10n.followingState)), findsOneWidget);
    expect(find.text('${l10n.fieldArticleCount(64)} · ${l10n.fieldFollowerCount(129)}'), findsOneWidget,
        reason: 'a followed topic is not a field follower');

    await tester.tap(find.byKey(const ValueKey('field-topic-all')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('field-topic-follow-ef-core')), findsNothing);
    expect(find.byType(PostCard), findsNWidgets(2));
  });

  testWidgets('opened on ?topic= (the link Search gives a topic): that chip, its articles, its Follow state', (tester) async {
    final repo = dotnetRepo();
    await pumpField(tester, repo, 'dotnet', topic: 'ASPNET-Core'.toLowerCase());
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('field-topic-aspnet-core'))).selected, isTrue);
    expect(find.descendant(of: find.byKey(const ValueKey('field-topic-follow-aspnet-core')), matching: find.text(l10n.followingState)), findsOneWidget);
    expect(repo.calls, contains('articles dotnet?aspnet-core'));
    expect(find.text(l10n.fieldTopicEmptyTitle), findsOneWidget, reason: 'no page for it in the fake');
  });

  testWidgets('the chip a link selects is scrolled into view', (tester) async {
    await pumpField(tester, dotnetRepo(), 'dotnet', topic: 'mapster');
    await tester.pumpAndSettle();
    final chip = tester.getRect(find.byKey(const ValueKey('field-topic-mapster')));
    expect(chip.left, greaterThanOrEqualTo(0));
    expect(chip.right, lessThanOrEqualTo(390));
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('field-topic-mapster'))).selected, isTrue);
    expect(Scrollable.of(tester.element(find.byKey(const ValueKey('field-page-name')))).position.pixels, 0,
        reason: 'the page itself stays at its top');
  });

  testWidgets('a ?topic= of another field says so and offers the whole field', (tester) async {
    final repo = dotnetRepo();
    await pumpField(tester, repo, 'dotnet', topic: 'react');
    expect(find.text(l10n.fieldTopicNotFoundTitle), findsOneWidget);
    expect(find.text(l10n.fieldTopicNotFoundBody('${Bidi.fsi}.NET${Bidi.pdi}')), findsOneWidget, reason: 'it names the field');
    expect(find.text('${l10n.fieldArticleCount(64)} · ${l10n.fieldFollowerCount(129)}'), findsOneWidget, reason: 'the header stays');

    await tester.tap(find.byKey(const ValueKey('field-show-all')));
    await tester.pump();
    await tester.pump();
    expect(find.byType(PostCard), findsNWidgets(2));
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('field-topic-all'))).selected, isTrue);
  });

  testWidgets('an empty field: its empty state, and no writers section', (tester) async {
    await pumpField(tester, dotnetRepo(), 'law');
    expect(find.text(l10n.fieldEmptyTitle), findsOneWidget);
    expect(find.text(l10n.fieldEmptyBody), findsOneWidget);
    expect(find.text(l10n.fieldTopWriters), findsNothing);
    expect(find.text('${l10n.fieldArticleCount(0)} · ${l10n.fieldFollowerCount(0)}'), findsOneWidget);
  });

  testWidgets('scrolling to the end loads the next page with the cursor', (tester) async {
    final repo = dotnetRepo(pages: const [[1, 2], [3, 4], [5]]);
    usePhoneSurface(tester);
    await tester.pumpWidget(testApp(provided([...appStores(), ...fieldProviders(repo, 'dotnet', me: sampleMe)], const FieldView()), variant: en));
    await tester.pump();
    await tester.pump();
    final articles = BlocProvider.of<FieldArticlesCubit>(tester.element(find.byType(FieldView)));

    for (var i = 0; i < 8 && articles.state.hasMore; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pump();
      await tester.pump();
    }
    expect(articles.state.items.map((a) => a.id), ['art-1', 'art-2', 'art-3', 'art-4', 'art-5']);
    expect(repo.calls, containsAllInOrder(['articles dotnet', 'articles dotnet c1', 'articles dotnet c2']));
  });

  testWidgets('an unknown field says it does not exist and leads to Explore', (tester) async {
    final opened = <String>[];
    final repo = dotnetRepo();
    await pumpRouted(tester, const FieldView(), opened: opened, providers: fieldProviders(repo, 'nope', me: sampleMe));
    await tester.pump();
    expect(find.text(l10n.fieldNotFoundTitle), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing, reason: 'nothing to retry');
    await tester.tap(find.byKey(const ValueKey('field-go-explore')));
    await tester.pumpAndSettle();
    expect(opened, ['/explore']);
  });

  testWidgets('skeleton while loading; an error offers retry, which loads the page', (tester) async {
    final gate = Completer<void>();
    final repo = dotnetRepo()
      ..gate = gate
      ..failure = const Failure(FailureCodes.networkOffline);
    await pumpField(tester, repo, 'dotnet', settle: false);
    await tester.pump();
    expect(find.byKey(const ValueKey('field-skeleton')), findsOneWidget);

    gate.complete();
    repo.gate = null;
    await tester.pump();
    await tester.pump();
    expect(find.byType(ErrorView), findsOneWidget);

    repo.failure = null;
    await tester.tap(find.text(l10n.retry));
    await tester.pump();
    await tester.pump();
    expect(find.byType(PostCard), findsNWidgets(2));
    expect(find.byType(WriterCard), findsWidgets);
  });

  testWidgets('opened from a link with no page under it, back goes Home', (tester) async {
    final opened = <String>[];
    await pumpRouted(tester, const FieldView(), opened: opened, providers: fieldProviders(dotnetRepo(), 'dotnet', me: sampleMe));
    await tester.pump();
    final home = find.byKey(const ValueKey('field-page-home'));
    expect(tester.widget<IconButton>(home).tooltip, const DefaultMaterialLocalizations().backButtonTooltip);
    await tester.tap(home);
    await tester.pumpAndSettle();
    expect(opened, ['/home']);
  });

  testWidgets('Arabic: the page reads right to left; topic names with English runs keep their order', (tester) async {
    final repo = FakeExploreRepository(fields: [dotnetDetails()], articlePages: {'dotnet': [exploreCards(count: 1)]});
    await pumpField(tester, repo, 'dotnet', variant: ar);
    expect(Directionality.of(tester.element(find.byType(FieldView))), TextDirection.rtl);
    final l10nAr = await AppLocalizations.delegate.load(AppLocales.ar);
    expect(find.text('${l10nAr.fieldArticleCount(64)} · ${l10nAr.fieldFollowerCount(129)}'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('field-topic-dotnet-testing')), matching: find.textContaining('Testing')), findsOneWidget);
  });

  testWidgets('the chip of a followed topic has a ✓ (read out as "Following"); a guest sees none', (tester) async {
    Finder mark(String slug) => find.descendant(of: find.byKey(ValueKey('field-topic-$slug')), matching: find.byKey(const ValueKey('field-topic-following')));
    await pumpField(tester, dotnetRepo(), 'dotnet');
    expect(mark('aspnet-core'), findsOneWidget);
    expect(tester.widget<Icon>(mark('aspnet-core')).semanticLabel, l10n.followingState);
    for (final slug in ['csharp', 'ef-core', 'dotnet-testing', 'mapster']) {
      expect(mark(slug), findsNothing, reason: slug);
    }

    // Following another topic marks its chip at once.
    await tester.tap(find.byKey(const ValueKey('field-topic-ef-core')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('field-topic-follow-ef-core')));
    await tester.pump();
    expect(mark('ef-core'), findsOneWidget);

    await pumpField(tester, dotnetRepo(field: dotnetDetails(lang: 'en')), 'dotnet', me: null);
    expect(find.byKey(const ValueKey('field-topic-following')), findsNothing);
  });

  testWidgets('names follow the language the app is in, also for a page loaded in the other one', (tester) async {
    // Loaded while the app was in English (the API's `name` is English), shown in Arabic.
    final l10nAr = await AppLocalizations.delegate.load(AppLocales.ar);
    final repo = dotnetRepo();
    await pumpField(tester, repo, 'medicine', variant: ar);
    expect(find.descendant(of: find.byKey(const ValueKey('field-page-name')), matching: find.textContaining('الطب')), findsOneWidget);
    expect(find.textContaining('Medicine'), findsNothing);
    expect(find.descendant(of: find.byKey(const ValueKey('field-follow')), matching: find.text(l10nAr.fieldFollow)), findsOneWidget);

    await pumpField(tester, repo, 'dotnet', topic: 'dotnet-testing', variant: ar);
    expect(find.descendant(of: find.byKey(const ValueKey('field-topic-dotnet-testing')), matching: find.textContaining(' في ')), findsOneWidget);
    expect(find.textContaining('Testing in .NET'), findsNothing);
  });

  testWidgets('no articles and no followers read "0 articles · 0 followers", as on the web', (tester) async {
    final l10nAr = await AppLocalizations.delegate.load(AppLocales.ar);
    await pumpField(tester, dotnetRepo(), 'law', variant: ar);
    expect(find.text('0 مقال · 0 متابع'), findsOneWidget);
    expect(l10nAr.fieldArticleCount(0), '0 مقال');
    expect(l10n.fieldArticleCount(0), '0 articles');
    expect(l10n.fieldFollowerCount(0), '0 followers');
  });

  test('field links: /f/{slug} and ?topic=', () {
    expect(ExploreRoutes.field('dotnet'), '/f/dotnet');
    expect(ExploreRoutes.field('dotnet', topic: 'ef-core'), '/f/dotnet?topic=ef-core');
    expect(ExploreRoutes.field('dotnet', topic: ''), '/f/dotnet');
    expect(ExploreRoutes.topicOf(Uri.parse('/f/dotnet?topic=ef-core')), 'ef-core');
    expect(ExploreRoutes.topicOf(Uri.parse('/f/dotnet?topic=')), isNull);
    expect(ExploreRoutes.topicOf(Uri.parse('/f/dotnet')), isNull);
    expect(ExploreRoutes.ranking(ExploreRanking.mostSaved), '/explore/most-saved');
    expect(ExploreRanking.fromPath('trending'), ExploreRanking.trending);
    expect(ExploreRanking.fromPath('nope'), isNull);
  });
}
