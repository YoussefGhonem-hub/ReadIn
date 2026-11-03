import 'package:equatable/equatable.dart';

import '../../../../core/realtime/realtime_service.dart' show ReactionType;

export '../../../../core/realtime/realtime_service.dart' show ReactionType;

/// Per-type reaction counts of an article (`ReactionCountsDto`, SPEC F10).
class ReactionCounts extends Equatable {
  const ReactionCounts({this.insightful = 0, this.love = 0, this.fire = 0, this.mindBlown = 0});

  /// Live counters (`/live/articles/{id}/reactions`) or any map keyed by type; missing types count as 0.
  factory ReactionCounts.fromMap(Map<ReactionType, int> counts) => ReactionCounts(
        insightful: counts[ReactionType.insightful] ?? 0,
        love: counts[ReactionType.love] ?? 0,
        fire: counts[ReactionType.fire] ?? 0,
        mindBlown: counts[ReactionType.mindBlown] ?? 0,
      );

  static const zero = ReactionCounts();

  final int insightful;
  final int love;
  final int fire;
  final int mindBlown;

  int of(ReactionType type) => switch (type) {
        ReactionType.insightful => insightful,
        ReactionType.love => love,
        ReactionType.fire => fire,
        ReactionType.mindBlown => mindBlown,
      };

  int get total => insightful + love + fire + mindBlown;

  ReactionCounts withCount(ReactionType type, int count) {
    final value = count < 0 ? 0 : count;
    return ReactionCounts(
      insightful: type == ReactionType.insightful ? value : insightful,
      love: type == ReactionType.love ? value : love,
      fire: type == ReactionType.fire ? value : fire,
      mindBlown: type == ReactionType.mindBlown ? value : mindBlown,
    );
  }

  /// The counts after one person's reaction changes from [from] to [to] (either may be null: none).
  ReactionCounts move({ReactionType? from, ReactionType? to}) {
    if (from == to) return this;
    var counts = this;
    if (from != null) counts = counts.withCount(from, counts.of(from) - 1);
    if (to != null) counts = counts.withCount(to, counts.of(to) + 1);
    return counts;
  }

  @override
  List<Object?> get props => [insightful, love, fire, mindBlown];
}

/// The wire value of a reaction type: `insightful | love | fire | mindBlown` (the enum names).
ReactionType? reactionTypeFromWire(String? value) => value == null ? null : ReactionType.values.asNameMap()[value];
