import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/moderation.dart';
import '../../domain/usecases/moderation_usecases.dart';

/// Targets with open reports, for the badge on Settings → Moderation and the queue's filters (F22). Null until
/// loaded; a failed load keeps the last counts.
@lazySingleton
class ModerationSummaryCubit extends Cubit<ModerationSummary?> {
  ModerationSummaryCubit(this._getSummary) : super(null);

  final GetModerationSummary _getSummary;

  // Bumped by every load, so an older answer never replaces a newer one.
  int _version = 0;

  Future<void> load() async {
    final version = ++_version;
    final result = await _getSummary();
    if (isClosed || version != _version) return;
    if (result.valueOrNull case final summary?) emit(summary);
  }

  /// After an action: re-reads the counts if anything shows them.
  Future<void> refresh() async {
    if (state != null) await load();
  }
}
