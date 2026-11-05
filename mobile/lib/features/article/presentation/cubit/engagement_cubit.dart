import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../reactions/domain/usecases/reaction_usecases.dart';
import '../../../reposts/domain/usecases/repost_usecases.dart';
import '../../../saved/domain/usecases/saved_usecases.dart';
import '../../domain/entities/article.dart';

/// What the viewer sees of an article's reactions, comments, saves and reposts (F10, F13, F27, F29).
class ArticleEngagement extends Equatable {
  const ArticleEngagement({
    this.reactions = ReactionCounts.zero,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.saveCount = 0,
    this.myReaction,
    this.isSaved = false,
    this.reacting = false,
    this.saving = false,
    this.repostCount = 0,
    this.isReposted = false,
    this.reposting = false,
  });

  factory ArticleEngagement.of(ArticleCard card) => ArticleEngagement(
        reactions: card.reactions,
        reactionCount: card.reactionCount,
        commentCount: card.commentCount,
        saveCount: card.saveCount,
        myReaction: card.myReaction,
        isSaved: card.isSaved,
        repostCount: card.repostCount,
        isReposted: card.isReposted,
      );

  final ReactionCounts reactions;
  final int reactionCount;
  final int commentCount;
  final int saveCount;
  final ReactionType? myReaction;
  final bool isSaved;

  /// A reaction or save request is in flight: the button ignores taps (no double submits).
  final bool reacting;
  final bool saving;

  final int repostCount;
  final bool isReposted;

  /// A repost request is in flight.
  final bool reposting;

  /// [card] with these values.
  ArticleCard applyTo(ArticleCard card) => card.copyWithEngagement(
        reactions: reactions,
        reactionCount: reactionCount,
        commentCount: commentCount,
        saveCount: saveCount,
        myReaction: () => myReaction,
        isSaved: isSaved,
        repostCount: repostCount,
        isReposted: isReposted,
      );

  @override
  List<Object?> get props => [
        reactions,
        reactionCount,
        commentCount,
        saveCount,
        myReaction,
        isSaved,
        reacting,
        saving,
        repostCount,
        isReposted,
        reposting,
      ];
}

/// The newest known values of one article, laid over the card each screen loaded. A null field is not known here and
/// keeps the card's value (e.g. live counters say nothing about the viewer's own reaction).
class EngagementOverlay extends Equatable {
  const EngagementOverlay({
    this.reactions,
    this.reactionCount,
    this.commentCount,
    this.saveCount,
    this.hasMyReaction = false,
    this.myReaction,
    this.isSaved,
    this.reacting = false,
    this.saving = false,
    this.repostCount,
    this.isReposted,
    this.reposting = false,
  });

  /// Everything about [card], as just loaded from the API.
  factory EngagementOverlay.of(ArticleCard card) => EngagementOverlay(
        reactions: card.reactions,
        reactionCount: card.reactionCount,
        commentCount: card.commentCount,
        saveCount: card.saveCount,
        hasMyReaction: true,
        myReaction: card.myReaction,
        isSaved: card.isSaved,
        repostCount: card.repostCount,
        isReposted: card.isReposted,
      );

  final ReactionCounts? reactions;
  final int? reactionCount;
  final int? commentCount;
  final int? saveCount;

  /// [myReaction] is known (null then means "none").
  final bool hasMyReaction;
  final ReactionType? myReaction;
  final bool? isSaved;
  final bool reacting;
  final bool saving;
  final int? repostCount;
  final bool? isReposted;
  final bool reposting;

  bool get pending => reacting || saving || reposting;

  ArticleEngagement resolve(ArticleCard card) => ArticleEngagement(
        reactions: reactions ?? card.reactions,
        reactionCount: reactionCount ?? card.reactionCount,
        commentCount: commentCount ?? card.commentCount,
        saveCount: saveCount ?? card.saveCount,
        myReaction: hasMyReaction ? myReaction : card.myReaction,
        isSaved: isSaved ?? card.isSaved,
        reacting: reacting,
        saving: saving,
        repostCount: repostCount ?? card.repostCount,
        isReposted: isReposted ?? card.isReposted,
        reposting: reposting,
      );

  /// Null arguments keep the current value.
  EngagementOverlay merge({
    ReactionCounts? reactions,
    int? reactionCount,
    int? commentCount,
    int? saveCount,
    ReactionType? Function()? myReaction,
    bool? isSaved,
    bool? reacting,
    bool? saving,
    int? repostCount,
    bool? isReposted,
    bool? reposting,
  }) =>
      EngagementOverlay(
        reactions: reactions ?? this.reactions,
        reactionCount: reactionCount ?? this.reactionCount,
        commentCount: commentCount ?? this.commentCount,
        saveCount: saveCount ?? this.saveCount,
        hasMyReaction: myReaction != null || hasMyReaction,
        myReaction: myReaction != null ? myReaction() : this.myReaction,
        isSaved: isSaved ?? this.isSaved,
        reacting: reacting ?? this.reacting,
        saving: saving ?? this.saving,
        repostCount: repostCount ?? this.repostCount,
        isReposted: isReposted ?? this.isReposted,
        reposting: reposting ?? this.reposting,
      );

  /// This overlay with the reaction values of [before] (a rollback), keeping everything about saves and reposts.
  EngagementOverlay withReactionOf(EngagementOverlay? before) => EngagementOverlay(
        reactions: before?.reactions,
        reactionCount: before?.reactionCount,
        commentCount: commentCount,
        saveCount: saveCount,
        hasMyReaction: before?.hasMyReaction ?? false,
        myReaction: before?.myReaction,
        isSaved: isSaved,
        saving: saving,
        repostCount: repostCount,
        isReposted: isReposted,
        reposting: reposting,
      );

  /// This overlay with the save values of [before] (a rollback), keeping everything about reactions and reposts.
  EngagementOverlay withSaveOf(EngagementOverlay? before) => EngagementOverlay(
        reactions: reactions,
        reactionCount: reactionCount,
        commentCount: commentCount,
        saveCount: before?.saveCount,
        hasMyReaction: hasMyReaction,
        myReaction: myReaction,
        isSaved: before?.isSaved,
        reacting: reacting,
        repostCount: repostCount,
        isReposted: isReposted,
        reposting: reposting,
      );

  /// This overlay with the repost values of [before] (a rollback), keeping everything about reactions and saves.
  EngagementOverlay withRepostOf(EngagementOverlay? before) => EngagementOverlay(
        reactions: reactions,
        reactionCount: reactionCount,
        commentCount: commentCount,
        saveCount: saveCount,
        hasMyReaction: hasMyReaction,
        myReaction: myReaction,
        isSaved: isSaved,
        reacting: reacting,
        saving: saving,
        repostCount: before?.repostCount,
        isReposted: before?.isReposted,
      );

  @override
  List<Object?> get props => [
        reactions,
        reactionCount,
        commentCount,
        saveCount,
        hasMyReaction,
        myReaction,
        isSaved,
        reacting,
        saving,
        repostCount,
        isReposted,
        reposting,
      ];
}

class EngagementState extends Equatable {
  const EngagementState([this.overlays = const {}]);

  final Map<String, EngagementOverlay> overlays;

  ArticleEngagement of(ArticleCard card) => overlays[card.id]?.resolve(card) ?? ArticleEngagement.of(card);

  @override
  List<Object?> get props => [overlays];
}

/// A save or unsave the API confirmed.
class SavedChange extends Equatable {
  const SavedChange(this.article, {required this.isSaved});

  final ArticleCard article;
  final bool isSaved;

  @override
  List<Object?> get props => [article, isSaved];
}

/// One place for the viewer's reactions, saves and reposts and the newest counters of every article on screen, so the
/// reader, the feeds and the Saved tab always agree (F10, F13, F27, F29).
///
/// Screens [seed] it with what they load. The viewer's own actions apply at once and roll back when the API refuses
/// them; the API's answer then replaces the optimistic values. Live counters [applyLive] **replace** the numbers and
/// never add to them, so the viewer's own reaction is never counted twice.
@lazySingleton
class EngagementCubit extends Cubit<EngagementState> {
  EngagementCubit(this._setReaction, this._setSaved, [this._setReposted]) : super(const EngagementState());

  final SetReaction _setReaction;
  final SetSaved _setSaved;

  /// Always set in the app; tests of screens without reposts may leave it out (a repost then fails and rolls back).
  final SetReposted? _setReposted;
  final _savedChanges = StreamController<SavedChange>.broadcast();

  /// Saves and unsaves confirmed by the API (the Saved list and collections follow them).
  Stream<SavedChange> get savedChanges => _savedChanges.stream;

  ArticleEngagement of(ArticleCard card) => state.of(card);

  /// Values just loaded from the API become the newest, except for articles with a request in flight.
  void seed(Iterable<ArticleCard> cards) {
    final next = {...state.overlays};
    var changed = false;
    for (final card in cards) {
      if (next[card.id]?.pending ?? false) continue;
      final seeded = EngagementOverlay.of(card);
      if (next[card.id] == seeded) continue;
      next[card.id] = seeded;
      changed = true;
    }
    if (changed) emit(EngagementState(next));
  }

  /// Live counters (`/live/articles/{id}`): they replace the counts; unknown fields keep theirs.
  void applyLive(String articleId, LiveArticleCounts live) {
    final reactions = live.reactions;
    if (reactions == null && live.commentCount == null && live.saveCount == null && live.repostCount == null) return;
    _update(
      articleId,
      (overlay) => overlay.merge(
        reactions: reactions == null ? null : ReactionCounts.fromMap(reactions),
        reactionCount: live.reactionCount,
        commentCount: live.commentCount,
        saveCount: live.saveCount,
        // While the viewer's own repost is in flight its optimistic count stays; the API's answer replaces it.
        repostCount: overlay.reposting ? null : live.repostCount,
      ),
    );
  }

  /// The comments sheet's count (F11): the page's `total`, then the viewer's own posts and deletes. It replaces the
  /// count, as live counters do.
  void setCommentCount(String articleId, int count) =>
      _update(articleId, (overlay) => overlay.merge(commentCount: math.max(0, count)));

  /// The reaction button: 💡 when the viewer hasn't reacted, otherwise removes their reaction.
  Future<Failure?> tapReaction(ArticleCard card) =>
      react(card, of(card).myReaction == null ? ReactionType.insightful : null);

  /// The picker: choosing the current reaction removes it.
  Future<Failure?> pickReaction(ArticleCard card, ReactionType type) => react(card, of(card).myReaction == type ? null : type);

  /// Sets ([type]) or removes (null) the viewer's reaction. Null on success (or nothing to do), else the failure
  /// after rolling back.
  Future<Failure?> react(ArticleCard card, ReactionType? type) async {
    final current = of(card);
    if (current.reacting || current.myReaction == type) return null;
    final before = state.overlays[card.id];
    final change = (type == null ? 0 : 1) - (current.myReaction == null ? 0 : 1);
    _update(
      card.id,
      (overlay) => overlay.merge(
        reactions: current.reactions.move(from: current.myReaction, to: type),
        reactionCount: math.max(0, current.reactionCount + change),
        myReaction: () => type,
        reacting: true,
      ),
    );
    final result = await _setReaction(card.id, type);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        _update(card.id, (overlay) => overlay.withReactionOf(before));
        return failure;
      },
      (reactions) {
        _update(
          card.id,
          (overlay) => overlay.merge(
            reactions: reactions.reactions,
            reactionCount: reactions.total,
            myReaction: () => reactions.myReaction,
            reacting: false,
          ),
        );
        return null;
      },
    );
  }

  Future<Failure?> toggleSave(ArticleCard card) => setSaved(card, saved: !of(card).isSaved);

  /// Saves or unsaves [card]; null on success (or nothing to do), else the failure after rolling back.
  Future<Failure?> setSaved(ArticleCard card, {required bool saved}) async {
    final current = of(card);
    if (current.saving || current.isSaved == saved) return null;
    final before = state.overlays[card.id];
    _update(
      card.id,
      (overlay) => overlay.merge(
        isSaved: saved,
        saveCount: math.max(0, current.saveCount + (saved ? 1 : -1)),
        saving: true,
      ),
    );
    final result = await _setSaved(card, saved: saved);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        _update(card.id, (overlay) => overlay.withSaveOf(before));
        return failure;
      },
      (saveState) {
        _update(card.id, (overlay) => overlay.merge(isSaved: saveState.isSaved, saveCount: saveState.saveCount, saving: false));
        _savedChanges.add(SavedChange(of(card).applyTo(card), isSaved: saveState.isSaved));
        return null;
      },
    );
  }

  Future<Failure?> toggleRepost(ArticleCard card) => setReposted(card, reposted: !of(card).isReposted);

  /// Reposts [card] or undoes the viewer's repost (F29); null on success (or nothing to do), else the failure after
  /// rolling back. The count moves at once and the API's answer replaces it.
  Future<Failure?> setReposted(ArticleCard card, {required bool reposted}) async {
    final current = of(card);
    if (current.reposting || current.isReposted == reposted) return null;
    final before = state.overlays[card.id];
    _update(
      card.id,
      (overlay) => overlay.merge(
        isReposted: reposted,
        repostCount: math.max(0, current.repostCount + (reposted ? 1 : -1)),
        reposting: true,
      ),
    );
    final setReposted = _setReposted;
    if (setReposted == null) {
      _update(card.id, (overlay) => overlay.withRepostOf(before));
      return Failure.unknown;
    }
    final result = await setReposted(card.id, reposted: reposted);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        _update(card.id, (overlay) => overlay.withRepostOf(before));
        return failure;
      },
      (repostState) {
        _update(
          card.id,
          (overlay) => overlay.merge(isReposted: repostState.isReposted, repostCount: repostState.repostCount, reposting: false),
        );
        return null;
      },
    );
  }

  /// Another account (or a guest) is using the app: nothing about the previous viewer stays.
  void reset() => emit(const EngagementState());

  void _update(String articleId, EngagementOverlay Function(EngagementOverlay overlay) change) {
    if (isClosed) return;
    final next = change(state.overlays[articleId] ?? const EngagementOverlay());
    emit(EngagementState({...state.overlays, articleId: next}));
  }

  @override
  Future<void> close() async {
    await _savedChanges.close();
    return super.close();
  }
}
