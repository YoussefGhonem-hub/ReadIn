import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../article/presentation/cubit/article_cubit.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/reading.dart';
import '../../domain/usecases/reading_usecases.dart';
import '../cubit/streak_cubit.dart';
import '../widgets/milestone_sheet.dart';
import 'reading_tracker.dart';

/// Connects the article reader to a [ReadingTracker] (F04 "read" rule, F08): wrap the reader below its
/// [ArticleCubit]. Tracking starts once the article is ready, reads the reader's vertical scroll from the scroll
/// notifications that bubble up, counts pointer activity, follows the app lifecycle and whether another screen covers
/// the reader, and hands completed reads to the [StreakCubit] and milestones to the celebration sheet.
class ReadingTracking extends StatefulWidget {
  const ReadingTracking({super.key, required this.child});

  final Widget child;

  @override
  State<ReadingTracking> createState() => _ReadingTrackingState();
}

class _ReadingTrackingState extends State<ReadingTracking> {
  // Read up front: the last report can finish after this widget is gone.
  late final SessionCubit _session;
  late final StreakCubit _streak;
  late final AppLifecycleListener _lifecycle;
  ReadingTracker? _tracker;
  NavigatorState? _rootNavigator;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _session = context.read<SessionCubit>();
    _streak = context.read<StreakCubit>();
    _lifecycle = AppLifecycleListener(onStateChange: (s) => _tracker?.setAppResumed(s == AppLifecycleState.resumed));
    _follow(context.read<ArticleCubit>().state);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ticking stops when an opaque screen covers the reader; sheets and dialogs keep it visible.
    _visible = TickerMode.valuesOf(context).enabled;
    _tracker?.setVisible(_visible);
    _rootNavigator = Navigator.maybeOf(context, rootNavigator: true);
  }

  void _follow(ArticleState state) {
    final article = state.article;
    if (state.status != ArticleStatus.ready || article == null) return;
    final current = _tracker;
    if (current != null && current.articleId == article.card.id) {
      current.language = article.card.language;
      return;
    }
    current?.dispose();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _tracker = ReadingTracker(
      articleId: article.card.id,
      language: article.card.language,
      report: getIt<ReportReadingProgress>(),
      isSignedIn: () => _session.state.isAuthenticated,
      onResult: _onResult,
      appResumed: lifecycle == null || lifecycle == AppLifecycleState.resumed,
      visible: _visible,
    )..start();
  }

  void _onResult(ReadingProgressResult result) {
    if (result.completedNow && result.streak != null) _streak.apply(result.streak!);
    final milestone = result.milestone;
    if (milestone == null) return;
    // The final report is sent after the reader closed: celebrate over whatever screen is showing then.
    final target = mounted ? context : _rootNavigator?.context;
    if (target != null && target.mounted) unawaited(showMilestoneSheet(target, milestone));
  }

  bool _onNotification(Notification notification) {
    final metrics = switch (notification) {
      ScrollNotification(depth: 0, :final metrics) => metrics,
      ScrollMetricsNotification(depth: 0, :final metrics) => metrics,
      _ => null,
    };
    if (metrics != null && metrics.axis == Axis.vertical) {
      final max = metrics.maxScrollExtent;
      _tracker?.updateScroll(max <= 0 ? 1 : metrics.pixels / max);
    }
    return false;
  }

  void _onPointer(PointerEvent _) => _tracker?.interact();

  @override
  void dispose() {
    _lifecycle.dispose();
    _tracker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<ArticleCubit, ArticleState>(
        listener: (_, state) => _follow(state),
        child: Listener(
          onPointerDown: _onPointer,
          onPointerMove: _onPointer,
          onPointerSignal: _onPointer,
          child: NotificationListener<Notification>(onNotification: _onNotification, child: widget.child),
        ),
      );
}
