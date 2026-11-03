/// Upload/download progress: bytes transferred so far and the total, or
/// `total <= 0` when the size is not known yet.
typedef TransferProgress = void Function(int sent, int total);

/// Cancels a running upload/download. Lives in `core/` so domain code can
/// cancel transfers without depending on Dio's `CancelToken`; the data layer
/// bridges the two (see `MediaRepositoryImpl`).
class TransferToken {
  final _listeners = <void Function()>[];
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  /// Runs [listener] once when the token is cancelled (immediately if it already is).
  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}
