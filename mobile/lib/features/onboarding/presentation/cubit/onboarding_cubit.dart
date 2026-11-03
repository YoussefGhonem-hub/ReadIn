import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../taxonomy/domain/entities/field.dart';
import '../../../taxonomy/domain/usecases/taxonomy_usecases.dart';
import '../../domain/usecases/save_interests.dart';

enum OnboardingStep { welcome, interests, preferences }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.welcome,
    this.loadingFields = false,
    this.fields = const [],
    this.topics = const {},
    this.selectedFieldIds = const {},
    this.selectedTopicIds = const {},
    this.fieldsFailure,
    this.submitting = false,
    this.submitFailure,
    this.completed = false,
  });

  final OnboardingStep step;
  final bool loadingFields;
  final List<Field> fields;

  /// Topics per field id, loaded when a field is selected.
  final Map<String, List<Topic>> topics;
  final Set<String> selectedFieldIds;
  final Set<String> selectedTopicIds;
  final Failure? fieldsFailure;
  final bool submitting;
  final Failure? submitFailure;
  final bool completed;

  int get selectedCount => selectedFieldIds.length + selectedTopicIds.length;
  bool get canContinue => selectedCount >= SaveInterests.minimum;

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? loadingFields,
    List<Field>? fields,
    Map<String, List<Topic>>? topics,
    Set<String>? selectedFieldIds,
    Set<String>? selectedTopicIds,
    Failure? Function()? fieldsFailure,
    bool? submitting,
    Failure? Function()? submitFailure,
    bool? completed,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        loadingFields: loadingFields ?? this.loadingFields,
        fields: fields ?? this.fields,
        topics: topics ?? this.topics,
        selectedFieldIds: selectedFieldIds ?? this.selectedFieldIds,
        selectedTopicIds: selectedTopicIds ?? this.selectedTopicIds,
        fieldsFailure: fieldsFailure != null ? fieldsFailure() : this.fieldsFailure,
        submitting: submitting ?? this.submitting,
        submitFailure: submitFailure != null ? submitFailure() : this.submitFailure,
        completed: completed ?? this.completed,
      );

  @override
  List<Object?> get props => [
        step,
        loadingFields,
        fields,
        topics,
        selectedFieldIds,
        selectedTopicIds,
        fieldsFailure,
        submitting,
        submitFailure,
        completed,
      ];
}

/// Onboarding (F02): welcome → interests (min 3) → preferences.
@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._getFields, this._getTopics, this._saveInterests) : super(const OnboardingState());

  final GetFields _getFields;
  final GetTopics _getTopics;
  final SaveInterests _saveInterests;

  /// Signed-in users skip the welcome step and start at interests,
  /// pre-selecting anything already saved on their profile.
  Future<void> start({required bool signedIn, List<String> fieldIds = const [], List<String> topicIds = const []}) async {
    if (!signedIn) return emit(const OnboardingState());
    emit(OnboardingState(
      step: OnboardingStep.interests,
      selectedFieldIds: fieldIds.toSet(),
      selectedTopicIds: topicIds.toSet(),
    ));
    await loadFields();
    for (final field in state.fields.where((f) => state.selectedFieldIds.contains(f.id))) {
      await _loadTopics(field);
    }
  }

  Future<void> loadFields() async {
    emit(state.copyWith(loadingFields: true, fieldsFailure: () => null));
    final result = await _getFields();
    emit(result.fold(
      (failure) => state.copyWith(loadingFields: false, fieldsFailure: () => failure),
      (fields) => state.copyWith(loadingFields: false, fields: fields),
    ));
  }

  Future<void> toggleField(Field field) async {
    final selected = {...state.selectedFieldIds};
    if (!selected.remove(field.id)) {
      selected.add(field.id);
      emit(state.copyWith(selectedFieldIds: selected));
      await _loadTopics(field);
      return;
    }
    // Deselecting a field also drops its topics.
    final topicIds = (state.topics[field.id] ?? const <Topic>[]).map((t) => t.id).toSet();
    emit(state.copyWith(
      selectedFieldIds: selected,
      selectedTopicIds: state.selectedTopicIds.difference(topicIds),
    ));
  }

  void toggleTopic(Topic topic) {
    final selected = {...state.selectedTopicIds};
    if (!selected.remove(topic.id)) selected.add(topic.id);
    emit(state.copyWith(selectedTopicIds: selected));
  }

  Future<void> _loadTopics(Field field) async {
    if (state.topics.containsKey(field.id) || field.topicCount == 0) return;
    final result = await _getTopics(field.slug);
    if (result.valueOrNull case final topics?) {
      emit(state.copyWith(topics: {...state.topics, field.id: topics}));
    }
  }

  void goToPreferences() {
    if (state.canContinue) emit(state.copyWith(step: OnboardingStep.preferences));
  }

  void backToInterests() => emit(state.copyWith(step: OnboardingStep.interests));

  /// Saves interests (`PUT /me/interests`). Preferences are already synced by
  /// the settings feature as the user changes them.
  Future<void> finish() async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, submitFailure: () => null));
    final result = await _saveInterests(
      fieldIds: state.selectedFieldIds.toList(),
      topicIds: state.selectedTopicIds.toList(),
    );
    emit(result.fold(
      (failure) => state.copyWith(submitting: false, submitFailure: () => failure),
      (_) => state.copyWith(submitting: false, completed: true),
    ));
  }
}
