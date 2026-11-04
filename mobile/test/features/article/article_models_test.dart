import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/article/data/models/article_models.dart';
import 'package:readin/features/article/domain/entities/article.dart';

import '../../helpers/fixtures.dart';
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

    test("the viewer's collections come in the API order; none when absent", () {
      final details = ArticleDetailsModel.fromJson(detailsJson(1, isSaved: true, collectionIds: ['c-2', 'c-1'])).toEntity();
      expect(details.collectionIds, ['c-2', 'c-1']);
      expect(ArticleDetailsModel.fromJson(detailsJson(1, withWave1: false)).toEntity().collectionIds, isEmpty);
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

  group('deleted author (SPEC §9.6)', () {
    test('a card and the reader parse author: null as no author', () {
      final json = detailsJson(1, authorDeleted: true);
      expect(json.containsKey('author'), isTrue, reason: 'the API sends the key with null');

      final details = ArticleDetailsModel.fromJson(json).toEntity();
      expect(details.card.author, isNull);
      expect(details.isFollowingAuthor, isFalse);
      expect(ArticleCardModel.fromJson(json).toEntity().author, isNull);
    });

    test('a missing author key parses the same', () {
      final json = detailsJson(1, authorDeleted: true)..remove('author');
      expect(ArticleCardModel.fromJson(json).toEntity().author, isNull);
      expect(ArticleDetailsModel.fromJson(json).toCard().author, isNull);
    });

    test('the offline copy of a deleted author round-trips without an author', () {
      final model = ArticleDetailsModel.fromJson(detailsJson(1, isSaved: true, authorDeleted: true));
      final stored = model.toJson();
      expect(stored.containsKey('author'), isFalse, reason: 'null fields are left out of the copy');

      final copy = ArticleDetailsModel.fromJson(jsonDecode(jsonEncode(stored)) as Map<String, dynamic>);
      expect(copy, model);
      expect(copy.toEntity(offline: true).card.author, isNull);
    });

    test('copyWith clears and sets the author', () {
      final model = detailsModel(1);
      expect(model.copyWith(author: null).author, isNull);
      expect(model.copyWith(author: null).copyWith(author: model.author).author, model.author);
      expect(model.copyWith.author, isNotNull);
      expect(model.copyWith(author: null).copyWith.author, isNull);
    });

    test('engagement updates keep the missing author', () {
      final card = sampleCard(1, authorDeleted: true).copyWithEngagement(reactionCount: 3, isSaved: true);
      expect(card.author, isNull);
    });
  });

  group('field.isSensitive (health disclaimer, SPEC F04)', () {
    test('a sensitive field ref parses on the reader and the card', () {
      final json = detailsJson(1);
      json['field'] = {...json['field'] as Map<String, dynamic>, 'isSensitive': true};
      expect(ArticleDetailsModel.fromJson(json).toEntity().card.field.isSensitive, isTrue);
      expect(ArticleCardModel.fromJson(json).toEntity().field.isSensitive, isTrue);
    });

    test('an API without it means not sensitive', () {
      expect(ArticleDetailsModel.fromJson(detailsJson(1)).toEntity().card.field.isSensitive, isFalse);
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
