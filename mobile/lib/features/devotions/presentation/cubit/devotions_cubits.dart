import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/devotions.dart';
import '../../domain/usecases/devotion_usecases.dart';

enum DevotionsStatus { loading, ready, failure }

class SurahState extends Equatable {
  const SurahState({this.status = DevotionsStatus.loading, this.surah, this.failure});

  final DevotionsStatus status;
  final Surah? surah;
  final Failure? failure;

  @override
  List<Object?> get props => [status, surah, failure];
}

/// A surah page (F38): the bundled text.
@injectable
class SurahCubit extends Cubit<SurahState> {
  SurahCubit(this._get) : super(const SurahState());

  final GetSurah _get;

  Future<void> load(int number) async {
    final result = await _get(number);
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => SurahState(status: DevotionsStatus.ready, surah: value),
      Err(:final failure) => SurahState(status: DevotionsStatus.failure, failure: failure),
    });
  }
}

class AdhkarState extends Equatable {
  const AdhkarState({
    this.status = DevotionsStatus.loading,
    this.session = AdhkarSession.morning,
    this.book,
    this.remaining = const {},
    this.failure,
  });

  final DevotionsStatus status;
  final AdhkarSession session;
  final AdhkarBook? book;

  /// Repetitions left per dhikr id; a dhikr not in the map hasn't been started (all its repetitions left).
  final Map<int, int> remaining;
  final Failure? failure;

  List<Dhikr> get items => book?.forSession(session) ?? const [];

  int left(Dhikr dhikr) => remaining[dhikr.id] ?? dhikr.repeat;

  bool done(Dhikr dhikr) => left(dhikr) == 0;

  int get doneCount => items.where(done).length;

  AdhkarState copyWith({Map<int, int>? remaining}) => AdhkarState(
    status: status,
    session: session,
    book: book,
    remaining: remaining ?? this.remaining,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, session, book, remaining, failure];
}

/// The morning or evening adhkar (F38). A tap on a dhikr counts one repetition down to zero; the counts live while
/// the page is open, and «إعادة» starts over.
@injectable
class AdhkarCubit extends Cubit<AdhkarState> {
  AdhkarCubit(this._get) : super(const AdhkarState());

  final GetAdhkar _get;

  Future<void> load(AdhkarSession session) async {
    final result = await _get();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => AdhkarState(status: DevotionsStatus.ready, session: session, book: value),
      Err(:final failure) => AdhkarState(status: DevotionsStatus.failure, session: session, failure: failure),
    });
  }

  void count(Dhikr dhikr) {
    final left = state.left(dhikr);
    if (left == 0) return;
    emit(state.copyWith(remaining: {...state.remaining, dhikr.id: left - 1}));
  }

  void reset() => emit(state.copyWith(remaining: const {}));
}

class DuasState extends Equatable {
  const DuasState({
    this.status = DevotionsStatus.loading,
    this.items = const [],
    this.failure,
    this.busy = false,
    this.remaining = const {},
  });

  final DevotionsStatus status;
  final List<PersonalDua> items;
  final Failure? failure;

  /// A save or a delete is on its way: the buttons wait.
  final bool busy;

  /// Repetitions left per du'a id while the page is open; one not in the map hasn't been started.
  final Map<String, int> remaining;

  int left(PersonalDua dua) => remaining[dua.id] ?? dua.repeat;

  DuasState copyWith({List<PersonalDua>? items, bool? busy, Map<String, int>? remaining}) => DuasState(
    status: status,
    items: items ?? this.items,
    failure: failure,
    busy: busy ?? this.busy,
    remaining: remaining ?? this.remaining,
  );

  @override
  List<Object?> get props => [status, items, failure, busy, remaining];
}

/// «أدعيتي» (F38): the account's own du'as, oldest first; add, edit and delete through the API. Each counts down like
/// the adhkar while the page is open; an edit starts its count over.
@injectable
class DuasCubit extends Cubit<DuasState> {
  DuasCubit(this._get, this._save, this._delete) : super(const DuasState());

  final GetDuas _get;
  final SaveDua _save;
  final DeleteDua _delete;

  /// Most du'as a person keeps (the API's `dua.limit`).
  static const limit = 200;

  Future<void> load() async {
    if (state.status != DevotionsStatus.loading) emit(const DuasState());
    final result = await _get();
    if (isClosed) return;
    emit(switch (result) {
      Ok(:final value) => DuasState(status: DevotionsStatus.ready, items: value),
      Err(:final failure) => DuasState(status: DevotionsStatus.failure, failure: failure),
    });
  }

  /// Adds ([id] null) or replaces a du'a. Null once saved, else why not.
  Future<Failure?> save(DuaDraft draft, {String? id}) async {
    emit(state.copyWith(busy: true));
    final result = await _save(draft, id: id);
    if (isClosed) return result.failureOrNull;
    switch (result) {
      case Ok(:final value):
        final items = id == null
            ? [...state.items, value]
            : [for (final dua in state.items) dua.id == id ? value : dua];
        emit(state.copyWith(items: items, busy: false, remaining: {...state.remaining}..remove(value.id)));
        return null;
      case Err(:final failure):
        emit(state.copyWith(busy: false));
        return failure;
    }
  }

  /// Null once deleted (or already gone), else why it stays.
  Future<Failure?> delete(String id) async {
    emit(state.copyWith(busy: true));
    final failure = (await _delete(id)).failureOrNull;
    if (isClosed) return failure;
    final gone = failure == null || failure.code == FailureCodes.duaNotFound;
    emit(state.copyWith(items: gone ? [...state.items.where((dua) => dua.id != id)] : null, busy: false));
    return gone ? null : failure;
  }

  /// One repetition of [dua], down to zero.
  void count(PersonalDua dua) {
    final left = state.left(dua);
    if (left == 0) return;
    emit(state.copyWith(remaining: {...state.remaining, dua.id: left - 1}));
  }

  void reset() => emit(state.copyWith(remaining: const {}));
}

/// The text size of the surahs and the adhkar (F38), kept on the device: − / + in steps of 10 %.
@lazySingleton
class DevotionsTextSizeCubit extends Cubit<double> {
  DevotionsTextSizeCubit(this._store) : super(_clamp(_store.read<double>(key) ?? 1));

  final KeyValueStore _store;

  static const key = 'devotions.textScale';
  static const min = 0.8;
  static const max = 1.8;
  static const step = 0.1;

  bool get canShrink => state > min + 0.001;
  bool get canGrow => state < max - 0.001;

  Future<void> grow() => _set(state + step);
  Future<void> shrink() => _set(state - step);

  Future<void> _set(double value) async {
    final scale = _clamp(value);
    if (scale == state) return;
    emit(scale);
    await _store.write<double>(key, scale);
  }

  static double _clamp(double value) => (value.clamp(min, max) * 10).roundToDouble() / 10;
}
