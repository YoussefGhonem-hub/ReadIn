import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../../onboarding/domain/repositories/interests_repository.dart';
import '../../../onboarding/domain/usecases/save_interests.dart';
import '../../../onboarding/domain/usecases/set_interest.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';

class InterestsState extends Equatable {
  const InterestsState({
    this.loading = true,
    this.failure,
    this.fields = const [],
    this.topics = const {},
    this.fieldIds = const {},
    this.topicIds = const {},
    this.pending = const {},
  });

  /// The fields are loading.
  final bool loading;

  /// Loading the fields failed.
  final Failure? failure;
  final List<Field> fields;

  /// Topics per field id, loaded for the followed fields.
  final Map<String, List<Topic>> topics;
  final Set<String> fieldIds;
  final Set<String> topicIds;

  /// Field and topic ids whose change is being saved.
  final Set<String> pending;

  int get count => fieldIds.length + topicIds.length;

  /// A field's topics are listed while the field is followed, or while one of its topics still is.
  bool showsTopicsOf(Field field) =>
      fieldIds.contains(field.id) || (topics[field.id] ?? const <Topic>[]).any((t) => topicIds.contains(t.id));

  InterestsState copyWith({
    bool? loading,
    Failure? Function()? failure,
    List<Field>? fields,
    Map<String, List<Topic>>? topics,
    Set<String>? fieldIds,
    Set<String>? topicIds,
    Set<String>? pending,
  }) =>
      InterestsState(
        loading: loading ?? this.loading,
        failure: failure != null ? failure() : this.failure,
        fields: fields ?? this.fields,
        topics: topics ?? this.topics,
        fieldIds: fieldIds ?? this.fieldIds,
        topicIds: topicIds ?? this.topicIds,
        pending: pending ?? this.pending,
      );

  /// The same state with [id] followed or not.
  InterestsState _with(InterestKind kind, String id, {required bool followed}) {
    Set<String> apply(Set<String> ids) => followed ? {...ids, id} : ({...ids}..remove(id));
    return kind == InterestKind.field ? copyWith(fieldIds: apply(fieldIds)) : copyWith(topicIds: apply(topicIds));
  }

  @override
  List<Object?> get props => [loading, failure, fields, topics, fieldIds, topicIds, pending];
}

/// Settings → Your interests (F02, F12): the fields and topics followed after onboarding. A chip toggles at once and is
/// saved on its own (`PUT`/`DELETE /me/interests/{fields|topics}/{id}`); when the API refuses, it goes back and the
/// screen says why. At least 3 interests stay followed. Otherwise the state follows `MeDto.interests` from the session.
@injectable
class InterestsCubit extends Cubit<InterestsState> {
  InterestsCubit(this._getFields, this._getTopics, this._setInterest, SessionCubit session)
      : super(InterestsState(
          fieldIds: {...?session.state.me?.interestFieldIds},
          topicIds: {...?session.state.me?.interestTopicIds},
        )) {
    _subscription = session.stream.listen((session) {
      final me = session.me;
      if (me == null || isClosed || state.pending.isNotEmpty) return;
      emit(state.copyWith(fieldIds: {...me.interestFieldIds}, topicIds: {...me.interestTopicIds}));
    });
  }

  final GetFields _getFields;
  final GetTopics _getTopics;
  final SetInterest _setInterest;
  late final StreamSubscription<SessionState> _subscription;

  /// Loads the fields, then the topics of the followed ones (and of the others while a followed topic is unaccounted
  /// for).
  Future<void> load() async {
    emit(state.copyWith(loading: true, failure: () => null));
    final result = await _getFields();
    if (isClosed) return;
    final failure = result.failureOrNull;
    if (failure != null) return emit(state.copyWith(loading: false, failure: () => failure));
    emit(state.copyWith(loading: false, fields: result.valueOrNull));
    await _loadTopics(state.fields.where((f) => state.fieldIds.contains(f.id)));
    bool known(String topicId) => state.topics.values.any((topics) => topics.any((t) => t.id == topicId));
    if (state.topicIds.any((id) => !known(id))) await _loadTopics(state.fields);
  }

  /// Null when saved (or nothing to do), else why not, after going back.
  Future<Failure?> toggleField(Field field) async {
    final followed = !state.fieldIds.contains(field.id);
    final failure = await _toggle(InterestKind.field, field.id, followed: followed);
    if (followed && failure == null) await _loadTopics([field]);
    return failure;
  }

  /// Null when saved (or nothing to do), else why not, after going back.
  Future<Failure?> toggleTopic(Topic topic) =>
      _toggle(InterestKind.topic, topic.id, followed: !state.topicIds.contains(topic.id));

  Future<Failure?> _toggle(InterestKind kind, String id, {required bool followed}) async {
    if (state.pending.contains(id)) return null;
    // The API would refuse it: say so without asking.
    if (!followed && state.count <= SaveInterests.minimum) return const Failure(FailureCodes.interestsMinThree);
    emit(state._with(kind, id, followed: followed).copyWith(pending: {...state.pending, id}));
    final result = await _setInterest(kind, id, followed: followed);
    if (isClosed) return null;
    final failure = result.failureOrNull;
    final settled = state.copyWith(pending: {...state.pending}..remove(id));
    emit(failure == null ? settled : settled._with(kind, id, followed: !followed));
    return failure;
  }

  Future<void> _loadTopics(Iterable<Field> fields) async {
    final missing = [for (final f in fields) if (!state.topics.containsKey(f.id) && f.topicCount > 0) f];
    final results = await Future.wait([for (final f in missing) _getTopics(f.slug)]);
    if (isClosed) return;
    final loaded = {for (var i = 0; i < missing.length; i++) missing[i].id: ?results[i].valueOrNull};
    if (loaded.isNotEmpty) emit(state.copyWith(topics: {...state.topics, ...loaded}));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
