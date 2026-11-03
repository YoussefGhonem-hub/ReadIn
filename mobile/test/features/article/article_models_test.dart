import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/article/domain/entities/article.dart';

import '../../helpers/social_fakes.dart';

void main() {
  group('wave 1 fields', () {
    test('a card carries per-type counts, saves and the viewer state', () {
      final card = ArticleDetailsModel.fromJson(detailsJson(1, isSaved: true)).toCard();
      expect(card.reactions, const ReactionCounts(insightful: 12, love: 3, fire: 1));
      expect(card.reactionCount, 16, reason: 'the total is the sum of the types');
      expect(card.saveCount, 7);
      expect(card.myReaction, ReactionType.love);
      expect(card.isSaved, isTrue);
    });

    test('an API without them still parses, with defaults', () {
      final details = ArticleDetailsModel.fromJson(detailsJson(1, withWave1: false)).toEntity();
      expect(details.card.reactions, ReactionCounts.zero);
      expect(details.card.reactionCount, 16, reason: 'reactionCount stays the total');
      expect(details.card.myReaction, isNull);
      expect(details.card.isSaved, isFalse);
      expect(details.isFollowingAuthor, isFalse);
      expect(details.saveCount, 7);
    });

    test('an unknown reaction type is no reaction', () {
      final json = {...detailsJson(1), 'myReaction': 'clap'};
      expect(ArticleDetailsModel.fromJson(json).toCard().myReaction, isNull);
    });

    test('the details JSON round-trips for the offline copy', () {
      final model = ArticleDetailsModel.fromJson(detailsJson(1, isSaved: true));
      final copy = ArticleDetailsModel.fromJson(jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>);
      expect(copy, model);
      expect(copy.toEntity(offline: true).isOfflineCopy, isTrue);
    });

    test('a feed card parses the same fields', () {
      final card = ArticleCardModel.fromJson({
        ...detailsJson(2),
        'reactions': {'insightful': 1, 'love': 0, 'fire': 2, 'mindBlown': 3},
        'myReaction': 'mindBlown',
      }).toEntity();
      expect(card.reactions.of(ReactionType.mindBlown), 3);
      expect(card.reactionCount, 6);
      expect(card.myReaction, ReactionType.mindBlown);
    });
  });

  group('ReactionCounts', () {
    const counts = ReactionCounts(insightful: 2, love: 1);

    test('move: a new reaction, a change and a removal', () {
      expect(counts.move(to: ReactionType.fire), const ReactionCounts(insightful: 2, love: 1, fire: 1));
      expect(counts.move(from: ReactionType.love, to: ReactionType.insightful), const ReactionCounts(insightful: 3));
      expect(counts.move(from: ReactionType.insightful), const ReactionCounts(insightful: 1, love: 1));
      expect(counts.move(from: ReactionType.fire), counts.withCount(ReactionType.fire, 0), reason: 'never below 0');
    });

    test('from a live map, missing types are 0', () {
      expect(ReactionCounts.fromMap({ReactionType.love: 4}), const ReactionCounts(love: 4));
      expect(ReactionCounts.fromMap({ReactionType.love: 4}).total, 4);
    });
  });
}
