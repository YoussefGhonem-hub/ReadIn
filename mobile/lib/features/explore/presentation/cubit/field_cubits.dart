import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/cursor_page.dart';
import '../../../article/domain/entities/article.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../follow/domain/entities/follow.dart';
import '../../../follow/presentation/cubit/follows_cubit.dart';
import '../../../home/presentation/cubit/feed_cubit.dart';
import '../../../onboarding/domain/repositories/interests_repository.dart';
import '../../../onboarding/domain/usecases/save_interests.dart';
import '../../../onboarding/domain/usecases/set_interest.dart';
import '../../domain/entities/explore.dart';
import '../../domain/usecases/explore_usecases.dart';

/// `404 field.not_found`: the field is unknown or disabled.
bool isFieldNotFound(Failure? failure) =>
    failure?.code == FailureCodes.fieldNotFound || (failure?.statusCode == 404 && failure?.code != FailureCodes.topicNotFound);

/// `404 topic.not_found`: the `?topic=` isn't one of the field's topics.
bool isTopicNotFound(Failure? failure) => failure?.code == FailureCodes.topicNotFound;

enum FieldStatus { loading, ready, failure }

class FieldState extends Equatable {
  const FieldState({this.status = FieldStatus.loading, this.field, this.failure, this.pending = const {}});

  final FieldStatus status;
  final FieldDetails? field;
  final Failure? failure;

  /// The field or topic ids whose follow is in flight: their toggles ignore taps.
  final Set<String> pending;

  bool get notFound => status == FieldStatus.failure && isFieldNotFound(failure);

  FieldState copyWith({FieldDetails? field, Set<String>? pending}) =>
      FieldState(status: status, field: field ?? this.field, failure: failure, pending: pending ?? this.pending);

  @override
  List<Object?> get props => [status, field, failure, pending];
}

/// A field page's header (F15): `GET /fields/{slug}`, and following the field or one of its topics with the
/// interests endpoints (F12). A follow shows at once (the follower count moves by one) and goes back when the API
/// refuses it; unfollowing the last 3 interests is refused before asking, so the toggle stays on.
@injectable
class FieldCubit extends Cubit<FieldState> {
  FieldCubit(this._getField, this._setInterest, this._session) : super(const FieldState());

  final GetFieldDetails _getField;
  final SetInterest _setInterest;
  final SessionCubit _session;
  String? _slug;

  /// Incremented on every load so an older answer is dropped.
  int _generation = 0;

  Future<void> load(String slug) async {
    _slug = slug;
    final generation = ++_generation;
    emit(const FieldState());
    final result = await _getField(slug);
    if (generation != _generation || isClosed) return;
    emit(result.fold(
      (failure) => FieldState(status: FieldStatus.failure, failure: failure),
      (field) => FieldState(status: FieldStatus.ready, field: field),
    ));
  }

  /// Pull to refresh: the header stays until the new one arrives; a failed refresh keeps it. Not while a follow is in
  /// flight, so its answer isn't overwritten.
  Future<void> refresh() async {
    final slug = _slug;
    if (slug == null) return;
    if (state.field == null) return load(slug);
    if (state.pending.isNotEmpty) return;
    final generation = ++_generation;
    final result = await _getField(slug);
    if (generation != _generation || isClosed || state.pending.isNotEmpty) return;
    if (result case Ok(value: final field)) emit(FieldState(status: FieldStatus.ready, field: field));
  }

  /// Follows or unfollows the field. Null when done (or nothing to do), else why it went back.
  Future<Failure?> toggleField() async {
    final field = state.field;
    if (field == null) return null;
    final follow = !field.isFollowing;
    return _toggle(
      InterestKind.field,
      field.id,
      follow: follow,
      apply: (f, on) => f.copyWith(
        isFollowing: on,
        followerCount: on ? f.followerCount + 1 : (f.followerCount > 0 ? f.followerCount - 1 : 0),
      ),
    );
  }

  /// Follows or unfollows one of the field's topics.
  Future<Failure?> toggleTopic(FieldTopic topic) {
    final current = state.field?.topics.where((t) => t.id == topic.id).firstOrNull ?? topic;
    return _toggle(
      InterestKind.topic,
      topic.id,
      follow: !current.isFollowing,
      apply: (f, on) => f.copyWith(topics: [for (final t in f.topics) t.id == topic.id ? t.withFollowing(on) : t]),
    );
  }

  Future<Failure?> _toggle(
    InterestKind kind,
    String id, {
    required bool follow,
    required FieldDetails Function(FieldDetails field, bool following) apply,
  }) async {
    final field = state.field;
    if (field == null || state.pending.contains(id)) return null;
    // The API would refuse it (fewer than 3 interests would remain): say so without asking.
    final me = _session.state.me;
    if (!follow && me != null && me.interestFieldIds.length + me.interestTopicIds.length <= SaveInterests.minimum) {
      return const Failure(FailureCodes.interestsMinThree);
    }
    emit(state.copyWith(field: apply(field, follow), pending: {...state.pending, id}));
    final result = await _setInterest(kind, id, followed: follow);
    if (isClosed) return null;
    final failure = result.failureOrNull;
    final now = state.field!;
    emit(state.copyWith(field: failure == null ? now : apply(now, !follow), pending: {...state.pending}..remove(id)));
    return failure;
  }
}

/// A field page's articles (F15): the whole field, or one topic's, newest first, with pull to refresh and infinite
/// scroll. The feed's filter ([FeedState.fieldSlug]) holds the selected topic's slug here; null is "All".
@injectable
class FieldArticlesCubit extends ArticleFeedCubit {
  FieldArticlesCubit(this._getArticles, @factoryParam this.slug);

  final GetFieldArticles _getArticles;

  /// The field's slug.
  final String slug;

  /// The selected topic chip; null for the whole field.
  String? get topic => state.fieldSlug;

  /// Shows one topic's articles, or the whole field's for null.
  Future<void> selectTopic(String? topic) => selectField(topic);

  @override
  Future<Result<CursorPage<ArticleCard>>> fetch({String? fieldSlug, String? cursor}) =>
      _getArticles(slug, topic: fieldSlug, cursor: cursor);
}

enum FieldWritersStatus { loading, ready, failure }

class FieldWritersState extends Equatable {
  const FieldWritersState({this.status = FieldWritersStatus.loading, this.users = const [], this.failure});

  final FieldWritersStatus status;
  final List<UserSummary> users;
  final Failure? failure;

  @override
  List<Object?> get props => [status, users, failure];
}

/// "Top writers in this field" (F15): the most read and reacted to in the last 90 days, each with Follow (F12).
@injectable
class FieldWritersCubit extends Cubit<FieldWritersState> {
  FieldWritersCubit(this._getWriters, this._follows, @factoryParam this.slug) : super(const FieldWritersState());

  final GetFieldWriters _getWriters;
  final FollowsCubit _follows;
  final String slug;

  /// Incremented on every load so an older answer is dropped.
  int _generation = 0;

  Future<void> load() => _load(keep: false);

  /// Pull to refresh: the writers stay until the new ones arrive; a failed refresh keeps them.
  Future<void> refresh() => _load(keep: state.status == FieldWritersStatus.ready);

  Future<void> _load({required bool keep}) async {
    final generation = ++_generation;
    if (!keep) emit(const FieldWritersState());
    final result = await _getWriters(slug);
    if (generation != _generation || isClosed) return;
    result.fold(
      (failure) {
        if (!keep) emit(FieldWritersState(status: FieldWritersStatus.failure, failure: failure));
      },
      (users) {
        _follows.seed({for (final user in users) user.id: user.isFollowing});
        emit(FieldWritersState(status: FieldWritersStatus.ready, users: users));
      },
    );
  }
}
