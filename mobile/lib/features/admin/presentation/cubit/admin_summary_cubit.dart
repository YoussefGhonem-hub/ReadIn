import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/admin_dashboard.dart';
import '../../domain/usecases/admin_usecases.dart';

/// The badge on the console entry (F23): open reports + open tickets + pending verification requests, from
/// `GET /admin/summary`. Null until loaded; a failed load keeps the last numbers.
///
/// It refreshes when the entry or the console is shown ([watch]), when the app comes back to the foreground, and every
/// [interval] while one of them is shown. Only holders of `admin.access` see those, so nobody else ever asks.
@lazySingleton
class AdminSummaryCubit extends Cubit<AdminSummary?> with WidgetsBindingObserver {
  AdminSummaryCubit(this._getSummary) : super(null);

  final GetAdminSummary _getSummary;

  static const interval = Duration(seconds: 60);

  int _watchers = 0;
  Timer? _timer;

  // Bumped by every load, so an older answer never replaces a newer one.
  int _version = 0;

  /// Whether an entry or the console is shown now.
  bool get isWatched => _watchers > 0;

  Future<void> load() async {
    final version = ++_version;
    final result = await _getSummary();
    if (isClosed || version != _version) return;
    if (result.valueOrNull case final summary?) emit(summary);
  }

  /// After an action in the console: re-reads the numbers if anything shows them.
  Future<void> refresh() async {
    if (isWatched || state != null) await load();
  }

  /// An entry or the console appeared: load now, then every [interval] and on resume until the last one goes.
  void watch() {
    if (_watchers++ == 0) {
      _timer = Timer.periodic(interval, (_) => unawaited(load()));
      WidgetsBinding.instance.addObserver(this);
    }
    unawaited(load());
  }

  void unwatch() {
    if (_watchers == 0) return;
    if (--_watchers == 0) _stop();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isWatched) unawaited(load());
  }

  @override
  Future<void> close() {
    if (_watchers > 0) _stop();
    _watchers = 0;
    return super.close();
  }
}

/// Keeps [AdminSummaryCubit] watched while [child] is on screen.
class AdminSummaryWatcher extends StatefulWidget {
  const AdminSummaryWatcher({super.key, required this.cubit, required this.child});

  final AdminSummaryCubit cubit;
  final Widget child;

  @override
  State<AdminSummaryWatcher> createState() => _AdminSummaryWatcherState();
}

class _AdminSummaryWatcherState extends State<AdminSummaryWatcher> {
  @override
  void initState() {
    super.initState();
    widget.cubit.watch();
  }

  @override
  void dispose() {
    widget.cubit.unwatch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
