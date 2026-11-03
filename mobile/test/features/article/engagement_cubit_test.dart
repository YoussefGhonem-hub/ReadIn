import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:readin/core/errors/failure.dart';
import 'package:readin/core/errors/result.dart';
import 'package:readin/core/realtime/realtime_service.dart';
import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/article/presentation/cubit/engagement_cubit.dart';
import 'package:readin/features/reactions/domain/entities/reactions.dart';
import 'package:readin/features/reactions/domain/usecases/reaction_usecases.dart';
import 'package:readin/features/saved/domain/entities/saved.dart';
import 'package:readin/features/saved/domain/usecases/saved_usecases.dart';

import '../../helpers/social_fakes.dart';

void main() {
  late MockReactionsRepository reactions;
  late MockSavedRepository saved;
  late EngagementCubit cubit;

  final card = engagedCard(1); // 💡 12 ❤️ 3 🔥 1 = 16, 7 saves, not reacted, not saved

  setUpAll(() {
    registerFallbackValue(card);
    registerFallbackValue(ReactionType.insightful);
  });

  setUp(() {
    reactions = MockReactionsRepository();
    saved = MockSavedRepository();
    cubit = EngagementCubit(SetReaction(reactions), SetSaved(saved));
  });

  tearDown(() => cubit.close());

  group('reactions (F10)', () {
    test('a tap reacts with 💡 at once, then takes the API counts', () async {
      final answer = Completer<Result<ArticleReactions>>();
      when(() => reactions.react(card.id, ReactionType.insightful)).thenAnswer((_) => answer.future);

      final done = cubit.tapReaction(card);
      expect(cubit.of(card).myReaction, ReactionType.insightful);
      expect(cubit.of(card).reactions.insightful, 13);
      expect(cubit.of(card).reactionCount, 17);
      expect(cubit.of(card).reacting, isTrue);

      answer.complete(const Ok(ArticleReactions(reactions: ReactionCounts(insightful: 20, love: 3, fire: 1), total: 24, myReaction: ReactionType.insightful)));
      expect(await done, isNull);
      expect(cubit.of(card).reactionCount, 24, reason: 'the API answer replaces the optimistic count');
      expect(cubit.of(card).reacting, isFalse);
    });

    test('a tap on the current reaction removes it; the picker changes it', () async {
      final mine = engagedCard(1, myReaction: ReactionType.love);
      when(() => reactions.removeReaction(mine.id)).thenAnswer(
        (_) async => const Ok(ArticleReactions(reactions: ReactionCounts(insightful: 12, love: 2, fire: 1), total: 15)),
      );
      when(() => reactions.react(mine.id, ReactionType.fire)).thenAnswer(
        (_) async => const Ok(ArticleReactions(reactions: ReactionCounts(insightful: 12, love: 2, fire: 2), total: 16, myReaction: ReactionType.fire)),
      );

      await cubit.tapReaction(mine);
      expect(cubit.of(mine).myReaction, isNull);
      expect(cubit.of(mine).reactions.love, 2);

      final change = cubit.pickReaction(mine, ReactionType.fire);
      expect(cubit.of(mine).reactions, const ReactionCounts(insightful: 12, love: 2, fire: 2), reason: 'optimistic +1');
      await change;

      when(() => reactions.removeReaction(mine.id)).thenAnswer((_) async => const Ok(ArticleReactions(reactions: ReactionCounts(insightful: 12, love: 2, fire: 1), total: 15)));
      await cubit.pickReaction(mine, ReactionType.fire);
      expect(cubit.of(mine).myReaction, isNull, reason: 'choosing the current reaction removes it');
    });

    test('a refused reaction rolls back and returns the failure', () async {
      when(() => reactions.react(card.id, ReactionType.insightful)).thenAnswer((_) async => const Err(Failure(FailureCodes.networkOffline)));

      final failure = await cubit.tapReaction(card);

      expect(failure!.code, FailureCodes.networkOffline);
      expect(cubit.of(card), ArticleEngagement.of(card));
    });

    test('taps while a request is in flight are ignored (no double submits)', () async {
      final answer = Completer<Result<ArticleReactions>>();
      when(() => reactions.react(any(), any())).thenAnswer((_) => answer.future);

      final first = cubit.tapReaction(card);
      await cubit.tapReaction(card);
      await cubit.pickReaction(card, ReactionType.love);
      answer.complete(const Ok(ArticleReactions(reactions: ReactionCounts(insightful: 13, love: 3, fire: 1), total: 17, myReaction: ReactionType.insightful)));
      await first;

      verify(() => reactions.react(card.id, ReactionType.insightful)).called(1);
      verifyNever(() => reactions.removeReaction(any()));
    });
  });

  group('saves (F13)', () {
    test('save applies at once, keeps the API answer and announces the change', () async {
      final changes = <SavedChange>[];
      final subscription = cubit.savedChanges.listen(changes.add);
      when(() => saved.save(any())).thenAnswer((_) async => const Ok(SaveState(isSaved: true, saveCount: 9)));

      final done = cubit.toggleSave(card);
      expect(cubit.of(card).isSaved, isTrue);
      expect(cubit.of(card).saveCount, 8);
      expect(await done, isNull);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.of(card).saveCount, 9);
      expect(changes.single.isSaved, isTrue);
      expect(changes.single.article.isSaved, isTrue);
      await subscription.cancel();
    });

    test('a refused unsave rolls back and announces nothing', () async {
      final mine = engagedCard(1, isSaved: true);
      final changes = <SavedChange>[];
      final subscription = cubit.savedChanges.listen(changes.add);
      when(() => saved.unsave(mine.id)).thenAnswer((_) async => const Err(Failure(FailureCodes.serverError)));

      final failure = await cubit.setSaved(mine, saved: false);
      await Future<void>.delayed(Duration.zero);

      expect(failure!.code, FailureCodes.serverError);
      expect(cubit.of(mine).isSaved, isTrue);
      expect(cubit.of(mine).saveCount, 7);
      expect(changes, isEmpty);
      await subscription.cancel();
    });

    test('a save and a reaction in flight together roll back separately', () async {
      final save = Completer<Result<SaveState>>();
      when(() => saved.save(any())).thenAnswer((_) => save.future);
      when(() => reactions.react(card.id, ReactionType.insightful)).thenAnswer((_) async => const Err(Failure(FailureCodes.rateLimited)));

      final saving = cubit.toggleSave(card);
      await cubit.tapReaction(card);
      expect(cubit.of(card).isSaved, isTrue, reason: 'the reaction rollback keeps the pending save');
      expect(cubit.of(card).saving, isTrue);

      save.complete(const Ok(SaveState(isSaved: true, saveCount: 8)));
      await saving;
      expect(cubit.of(card).myReaction, isNull);
      expect(cubit.of(card).isSaved, isTrue);
    });
  });

  group('live counters (F27)', () {
    test('replace the counts, never add to them, and keep the viewer state', () async {
      when(() => reactions.react(card.id, ReactionType.insightful)).thenAnswer(
        (_) async => const Ok(ArticleReactions(reactions: ReactionCounts(insightful: 13, love: 3, fire: 1), total: 17, myReaction: ReactionType.insightful)),
      );
      await cubit.tapReaction(card);

      // The outbox recomputed from SQL, the viewer's own reaction included.
      cubit.applyLive(card.id, const LiveArticleCounts(reactions: {ReactionType.insightful: 13, ReactionType.love: 3, ReactionType.fire: 1}, commentCount: 5));

      expect(cubit.of(card).reactionCount, 17, reason: 'not 18: the own reaction is not counted twice');
      expect(cubit.of(card).commentCount, 5);
      expect(cubit.of(card).saveCount, 7, reason: 'unknown live fields keep their value');
      expect(cubit.of(card).myReaction, ReactionType.insightful);
    });

    test('an article seen only through live values keeps the card for the rest', () {
      cubit.applyLive('art-1', const LiveArticleCounts(saveCount: 30));
      expect(cubit.of(card).saveCount, 30);
      expect(cubit.of(card).reactionCount, 16);
      expect(cubit.of(card).isSaved, isFalse);
    });

    test('an empty live value changes nothing', () {
      cubit.applyLive(card.id, const LiveArticleCounts());
      expect(cubit.state.overlays, isEmpty);
    });
  });

  test('fresh API values become the newest, except while a request is in flight', () async {
    cubit.applyLive(card.id, const LiveArticleCounts(commentCount: 99));
    cubit.seed([card]);
    expect(cubit.of(card).commentCount, 4, reason: 'the page loaded after the live value');

    final answer = Completer<Result<SaveState>>();
    when(() => saved.save(any())).thenAnswer((_) => answer.future);
    final saving = cubit.toggleSave(card);
    cubit.seed([card]);
    expect(cubit.of(card).isSaved, isTrue, reason: 'the optimistic save survives a page that loaded meanwhile');
    answer.complete(const Ok(SaveState(isSaved: true, saveCount: 8)));
    await saving;
  });

  test('reset forgets the previous viewer', () async {
    when(() => saved.save(any())).thenAnswer((_) async => const Ok(SaveState(isSaved: true, saveCount: 8)));
    await cubit.toggleSave(card);
    cubit.reset();
    expect(cubit.of(card), ArticleEngagement.of(card));
  });
}
