import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/session/session_cubit.dart';
import '../../domain/entities/reading.dart';
import '../../domain/usecases/reading_usecases.dart';
import '../cubit/streak_cubit.dart';
import 'reading_tracker.dart';
import 'reading_tracking.dart';

/// Counts an article shown whole in its post card (F34) like one read in the reader (F04: 70% seen and 30 seconds):
/// wrap the expanded text of a complete preview. The reader's own [ReadingTracker] sends `PUT /articles/{id}/progress`;
/// "seen" is how far down the text the list's viewport has reached, active time counts while the text is on screen,
/// the list isn't covered and the viewer scrolls or touches it. A cut-off article never counts from the card. Guests
/// send nothing; the last report goes when the card collapses or leaves the list.
class PostCardReading extends StatefulWidget {
  const PostCardReading({super.key, required this.articleId, required this.language, required this.child});

  final String articleId;

  /// The version shown (`ar-EG` / `en`).
  final String language;
  final Widget child;

  @override
  State<PostCardReading> createState() => _PostCardReadingState();
}

class _PostCardReadingState extends State<PostCardReading> {
  ReadingTracker? _tracker;
  AppLifecycleListener? _lifecycle;
  StreakCubit? _streak;
  NavigatorState? _rootNavigator;
  ScrollableState? _scrollable;
  ScrollPosition? _position;
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit?>();
    if (session == null || !session.state.isAuthenticated || !getIt.isRegistered<ReportReadingProgress>()) return;
    _streak = context.read<StreakCubit?>();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _tracker = ReadingTracker(
      articleId: widget.articleId,
      language: widget.language,
      report: getIt<ReportReadingProgress>(),
      isSignedIn: () => session.state.isAuthenticated,
      onResult: _onResult,
      appResumed: lifecycle == null || lifecycle == AppLifecycleState.resumed,
      // Until the first layout says where the text is.
      visible: false,
    )..start();
    _lifecycle = AppLifecycleListener(onStateChange: (s) => _tracker?.setAppResumed(s == AppLifecycleState.resumed));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ticking stops while another screen covers the list; sheets and dialogs keep it on.
    _covered = !TickerMode.valuesOf(context).enabled;
    _rootNavigator = Navigator.maybeOf(context, rootNavigator: true);
    _scrollable = Scrollable.maybeOf(context);
    final position = _scrollable?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_onScroll);
      _position = position?..addListener(_onScroll);
    }
  }

  void _onResult(ReadingProgressResult result) =>
      celebrateReading(result, streak: _streak, target: () => mounted ? context : _rootNavigator?.context);

  void _onScroll() {
    _tracker?.interact();
    _measure();
  }

  void _onPointer(PointerEvent _) => _tracker?.interact();

  /// How much of the text the viewport has reached, and whether any of it is on screen.
  void _measure() {
    final tracker = _tracker;
    if (tracker == null || !mounted) return;
    final box = context.findRenderObject();
    final viewport = _scrollable?.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached || viewport is! RenderBox || !viewport.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final height = box.size.height;
    final viewTop = viewport.localToGlobal(Offset.zero).dy;
    final viewBottom = viewTop + viewport.size.height;
    tracker
      ..updateScroll(height <= 0 ? 1 : (viewBottom - top) / height)
      ..setVisible(!_covered && top < viewBottom && top + height > viewTop);
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _lifecycle?.dispose();
    _tracker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Layout may have moved the text (images, the card above): measure once it is laid out.
    if (_tracker != null) WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    return Listener(
      onPointerDown: _onPointer,
      onPointerMove: _onPointer,
      onPointerSignal: _onPointer,
      child: widget.child,
    );
  }
}
