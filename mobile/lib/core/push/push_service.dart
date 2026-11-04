import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'devices_api.dart';
import 'push_links.dart';
import 'push_platform.dart';
import 'push_read_receipts.dart';

/// Push notifications through Firebase Cloud Messaging (SPEC §21.1).
///
/// - Permission is asked only in context ([enable]), never on first launch.
/// - Once granted, this device's token is registered with `POST /me/devices` on
///   every sign-in and app start, and again when FCM rotates it. On sign-out it is removed from the API
///   ([unregister], `DELETE /me/devices/{token}`) and deleted on the device.
/// - Foreground pushes become a local notification on Android (iOS shows them itself).
/// - Taps, including the one that launched the app, come out of [openPaths] as app routes, and mark their
///   notification read (F17) once the session is known: right away when signed in, never when signed out.
@lazySingleton
class PushService {
  PushService(this._platform, this._devices, this._receipts);

  final PushPlatform _platform;
  final DevicesApi _devices;
  final PushReadReceipts _receipts;

  final ValueNotifier<PushPermission> permission = ValueNotifier(PushPermission.unsupported);

  /// Single-subscription, so a tap that arrives before the router listens is kept.
  final _opens = StreamController<String>();
  Stream<String> get openPaths => _opens.stream;

  String? _userId;
  ({String userId, String token})? _registered;
  bool _started = false;

  /// [followUser] was called: the session is restored, so taps can be marked read (or dropped when signed out).
  bool _sessionKnown = false;

  /// Notifications whose push was tapped, waiting for the session.
  final _pendingReads = <String>{};

  Future<void> start() async {
    if (_started || !_platform.isSupported) return;
    _started = true;
    try {
      await _platform.initialize();
      permission.value = await _platform.permission();
      _platform.onForegroundMessage.listen(_platform.show);
      _platform.onOpened.listen(_open);
      _platform.onTokenRefresh.listen((_) => _register());
      _open(await _platform.launchPayload());
      await _register(); // the session may have been restored before start() finished
    } catch (error) {
      debugPrint('Push notifications unavailable: $error');
    }
  }

  /// Asks for permission in context (onboarding reminder step, the notifications switch).
  Future<PushPermission> enable() async {
    if (permission.value == PushPermission.unsupported) return PushPermission.unsupported;
    try {
      permission.value = await _platform.requestPermission();
    } catch (error) {
      debugPrint('Could not ask for notification permission: $error');
    }
    await _register();
    return permission.value;
  }

  /// `DELETE /me/devices/{token}` for the token registered by this device. Called before signing out, while the
  /// access token still works; failures are ignored (the API also drops tokens FCM reports as invalid).
  Future<void> unregister() async {
    final registered = _registered;
    if (registered == null) return;
    try {
      await _devices.unregister(Uri.encodeComponent(registered.token));
    } catch (error) {
      debugPrint('Device unregistration failed: $error');
    }
  }

  /// The account was deleted (the API already dropped its device tokens): this device stops registering for it and its
  /// FCM token is deleted, whether or not it was registered, so nothing sent to the old token can arrive. Best effort.
  Future<void> forgetDevice() async {
    _userId = null;
    _registered = null;
    if (!_platform.isSupported) return;
    try {
      await _platform.deleteToken();
    } catch (error) {
      debugPrint('Could not delete the push token: $error');
    }
  }

  /// Registers this device for [userId] (null = signed out, which deletes the token).
  Future<void> followUser(String? userId) async {
    _sessionKnown = true;
    if (userId == _userId) {
      unawaited(_sendReads());
      return;
    }
    final previous = _userId;
    _userId = userId;
    unawaited(_sendReads());
    if (userId == null) {
      if (previous != null && _registered != null) {
        _registered = null;
        try {
          await _platform.deleteToken(); // the next account on this device gets no pushes for this one
        } catch (_) {
          /* the API drops the token when FCM reports it invalid */
        }
      }
      return;
    }
    await _register();
  }

  Future<void> _register() async {
    final userId = _userId;
    if (userId == null || permission.value != PushPermission.granted) return;
    try {
      final token = await _platform.getToken();
      if (token == null || userId != _userId) return;
      if (_registered == (userId: userId, token: token)) return;
      await _devices.register(RegisterDeviceRequest(token: token, platform: _platform.platformName));
      _registered = (userId: userId, token: token);
    } catch (error) {
      debugPrint('Device registration failed, retried on the next start: $error');
    }
  }

  void _open(PushPayload? tap) {
    if (tap == null) return;
    if (tap.notificationId case final id?) {
      _pendingReads.add(id);
      unawaited(_sendReads());
    }
    final link = tap.link;
    if (link == null) return; // no link: the tap just opens the app
    // A link the app doesn't know (or an unsafe one) still leads somewhere useful.
    _opens.add(pushLinkToPath(link) ?? '/notifications');
  }

  /// `POST /me/notifications/{id}/read` for the tapped pushes, once someone is signed in. Signed out, they are
  /// dropped: they belonged to an account that isn't on this device anymore.
  Future<void> _sendReads() async {
    if (!_sessionKnown || _pendingReads.isEmpty) return;
    final ids = _pendingReads.toList();
    _pendingReads.clear();
    if (_userId == null) return;
    for (final id in ids) {
      try {
        await _receipts.markRead(id);
      } catch (error) {
        debugPrint('Could not mark the notification read: $error');
      }
    }
  }
}
