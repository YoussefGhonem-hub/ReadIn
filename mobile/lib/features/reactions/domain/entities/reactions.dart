import 'package:equatable/equatable.dart';

import '../../../article/domain/entities/article.dart';

/// `ArticleReactionsDto`: an article's reactions after a change (F10).
class ArticleReactions extends Equatable {
  const ArticleReactions({required this.reactions, required this.total, this.myReaction});

  final ReactionCounts reactions;
  final int total;
  final ReactionType? myReaction;

  @override
  List<Object?> get props => [reactions, total, myReaction];
}

/// `ReactorDto`: who reacted, newest first.
class Reactor extends Equatable {
  const Reactor({required this.user, required this.type, required this.reactedAt});

  final Author user;
  final ReactionType type;
  final DateTime reactedAt;

  @override
  List<Object?> get props => [user, type, reactedAt];
}
