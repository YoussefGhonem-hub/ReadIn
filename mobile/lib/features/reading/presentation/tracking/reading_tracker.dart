import 'dart:async';
import 'dart:math' as math;

import '../../../../core/errors/failure.dart';
import '../../domain/entities/reading.dart';
import '../../domain/usecases/reading_usecases.dart';

/// Reports reading progress for one article (SPEC F04, ADR 0013) with `PUT /articles/{id}/progress`.
///
/// - [start] sends a report at once with no seconds: the server credits none on the first report, so the next ones
///   are measured from it.
/// - Active time counts only while the app is resumed, the reader is visible and the user interacted (scroll or
///   pointer) in the last [idleTimeout]; opening the article, coming back to the app and coming back to the reader
///   count as interactions.
/// - Every [reportInterval] it sends the highest percent reached, the current position and the unsent seconds, and
///   skips the report when none of them changed. Pausing the app and [dispose] send one at once.
/// - One request is in flight at a time. A failure that may pass (offline, 5xx, `409 reading.conflict`, 429) keeps
///   its seconds for the next report; any other (401, 404, …) stops the tracker.
/// - Guests send nothing; their time is dropped.
///
/// Plain Dart with an injectable clock, so it is tested with `fake_async`.
class ReadingTracker {
  ReadingTracker({
    required this.articleId,
    required this._language,
    required this._report,
    required this._isSignedIn,
    this.onResult,
    DateTime Function()? now,
    bool appResumed = true,
    this._visible = true,
  })  : _now = now ?? DateTime.now,
        _resumed = appResumed {
    _lastInteraction = _accountedUntil = _now();
  }

  static const reportInterval = Duration(seconds: 15);
  static const idleTimeout = Duration(seconds: 60);

  /// The API accepts at most this many seconds per report; the rest waits for the next one.
  static const maxSecondsPerReport = 3600;

  final String articleId;

  /// Called for every report the server accepted (also after [dispose], for the final one).
  final void Function(ReadingProgressResult result)? onResult;

  final ReportReadingProgress _report;
  final bool Function() _isSignedIn;
  final DateTime Function() _now;

  String _language;
  bool _resumed;
  bool _visible;
  bool _started = false;
  bool _disposed = false;
  bool _stopped = false;
  Timer? _timer;

  late DateTime _lastInteraction;
  late DateTime _accountedUntil;
  Duration _unsent = Duration.zero;
  double _highest = 0;
  double _position = 0;

  // What the server last accepted; null until the first report went through.
  int? _sentPercent;
  String? _sentPosition;

  bool _sending = false;
  bool _sendAgain = false;

  /// True once a 401/404-like failure ended reporting for this article.
  bool get isStopped => _stopped;

  bool get _counting => _started && !_disposed && !_stopped && _resumed && _visible;

  /// The article language being read (`ar-EG` / `en`); the next report uses it.
  set language(String value) => _language = value;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _lastInteraction = _accountedUntil = _now();
    _timer = Timer.periodic(reportInterval, (_) => unawaited(_send()));
    unawaited(_send());
  }

  /// [fraction] is the current scroll position, 0–1 (1 when the article fits the screen).
  void updateScroll(double fraction) {
    final value = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);
    _position = value;
    _highest = math.max(_highest, value);
  }

  /// A scroll, tap or other pointer activity on the reader.
  void interact() {
    _accrue();
    _lastInteraction = _now();
  }

  /// The app moved to or from the foreground. Leaving it sends a report at once.
  void setAppResumed(bool resumed) => _setActive(resumed: resumed);

  /// The reader became visible or another screen covered it.
  void setVisible(bool visible) => _setActive(visible: visible);

  /// Sends a report now (skipped when nothing changed).
  Future<void> flush() => _send();

  /// Stops counting and sends the last report.
  void dispose() {
    if (_disposed) return;
    _accrue();
    _disposed = true;
    _timer?.cancel();
    if (_started) unawaited(_send());
  }

  void _setActive({bool? resumed, bool? visible}) {
    final wasCounting = _counting;
    _accrue();
    final leftApp = resumed == false && _resumed;
    _resumed = resumed ?? _resumed;
    _visible = visible ?? _visible;
    if (!wasCounting && _counting) _lastInteraction = _now();
    if (leftApp && _started && !_disposed) unawaited(_send());
  }

  /// Moves the active seconds since the last call into [_unsent].
  void _accrue() {
    final now = _now();
    if (_counting) {
      final activeUntil = _lastInteraction.add(idleTimeout);
      final end = now.isBefore(activeUntil) ? now : activeUntil;
      if (end.isAfter(_accountedUntil)) _unsent += end.difference(_accountedUntil);
    }
    _accountedUntil = now;
  }

  /// Runs reports one at a time; a request made while one is in flight is sent after it.
  Future<void> _send() async {
    _sendAgain = true;
    if (_sending) return;
    _sending = true;
    try {
      while (_sendAgain && !_stopped) {
        _sendAgain = false;
        await _sendOnce();
      }
    } finally {
      _sending = false;
    }
  }

  Future<void> _sendOnce() async {
    _accrue();
    if (!_isSignedIn()) {
      _unsent = Duration.zero;
      _sentPercent = null;
      _sentPosition = null;
      return;
    }

    final seconds = math.min(_unsent.inSeconds, maxSecondsPerReport);
    final percent = (_highest * 100).round();
    final position = _position.toStringAsFixed(4);
    if (seconds == 0 && percent == _sentPercent && position == _sentPosition) return;

    _unsent -= Duration(seconds: seconds);
    final result = await _report(
      articleId,
      ReadingProgressReport(language: _language, percent: percent, lastPosition: position, activeSecondsDelta: seconds),
    );
    result.fold(
      (failure) {
        if (_mayPass(failure)) {
          _unsent += Duration(seconds: seconds);
        } else {
          _stopped = true;
          _timer?.cancel();
        }
      },
      (value) {
        _sentPercent = percent;
        _sentPosition = position;
        onResult?.call(value);
      },
    );
  }

  static bool _mayPass(Failure failure) {
    final status = failure.statusCode;
    return status == null || status >= 500 || status == 409 || status == 429 || failure.code == FailureCodes.readingConflict;
  }
}
