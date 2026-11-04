import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import '../config/app_config.dart';
import '../firebase/firebase_bootstrap.dart';
import 'push_links.dart';

enum PushPermission { unsupported, notDetermined, granted, denied }

/// A push as the app shows it, and what its tap carries.
class PushPayload {
  const PushPayload({this.title, this.body, this.link, this.notificationId});

  final String? title;
  final String? body;

  /// `readin://a/{slug}#comment-{id}` or an App Link (SPEC §21.1); null when the push has none.
  final String? link;

  /// `data.notificationId` (F17): opening the push marks this notification read.
  final String? notificationId;

  /// The payload of the local notification a foreground push becomes: its link and notification id.
  String toLocalPayload() => jsonEncode({'link': ?link, 'notificationId': ?notificationId});

  /// Reads [toLocalPayload], and the bare link earlier versions stored.
  static PushPayload fromLocalPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return const PushPayload();
    if (payload.startsWith('{')) {
      try {
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic>) {
          final link = data['link'];
          return PushPayload(link: link is String ? link : null, notificationId: pushNotificationId(data));
        }
      } on FormatException {
        // not ours: read as a link below
      }
    }
    return PushPayload(link: payload);
  }
}

/// Firebase Cloud Messaging + local notifications; tests use a fake.
abstract interface class PushPlatform {
  /// False without Firebase and with the emulator (it has no Cloud Messaging).
  bool get isSupported;

  /// `android` or `ios` (`RegisterDeviceRequest.platform`).
  String get platformName;

  /// Sets up channels and listeners. Never asks for permission.
  Future<void> initialize();

  Future<PushPermission> permission();

  Future<PushPermission> requestPermission();

  /// This device's FCM token, or null when it cannot be created yet.
  Future<String?> getToken();

  Future<void> deleteToken();

  Stream<String> get onTokenRefresh;

  /// Pushes received while the app is in the foreground.
  Stream<PushPayload> get onForegroundMessage;

  /// Notifications the user tapped while the app was running (background, or shown in the foreground).
  Stream<PushPayload> get onOpened;

  /// The notification that launched the app, if any (read once).
  Future<PushPayload?> launchPayload();

  /// Shows [payload] as a system notification (Android foreground; iOS shows it itself).
  Future<void> show(PushPayload payload);
}

@LazySingleton(as: PushPlatform)
class FirebasePushPlatform implements PushPlatform {
  FirebasePushPlatform(this._config, this._firebase);

  final AppConfig _config;
  final FirebaseStatus _firebase;
  final _local = FlutterLocalNotificationsPlugin();
  final _localTaps = StreamController<PushPayload>.broadcast();
  int _nextId = 0;

  /// Also the default channel for background FCM notifications (AndroidManifest.xml).
  static const channel = AndroidNotificationChannel(
    'readin_default',
    'ReadIn',
    description: 'Replies, mentions, followers and today\'s article',
    importance: Importance.high,
  );

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  bool get isSupported => _firebase.available && !_config.useFirebaseEmulator;

  @override
  String get platformName => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  @override
  Future<void> initialize() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _localTaps.add(PushPayload.fromLocalPayload(response.payload)),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    // iOS shows foreground pushes itself; Android needs a local notification (see [show]).
    await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
  }

  @override
  Future<PushPermission> permission() async => _map((await _messaging.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushPermission> requestPermission() async => _map((await _messaging.requestPermission()).authorizationStatus);

  @override
  Future<String?> getToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // The FCM token needs the APNs token, which arrives shortly after permission is granted.
      for (var attempt = 0; attempt < 10 && await _messaging.getAPNSToken() == null; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    // ignore: deprecated_member_use
    return _messaging.getToken();
  }

  // FCM registration tokens, not the newer installation IDs (register / onRegistered): the API and the
  // web app send to tokens (`RegisterDeviceRequest.token`, FCM HTTP v1). Moving to installation IDs is
  // a backend change for both clients.
  @override
  // ignore: deprecated_member_use
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushPayload> get onForegroundMessage => FirebaseMessaging.onMessage.map(payloadOf);

  @override
  Stream<PushPayload> get onOpened => StreamGroupLite.merge([
        FirebaseMessaging.onMessageOpenedApp.map(payloadOf),
        _localTaps.stream,
      ]);

  @override
  Future<PushPayload?> launchPayload() async {
    final initial = await _messaging.getInitialMessage();
    if (initial != null) return payloadOf(initial);
    final details = await _local.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true
        ? PushPayload.fromLocalPayload(details!.notificationResponse?.payload)
        : null;
  }

  @override
  Future<void> show(PushPayload payload) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) return;
    await _local.show(
      id: _nextId++,
      title: payload.title,
      body: payload.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload.toLocalPayload(),
    );
  }

  static PushPermission _map(AuthorizationStatus status) => switch (status) {
        AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  /// One mapping for every app state: foreground messages, background taps and the tap that launched the app.
  @visibleForTesting
  static PushPayload payloadOf(RemoteMessage message) => PushPayload(
        title: message.notification?.title ?? message.data['title'] as String?,
        body: message.notification?.body ?? message.data['body'] as String?,
        link: pushDataLink(message.data),
        notificationId: pushNotificationId(message.data),
      );
}

/// Merges broadcast streams without pulling in a stream library.
abstract final class StreamGroupLite {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    final subscriptions = <StreamSubscription<T>>[];
    late final StreamController<T> controller;
    controller = StreamController<T>.broadcast(
      onListen: () => subscriptions.addAll(streams.map((s) => s.listen(controller.add, onError: controller.addError))),
      onCancel: () => Future.wait(subscriptions.map((s) => s.cancel())).then((_) => subscriptions.clear()),
    );
    return controller.stream;
  }
}
