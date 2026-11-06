import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/l10n/l10n_x.dart';
import 'package:readin/core/theme/theme_x.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/article/presentation/widgets/post_card.dart';
import 'package:readin/features/auth/presentation/session/session_cubit.dart';
import 'package:readin/features/follow/presentation/cubit/follows_cubit.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/reposts/data/datasources/reposts_api.dart';
import 'package:readin/features/reposts/data/models/repost_models.dart';
import 'package:readin/features/reposts/data/repositories/reposts_repository_impl.dart';
import 'package:readin/features/reposts/domain/entities/repost_state.dart';
import 'package:readin/features/reposts/domain/repositories/reposts_repository.dart';
import 'package:readin/features/reposts/domain/usecases/repost_usecases.dart';
import 'package:readin/features/reposts/presentation/widgets/repost_button.dart';
import 'package:readin/features/reposts/presentation/widgets/repost_caption_sheet.dart';
import 'package:readin/features/reposts/presentation/widgets/repost_label.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';
import 'package:readin/features/saved/presentation/cubit/collections_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/post_card_fixtures.dart';
import '../../helpers/social_fakes.dart';
import '../../helpers/test_app.dart';

class MockRepostsRepository extends Mock implements RepostsRepository {}

class MockRepostsApi extends Mock implements RepostsApi {}

/// "Repost with your thoughts" (F29): the menu by state (own article, guests), the caption sheet (counter, limit,
/// submit, errors, prefill), the cubit flows (a caption waits for the API, undo is optimistic, the prefill), the caption
/// under the label on the post card, and the API mapping.
void main() {
  late MockRepostsRepository reposts;
  late EngagementCubit engagement;

  /// Someone else's article, reposted 3 times, not by the viewer.
  final card = engagedCard(1).copyWithEngagement(repostCount: 3);
  final reposted = card.copyWithEngagement(isReposted: true);

  const tooLong = Failure(
    FailureCodes.validationFailed,
    statusCode: 400,
    fieldErrors: {
      'caption': [FailureCodes.repostCaptionTooLong],
    },
  );

  setUpAll(() => registerFallbackValue(const RepostRequest()));

  setUp(() {
    reposts = MockRepostsRepository();
    engagement = EngagementCubit(
      SetReaction(MockReactionsRepository()),
      SetSaved(MockSavedRepository()),
      SetReposted(reposts),
      GetRepost(reposts),
    );
  });
  tearDown(() => engagement.close());

  group('the engagement store', () {
    test('a repost with a caption waits for the API, then takes its state, count and caption', () async {
      final answer = Completer<Result<RepostState>>();
      when(() => reposts.repost(card.id, caption: 'Worth it')).thenAnswer((_) => answer.future);

      final done = engagement.repostWithCaption(card, 'Worth it');
      expect(engagement.of(card).isReposted, isFalse, reason: 'not optimistic');
      expect(engagement.of(card).repostCount, 3);
      expect(engagement.of(card).reposting, isTrue);

      answer.complete(const Ok(RepostState(repostCount: 4, isReposted: true, caption: 'Worth it')));
      expect(await done, isNull);
      expect(engagement.of(card).isReposted, isTrue);
      expect(engagement.of(card).repostCount, 4);
      expect(engagement.of(card).reposting, isFalse);
      expect(engagement.of(card).hasRepostCaption, isTrue);
      expect(engagement.of(card).repostCaption, 'Worth it');
    });

    test('a refused caption changes nothing and returns the failure', () async {
      when(() => reposts.repost(card.id, caption: any(named: 'caption'))).thenAnswer((_) async => const Err(tooLong));

      expect(await engagement.repostWithCaption(card, 'x' * 501), tooLong);
      expect(engagement.of(card).isReposted, isFalse);
      expect(engagement.of(card).repostCount, 3);
      expect(engagement.of(card).reposting, isFalse);
      expect(engagement.of(card).hasRepostCaption, isFalse);
    });

    test('editing the caption of a repost: the count stays, the caption is replaced; "" clears it', () async {
      when(() => reposts.repost(reposted.id, caption: 'Edited'))
          .thenAnswer((_) async => const Ok(RepostState(repostCount: 3, isReposted: true, caption: 'Edited')));
      when(() => reposts.repost(reposted.id, caption: ''))
          .thenAnswer((_) async => const Ok(RepostState(repostCount: 3, isReposted: true)));

      expect(await engagement.repostWithCaption(reposted, 'Edited'), isNull);
      expect(engagement.of(reposted).repostCount, 3);
      expect(engagement.of(reposted).repostCaption, 'Edited');

      expect(await engagement.repostWithCaption(reposted, ''), isNull);
      expect(engagement.of(reposted).hasRepostCaption, isTrue);
      expect(engagement.of(reposted).repostCaption, isNull);
    });

    test('nothing is sent while another repost request is in flight', () async {
      final answer = Completer<Result<RepostState>>();
      when(() => reposts.repost(card.id)).thenAnswer((_) => answer.future);
      final quick = engagement.setReposted(card, reposted: true);

      expect(await engagement.repostWithCaption(card, 'Late'), isNull);
      verifyNever(() => reposts.repost(card.id, caption: 'Late'));

      answer.complete(const Ok(RepostState(repostCount: 4, isReposted: true)));
      await quick;
    });

    test('a quick repost is optimistic and sends no caption; undo is optimistic and the caption goes with it', () async {
      when(() => reposts.repost(card.id)).thenAnswer((_) async => const Ok(RepostState(repostCount: 4, isReposted: true)));
      final quick = engagement.setReposted(card, reposted: true);
      expect(engagement.of(card).isReposted, isTrue, reason: 'a quick repost shows at once');
      expect(await quick, isNull);
      verify(() => reposts.repost(card.id)).called(1);
      expect(engagement.of(card).repostCaption, isNull);

      when(() => reposts.repost(card.id, caption: 'Mine'))
          .thenAnswer((_) async => const Ok(RepostState(repostCount: 4, isReposted: true, caption: 'Mine')));
      expect(await engagement.repostWithCaption(card, 'Mine'), isNull);
      expect(engagement.of(card).repostCaption, 'Mine');

      final answer = Completer<Result<RepostState>>();
      when(() => reposts.undoRepost(card.id)).thenAnswer((_) => answer.future);
      final undo = engagement.setReposted(card, reposted: false);
      expect(engagement.of(card).isReposted, isFalse, reason: 'undo shows at once');
      expect(engagement.of(card).repostCount, 3);
      answer.complete(const Ok(RepostState(repostCount: 3, isReposted: false)));
      expect(await undo, isNull);
      expect(engagement.of(card).hasRepostCaption, isTrue);
      expect(engagement.of(card).repostCaption, isNull);
    });

    test('the prefill loads the repost now: its state, count and caption become the newest', () async {
      when(() => reposts.getRepost(reposted.id))
          .thenAnswer((_) async => const Ok(RepostState(repostCount: 6, isReposted: true, caption: 'Read this\ntwice')));

      final result = await engagement.loadRepost(reposted);
      expect(result.valueOrNull?.caption, 'Read this\ntwice');
      expect(engagement.of(reposted).repostCount, 6);
      expect(engagement.of(reposted).repostCaption, 'Read this\ntwice');

      when(() => reposts.getRepost(reposted.id)).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));
      expect((await engagement.loadRepost(reposted)).failureOrNull?.code, FailureCodes.networkOffline);
      expect(engagement.of(reposted).repostCount, 6, reason: 'a failed load changes nothing');
    });

    test('a rollback of a quick repost restores what was known of the caption', () async {
      when(() => reposts.repost(card.id, caption: 'Kept'))
          .thenAnswer((_) async => const Ok(RepostState(repostCount: 4, isReposted: true, caption: 'Kept')));
      when(() => reposts.undoRepost(card.id)).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));

      await engagement.repostWithCaption(card, 'Kept');
      expect(await engagement.setReposted(card, reposted: false), isA<Failure>());
      expect(engagement.of(card).isReposted, isTrue);
      expect(engagement.of(card).repostCount, 4);
      expect(engagement.of(card).repostCaption, 'Kept');
    });
  });

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool signedIn = true,
    Variant variant = const Variant(AppLocales.en, Brightness.light),
  }) async {
    usePhoneSurface(tester);
    final session = MockSessionCubit();
    whenListen(
      session,
      const Stream<SessionState>.empty(),
      initialState: signedIn ? const SessionState(status: SessionStatus.authenticated, me: sampleMe) : const SessionState(status: SessionStatus.guest),
    );
    final follows = MockFollowsCubit();
    whenListen(follows, const Stream<FollowsState>.empty(), initialState: const FollowsState());
    final collections = MockCollectionsCubit();
    whenListen(collections, const Stream<CollectionsState>.empty(), initialState: const CollectionsState());
    await tester.pumpWidget(testApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionCubit>.value(value: session),
          BlocProvider<EngagementCubit>.value(value: engagement),
          BlocProvider<FollowsCubit>.value(value: follows),
          BlocProvider<CollectionsCubit>.value(value: collections),
        ],
        child: Scaffold(body: Center(child: child)),
      ),
      variant: variant,
    ));
    await tester.pump();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(RepostButton));
    await tester.pumpAndSettle();
  }

  group('the Repost menu', () {
    testWidgets('not reposted yet: Repost and Repost with your thoughts', (tester) async {
      await pump(tester, RepostButton(article: card));
      await openMenu(tester);
      expect(find.text('Repost'), findsOneWidget);
      expect(find.text('Repost with your thoughts'), findsOneWidget);
      expect(find.text('Edit your thoughts'), findsNothing);
      expect(find.text('Undo repost'), findsNothing);
      verifyZeroInteractions(reposts);
    });

    testWidgets('Arabic: "أعد النشر" and "أعد النشر مع رأيك"', (tester) async {
      await pump(tester, RepostButton(article: card), variant: const Variant(AppLocales.ar, Brightness.light));
      await openMenu(tester);
      expect(find.text('إعادة النشر'), findsOneWidget);
      expect(find.text('إعادة النشر مع رأيك'), findsOneWidget);
    });

    testWidgets('Arabic, reposted: "عدّل رأيك" and "إلغاء إعادة النشر"', (tester) async {
      await pump(tester, RepostButton(article: reposted), variant: const Variant(AppLocales.ar, Brightness.light));
      await openMenu(tester);
      expect(find.text('تعديل رأيك'), findsOneWidget);
      expect(find.text('إلغاء إعادة النشر'), findsOneWidget);
    });

    testWidgets('reposted: Edit your thoughts and Undo repost; undo takes one off at once', (tester) async {
      final answer = Completer<Result<RepostState>>();
      when(() => reposts.undoRepost(reposted.id)).thenAnswer((_) => answer.future);
      await pump(tester, RepostButton(article: reposted));
      await openMenu(tester);
      expect(find.text('Edit your thoughts'), findsOneWidget);
      expect(find.text('Undo repost'), findsOneWidget);
      expect(find.text('Repost with your thoughts'), findsNothing);

      await tester.tap(find.text('Undo repost'));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget, reason: 'optimistic');
      answer.complete(const Ok(RepostState(repostCount: 2, isReposted: false)));
      await tester.pumpAndSettle();
      verify(() => reposts.undoRepost(reposted.id)).called(1);
    });

    testWidgets('your own article: no menu, the hint; guests: the sign-in prompt, no menu', (tester) async {
      final mine = ArticleCard(
        id: card.id,
        slug: card.slug,
        language: card.language,
        title: card.title,
        field: card.field,
        author: const Author(id: 'u-1', displayName: 'Youssef Hassan', username: 'reader1'),
        readingTimeMinutes: card.readingTimeMinutes,
        publishedAt: card.publishedAt,
      );
      await pump(tester, RepostButton(article: mine));
      await tester.tap(find.byType(RepostButton));
      await tester.pumpAndSettle();
      expect(find.text("You can't repost your own article"), findsOneWidget);
      expect(find.text('Repost with your thoughts'), findsNothing);

      await pump(tester, RepostButton(article: card), signedIn: false);
      await tester.tap(find.byType(RepostButton));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Repost with your thoughts'), findsNothing);
      verifyZeroInteractions(reposts);
    });
  });

  group('the caption sheet', () {
    Finder submit() => find.byKey(const ValueKey('repost-caption-submit'));
    bool submitEnabled(WidgetTester tester) => tester.widget<FilledButton>(submit()).onPressed != null;
    Text counter(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('repost-caption-counter')));

    /// [settle] false while the prefill is still loading (its spinner never settles).
    Future<void> openWithThoughts(WidgetTester tester, ArticleCard article, {bool settle = true}) async {
      await pump(tester, RepostButton(article: article));
      await openMenu(tester);
      await tester.tap(find.text(article.isReposted ? 'Edit your thoughts' : 'Repost with your thoughts'));
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    testWidgets('the title, the article, the placeholder, the counter; submitting reposts with the caption', (tester) async {
      when(() => reposts.repost(card.id, caption: 'Read this\ntwice.'))
          .thenAnswer((_) async => const Ok(RepostState(repostCount: 4, isReposted: true, caption: 'Read this\ntwice.')));
      await openWithThoughts(tester, card);

      expect(find.text('Repost this article'), findsOneWidget);
      expect(find.text('ReadIn Editorial'), findsOneWidget, reason: "the article's author");
      expect(find.textContaining('Transient'), findsOneWidget, reason: "the article's title");
      expect(find.text('Add your thoughts… (optional)'), findsOneWidget);
      expect(counter(tester).data, '0/500');
      expect(find.text('Cancel'), findsOneWidget);
      expect(submitEnabled(tester), isTrue, reason: 'the caption is optional');

      await tester.enterText(find.byType(TextField), '  Read this\r\ntwice.  ');
      await tester.pump();
      expect(counter(tester).data, '16/500', reason: 'counted as the API stores it: trimmed, CRLF as LF');

      await tester.tap(submit());
      await tester.pumpAndSettle();
      verify(() => reposts.repost(card.id, caption: 'Read this\ntwice.')).called(1);
      expect(find.text('Repost this article'), findsNothing, reason: 'closed once saved');
      expect(find.text('You reposted this article.'), findsOneWidget, reason: 'a message confirms it, as on the web');
      expect(find.text('4'), findsOneWidget);
      expect(engagement.of(card).isReposted, isTrue);
    });

    testWidgets('Arabic: the sheet texts, and "أعدت نشر المقال." once reposted', (tester) async {
      when(() => reposts.repost(card.id, caption: '')).thenAnswer((_) async => const Ok(RepostState(repostCount: 4, isReposted: true)));
      await pump(tester, RepostButton(article: card), variant: const Variant(AppLocales.ar, Brightness.light));
      await openMenu(tester);
      await tester.tap(find.text('إعادة النشر مع رأيك'));
      await tester.pumpAndSettle();
      expect(find.text('إعادة نشر المقال'), findsOneWidget);
      expect(find.text('اكتب رأيك في المقال… (اختياري)'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);

      await tester.tap(find.text('نشر'));
      await tester.pumpAndSettle();
      expect(find.text('تمت إعادة نشر المقال.'), findsOneWidget);
    });

    testWidgets('over 500 characters: the counter turns red, the message shows and Repost is disabled', (tester) async {
      await openWithThoughts(tester, card);
      await tester.enterText(find.byType(TextField), 'a' * 501);
      await tester.pump();
      final colors = tester.element(find.byType(RepostCaptionSheet)).colors;
      expect(counter(tester).data, '501/500');
      expect(counter(tester).style?.color, colors.error);
      expect(find.text('Your thoughts must be 500 characters or fewer.'), findsOneWidget);
      expect(submitEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), 'a' * 500);
      await tester.pump();
      expect(counter(tester).style?.color, colors.textSecondary);
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('a refusal keeps the sheet open with the message (caption_too_long, own_article)', (tester) async {
      when(() => reposts.repost(card.id, caption: 'Too long')).thenAnswer((_) async => const Err(tooLong));
      when(() => reposts.repost(card.id, caption: 'Mine'))
          .thenAnswer((_) async => const Err(Failure(FailureCodes.repostOwnArticle, statusCode: 400)));
      await openWithThoughts(tester, card);

      await tester.enterText(find.byType(TextField), 'Too long');
      await tester.tap(submit());
      await tester.pumpAndSettle();
      expect(find.text('Repost this article'), findsOneWidget);
      expect(find.text('Your thoughts must be 500 characters or fewer.'), findsOneWidget);
      expect(engagement.of(card).isReposted, isFalse);

      await tester.enterText(find.byType(TextField), 'Mine');
      await tester.tap(submit());
      await tester.pumpAndSettle();
      expect(find.text("You can't repost your own article."), findsOneWidget);
      expect(find.text('Repost this article'), findsOneWidget);
    });

    testWidgets('Edit your thoughts: prefilled from the API, Save sends the new caption, the count stays', (tester) async {
      final load = Completer<Result<RepostState>>();
      when(() => reposts.getRepost(reposted.id)).thenAnswer((_) => load.future);
      when(() => reposts.repost(reposted.id, caption: 'Even better'))
          .thenAnswer((_) async => const Ok(RepostState(repostCount: 3, isReposted: true, caption: 'Even better')));
      await openWithThoughts(tester, reposted, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'loading the caption');
      expect(submitEnabled(tester), isFalse);
      load.complete(const Ok(RepostState(repostCount: 3, isReposted: true, caption: 'Good one')));
      await tester.pumpAndSettle();
      expect(find.text('Good one'), findsOneWidget);
      expect(counter(tester).data, '8/500');
      expect(find.text('Save'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Even better');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      verify(() => reposts.repost(reposted.id, caption: 'Even better')).called(1);
      expect(find.text('Repost this article'), findsNothing);
      expect(find.text('Your thoughts were saved.'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Edit your thoughts: a failed load offers Try again', (tester) async {
      var calls = 0;
      when(() => reposts.getRepost(reposted.id)).thenAnswer((_) async => calls++ == 0
          ? const Err(Failure(FailureCodes.networkOffline))
          : const Ok(RepostState(repostCount: 3, isReposted: true, caption: 'Back')));
      await openWithThoughts(tester, reposted);
      expect(find.text("You're offline. Check your connection."), findsOneWidget);
      expect(submitEnabled(tester), isFalse);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Back'), findsOneWidget);
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('Cancel closes it and sends nothing', (tester) async {
      await openWithThoughts(tester, card);
      await tester.enterText(find.byType(TextField), 'Never mind');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Repost this article'), findsNothing);
      expect(find.text('You reposted this article.'), findsNothing);
      verifyZeroInteractions(reposts);
    });

    testWidgets('it rides above the keyboard', (tester) async {
      await openWithThoughts(tester, card);
      final before = tester.getBottomLeft(submit()).dy;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(submit()).dy, lessThanOrEqualTo(before - 300 + 1));
    });

    testWidgets('an Arabic caption is laid out right to left in the English UI', (tester) async {
      await openWithThoughts(tester, card);
      await tester.enterText(find.byType(TextField), 'مقال مهم جدًا');
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).textDirection, TextDirection.rtl);
    });
  });

  group('the caption on the post card', () {
    RepostLabel label(String? caption, {Author user = const Author(id: 'w-9', displayName: 'Mona', username: 'mona')}) =>
        RepostLabel(user: user, repostedAt: DateTime.utc(2026, 11, 2, 9), caption: caption);

    ArticleCard placed(String? caption, {Author? user}) =>
        postCard(5, language: 'en', cover: false, repostedBy: user == null ? label(caption) : label(caption, user: user));

    Finder captionText() => find.descendant(of: find.byType(RepostCaptionText), matching: find.byType(Text));

    testWidgets('under the label, above the header, with its line breaks and its own direction', (tester) async {
      await pump(tester, SingleChildScrollView(child: PostCard(article: placed('مقال لازم يتقري\nخصوصًا الجزء التاني'))));
      expect(find.byType(RepostCaptionText), findsOneWidget);
      final text = tester.widget<Text>(captionText());
      expect(text.data, 'مقال لازم يتقري\nخصوصًا الجزء التاني');
      expect(text.textDirection, TextDirection.rtl, reason: 'its first strong character, in the English UI');

      final labelBottom = tester.getBottomLeft(find.byType(RepostLabelText)).dy;
      final captionTop = tester.getTopLeft(find.byType(RepostCaptionText)).dy;
      final headerTop = tester.getTopLeft(find.text('ReadIn Editorial')).dy;
      expect(captionTop, greaterThanOrEqualTo(labelBottom));
      expect(headerTop, greaterThan(tester.getBottomLeft(find.byType(RepostCaptionText)).dy));
    });

    testWidgets('no caption, no text under the label', (tester) async {
      await pump(tester, SingleChildScrollView(child: PostCard(article: placed(null))));
      expect(find.byType(RepostLabelText), findsOneWidget);
      expect(find.byType(RepostCaptionText), findsNothing);
    });

    testWidgets('a long caption is cut with "… Read more"; a tap shows it whole', (tester) async {
      final long = List.filled(40, 'This one changed how I think about dependency injection.').join(' ');
      await pump(tester, SingleChildScrollView(child: PostCard(article: placed(long))));
      expect(find.textContaining('Read more'), findsWidgets);
      final cut = tester.widget<Text>(captionText());
      expect(cut.maxLines, 4);

      await tester.tap(find.byType(RepostCaptionText));
      await tester.pump();
      final whole = tester.widget<Text>(captionText());
      expect(whole.data, long);
      expect(whole.maxLines, isNull);
    });

    testWidgets("the viewer's own repost shows the caption they just saved", (tester) async {
      const me = Author(id: 'u-1', displayName: 'Youssef Hassan', username: 'reader1');
      final mine = placed('Old thoughts', user: me);
      when(() => reposts.repost(mine.id, caption: 'New thoughts'))
          .thenAnswer((_) async => const Ok(RepostState(repostCount: 1, isReposted: true, caption: 'New thoughts')));
      await pump(tester, SingleChildScrollView(child: PostCard(article: mine)));
      expect(tester.widget<Text>(captionText()).data, 'Old thoughts');

      await engagement.repostWithCaption(mine, 'New thoughts');
      await tester.pump();
      expect(tester.widget<Text>(captionText()).data, 'New thoughts');
    });
  });

  group('API', () {
    test('PUT with no body, PUT with { caption }, GET and DELETE map to the state', () async {
      final api = MockRepostsApi();
      final repository = RepostsRepositoryImpl(api);
      when(() => api.repost('a1')).thenAnswer((_) async => const RepostStateModel(repostCount: 4, isReposted: true));
      when(() => api.repostWithCaption('a1', const RepostRequest(caption: 'Hi')))
          .thenAnswer((_) async => const RepostStateModel(repostCount: 4, isReposted: true, caption: 'Hi'));
      when(() => api.getRepost('a1')).thenAnswer((_) async => const RepostStateModel(repostCount: 4, isReposted: true, caption: ' '));

      expect((await repository.repost('a1')).valueOrNull, const RepostState(repostCount: 4, isReposted: true));
      verifyNever(() => api.repostWithCaption(any(), any()));
      expect((await repository.repost('a1', caption: 'Hi')).valueOrNull, const RepostState(repostCount: 4, isReposted: true, caption: 'Hi'));
      expect((await repository.getRepost('a1')).valueOrNull?.caption, isNull, reason: 'a blank caption is none');
    });

    test('RepostRequest: a string is sent as is ("" clears); null is left out (keeps it)', () {
      expect(const RepostRequest(caption: 'Hi').toJson(), {'caption': 'Hi'});
      expect(const RepostRequest(caption: '').toJson(), {'caption': ''});
      expect(const RepostRequest().toJson(), isEmpty);
    });

    test('RepostStateDto: caption read, missing or null is none, and none without a repost', () {
      expect(RepostStateModel.fromJson({'repostCount': 2, 'isReposted': true, 'caption': 'Line 1\nLine 2'}).toEntity().caption,
          'Line 1\nLine 2');
      expect(RepostStateModel.fromJson({'repostCount': 2, 'isReposted': true}).toEntity().caption, isNull);
      expect(RepostStateModel.fromJson({'repostCount': 2, 'isReposted': true, 'caption': null}).toEntity().caption, isNull);
      expect(RepostStateModel.fromJson({'repostCount': 1, 'isReposted': false, 'caption': 'x'}).toEntity().caption, isNull);
    });

    test("RepostLabelDto: the label user's caption; missing, null or blank is none", () {
      Map<String, dynamic> json([Object? caption = #missing]) => {
            'user': {'id': 'r', 'displayName': 'Mona', 'username': 'mona'},
            'othersCount': 0,
            'repostedAt': '2026-11-02T09:00:00Z',
            if (caption != #missing) 'caption': caption,
          };
      expect(RepostLabelModel.fromJson(json('أول سطر\nتاني سطر')).toEntity().caption, 'أول سطر\nتاني سطر');
      expect(RepostLabelModel.fromJson(json()).toEntity().caption, isNull);
      expect(RepostLabelModel.fromJson(json(null)).toEntity().caption, isNull);
      expect(RepostLabelModel.fromJson(json('   ')).toEntity().caption, isNull);
    });

    test('caption_too_long inside validation.failed reads as its message', () {
      expect(tooLong.fieldErrors['caption'], [FailureCodes.repostCaptionTooLong]);
      expect(RepostState.normalizeCaption(' a\r\nb '), 'a\nb');
    });
  });
}
